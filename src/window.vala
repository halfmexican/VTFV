/* window.vala
 *
 * Copyright 2026 José Hunter
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[GtkTemplate (ui = "/io/github/halfmexican/VTFV/gtk/window.ui")]
public class Vtfv.Window : Adw.ApplicationWindow {

    [GtkChild] private unowned Adw.OverlaySplitView split_view;
    [GtkChild] private unowned Gtk.Stack content_stack;
    [GtkChild] private unowned NearestPicture vtf_picture;
    [GtkChild] private unowned Adw.ActionRow row_filename;
    [GtkChild] private unowned Adw.ActionRow row_width;
    [GtkChild] private unowned Adw.ActionRow row_height;
    [GtkChild] private unowned Adw.ActionRow row_format;

    private Gtk.FileFilter supported_files_filter;

    private string? current_vtf_path = null;
    private bool is_temp_file = false;

    // Zoom state
    private Gdk.Texture? original_texture = null;
    private uint base_width = 0;
    private uint base_height = 0;
    private double zoom_level = 1.0;
    private double zoom_at_gesture_start = 1.0;

    public Window (Adw.Application application) {
        Object (application: application);
    }

    construct {
        var open_action = new GLib.SimpleAction ("open-file", null);
        open_action.activate.connect (() => { open_file.begin (); });
        add_action (open_action);

        var save_action = new GLib.SimpleAction ("save-file", null);
        save_action.activate.connect (() => { save_file.begin (); });
        add_action (save_action);

        supported_files_filter = new Gtk.FileFilter ();
        supported_files_filter.name = _("VTF and PNG files");
        supported_files_filter.add_pattern ("*.vtf");
        supported_files_filter.add_pattern ("*.VTF");
        supported_files_filter.add_pattern ("*.png");
        supported_files_filter.add_pattern ("*.PNG");

        setup_zoom_controllers ();
    }

    ~Window () {
        cleanup ();
    }

    private void cleanup () {
        if (is_temp_file && current_vtf_path != null) {
            GLib.FileUtils.unlink (current_vtf_path);
        }
        current_vtf_path = null;
        is_temp_file = false;
    }

    private void setup_zoom_controllers () {
        // TODO: Ctrl + Scroll
        var scroll_ctrl = new Gtk.EventControllerScroll (Gtk.EventControllerScrollFlags.VERTICAL);
        scroll_ctrl.scroll.connect ((dx, dy) => {
            var state = scroll_ctrl.get_current_event_state ();
            if (Gdk.ModifierType.CONTROL_MASK in state) {
                apply_zoom (zoom_level * GLib.Math.pow (1.1, -dy));
                return true;
            }
            return false;
        });
        vtf_picture.add_controller (scroll_ctrl);

        // Touchpad pinch
        var pinch = new Gtk.GestureZoom ();
        pinch.begin.connect (() => {
            zoom_at_gesture_start = zoom_level;
        });
        pinch.scale_changed.connect ((scale) => {
            apply_zoom (zoom_at_gesture_start * scale);
        });
        vtf_picture.add_controller (pinch);

        // Double-click: toggle fit / 100%
        var click = new Gtk.GestureClick ();
        click.button = 1;
        click.pressed.connect ((n_press, x, y) => {
            if (n_press == 2) {
                apply_zoom (1.0);
                click.set_state (Gtk.EventSequenceState.CLAIMED);
            }
        });
        vtf_picture.add_controller (click);
    }

    private void apply_zoom (double new_zoom) {
        if (original_texture == null) return;

        if (new_zoom < 0.1) new_zoom = 0.1;
        if (new_zoom > 8.0) new_zoom = 8.0;
        zoom_level = new_zoom;

        if (zoom_level <= 1.0) {
            vtf_picture.texture = original_texture;
            vtf_picture.width_request = -1;
            vtf_picture.height_request = -1;
        } else {
            int target_w = (int) (base_width * zoom_level);
            int target_h = (int) (base_height * zoom_level);

            vtf_picture.texture = original_texture;
            vtf_picture.width_request = target_w;
            vtf_picture.height_request = target_h;
        }
    }

    private async void open_file () {
        var file_dialog = new Gtk.FileDialog () {
            title = _("Open Image"),
            default_filter = supported_files_filter
        };

        try {
            GLib.File file = yield file_dialog.open (this, null);
            if (file != null) {
                process_file (file);
            }
        } catch (GLib.Error e) {
            if (!(e is Gtk.DialogError.DISMISSED)) {
                warning ("Could not open file: %s", e.message);
            }
        }
    }

    private async void save_file () {
        if (current_vtf_path == null) {
            return;
        }

        var save_filter = new Gtk.FileFilter ();
        save_filter.name = _("VTF files");
        save_filter.add_pattern ("*.vtf");
        save_filter.add_pattern ("*.VTF");

        var file_dialog = new Gtk.FileDialog () {
            title = _("Save VTF As"),
            default_filter = save_filter
        };

        string initial_name = title ?? "texture.vtf";
        initial_name = initial_name.replace (" (Converted)", "");
        if (!initial_name.down ().has_suffix (".vtf")) {
            initial_name += ".vtf";
        }
        file_dialog.initial_name = initial_name;

        try {
            GLib.File dest_file = yield file_dialog.save (this, null);
            if (dest_file != null) {
                var source_file = GLib.File.new_for_path (current_vtf_path);
                try {
                    source_file.copy (dest_file, GLib.FileCopyFlags.OVERWRITE, null);
                    message ("VTF saved to %s", dest_file.get_path () ?? "unknown");
                } catch (GLib.Error e) {
                    warning ("failed to save file: %s", e.message);
                }
            }
        } catch (GLib.Error e) {
            if (!(e is Gtk.DialogError.DISMISSED)) {
                warning ("could not save: %s", e.message);
            }
        }
    }

    private void process_file (GLib.File file) {
        string basename = file.get_basename ().down ();
        if (basename.has_suffix (".png")) {
            convert_png_to_vtf.begin (file);
        } else {
            load_vtf_file (file);
        }
    }

    private void load_vtf_file (GLib.File file) {
        cleanup ();

        var texture = new Vtf.Texture ();

        string? path = file.get_path ();
        if (path == null) {
            warning ("failed to load path");
            return;
        }

        if (!texture.load (path)) {
            warning ("failed to load VTF: %s", Vtf.get_last_error ());
            return;
        }

        current_vtf_path = path;
        is_temp_file = false;

        update_ui_with_texture (texture, get_file_name (file));
    }

    private async void convert_png_to_vtf (GLib.File file) {
        cleanup ();

        GLib.FileInputStream? stream = null;
        try {
            stream = yield file.read_async (GLib.Priority.DEFAULT, null);
            var pixbuf = new Gdk.Pixbuf.from_stream (stream, null);

            if (!pixbuf.has_alpha) {
                pixbuf = pixbuf.add_alpha (false, 0, 0, 0);
            }

            uint width = (uint) pixbuf.width;
            uint height = (uint) pixbuf.height;

            if (!is_power_of_two (width) || !is_power_of_two (height)) {
                uint new_w = next_power_of_two (width);
                uint new_h = next_power_of_two (height);
                message ("resizing image from %ux%u to %ux%u", width, height, new_w, new_h);

                pixbuf = pixbuf.scale_simple ((int) new_w, (int) new_h, Gdk.InterpType.BILINEAR);

                width = new_w;
                height = new_h;
            }

            int rowstride = pixbuf.rowstride;
            unowned uint8[] src_pixels = pixbuf.get_pixels ();
            unowned uint8* src_ptr = (uint8*) src_pixels;

            uint handle;
            Vtf.create_image (out handle);
            Vtf.bind_image (handle);

            if (!Vtf.image_create (width, height, 1, 1, 1, Vtf.ImageFormat.RGBA8888, false, false, false)) {
                warning ("failed to create image: %s", Vtf.get_last_error ());
                Vtf.delete_image (handle);
                return;
            }

            unowned uint8* dest_ptr = Vtf.get_data (0, 0, 0, 0);
            if (dest_ptr == null) {
                warning ("failed to allocate image data buffer.");
                Vtf.delete_image (handle);
                return;
            }

            for (uint y = 0; y < height; y++) {
                int src_offset = (int) y * rowstride;
                int dest_offset = (int) y * (int) width * 4;

                GLib.Memory.copy (
                    (void*) (dest_ptr + dest_offset),
                    (void*) (src_ptr + src_offset),
                    width * 4
                );
            }

            string temp_path;
            int fd = GLib.FileUtils.open_tmp ("vtfv-convert-XXXXXX.vtf", out temp_path);
            if (fd == -1) {
                throw new GLib.FileError.FAILED ("failed to create temp file");
            }
            GLib.FileUtils.close (fd);

            Vtf.save (temp_path);

            var vtf_texture = new Vtf.Texture ();
            if (vtf_texture.load (temp_path)) {
                current_vtf_path = temp_path;
                is_temp_file = true;
                update_ui_with_texture (vtf_texture, get_file_name (file) + " (Converted)");
            } else {
                GLib.FileUtils.unlink (temp_path);
            }

            Vtf.delete_image (handle);

        } catch (GLib.Error e) {
            warning ("Conversion failed: %s", e.message);
        } finally {
                if (stream != null) {
                    try {
                        stream.close ();
                    } catch (GLib.Error e) {
                        warning (e.message);
                    }
                }
            }
        }

    private bool is_power_of_two (uint v) {
        return v > 0 && (v & (v - 1)) == 0;
    }

    private uint next_power_of_two (uint v) {
        v--;
        v |= v >> 1;
        v |= v >> 2;
        v |= v >> 4;
        v |= v >> 8;
        v |= v >> 16;
        v++;
        return v;
    }

    private void update_ui_with_texture (Vtf.Texture texture, string display_name) {
        var gdk_texture = texture.to_gdk_texture ();
        if (gdk_texture != null) {
            original_texture = gdk_texture;
            base_width = texture.width;
            base_height = texture.height;
            zoom_level = 1.0;

            vtf_picture.texture = gdk_texture;
            vtf_picture.width_request = -1;
            vtf_picture.height_request = -1;
            content_stack.visible_child_name = "image";

            row_filename.subtitle = display_name;
            row_width.subtitle = texture.width.to_string ();
            row_height.subtitle = texture.height.to_string ();

            row_format.subtitle = texture.get_format ().to_string ().replace ("IMAGE_FORMAT_", "");

            split_view.show_sidebar = true;
            title = display_name;
        }
    }

    private static string get_file_name (GLib.File file) {
        try {
            var info = file.query_info ("standard::name", GLib.FileQueryInfoFlags.NONE, null);
            return info.get_name ();
        } catch (GLib.Error e) {
            warning (e.message);
            return file.get_basename () ?? "Unknown";
        }
    }
}

