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
    [GtkChild] private unowned Gtk.Picture vtf_picture;
    [GtkChild] private unowned Adw.ActionRow row_filename;
    [GtkChild] private unowned Adw.ActionRow row_width;
    [GtkChild] private unowned Adw.ActionRow row_height;
    [GtkChild] private unowned Adw.ActionRow row_format;

    private Gtk.FileFilter supported_files_filter;

    public Window (Adw.Application application) {
        Object (application: application);
    }

    construct {
        var open_action = new GLib.SimpleAction ("open-file", null);
        open_action.activate.connect (() => { open_file.begin (); });
        add_action (open_action);

        supported_files_filter = new Gtk.FileFilter ();
        supported_files_filter.name = _("VTF and PNG files");
        supported_files_filter.add_pattern ("*.vtf");
        supported_files_filter.add_pattern ("*.VTF");
        supported_files_filter.add_pattern ("*.png");
        supported_files_filter.add_pattern ("*.PNG");
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

    private void process_file (GLib.File file) {
        string basename = file.get_basename ().down ();
        if (basename.has_suffix (".png")) {
            convert_png_to_vtf.begin (file);
        } else {
            load_vtf_file (file);
        }
    }

    private void load_vtf_file (GLib.File file) {
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

        update_ui_with_texture (texture, get_file_name (file));
    }

    private async void convert_png_to_vtf (GLib.File file) {
        try {
            GLib.FileInputStream stream = file.read (null);
            var pixbuf = new Gdk.Pixbuf.from_stream (stream, null);

            if (!pixbuf.has_alpha) {
                pixbuf = pixbuf.add_alpha (false, 0, 0, 0);
            }

            uint width = (uint) pixbuf.width;
            uint height = (uint) pixbuf.height;
            int rowstride = pixbuf.rowstride;

            unowned uint8[] src_pixels = pixbuf.get_pixels ();
            unowned uint8* src_ptr = (uint8*) src_pixels;

            uint handle;
            Vtf.create_image (out handle);
            Vtf.bind_image (handle);

            Vtf.image_create (
                width, height, 1, 1, 1,
                Vtf.ImageFormat.RGBA8888,
                false, false, false
            );

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
                throw new GLib.FileError.FAILED ("Failed to create temp file");
            }
            GLib.FileUtils.close (fd);

            Vtf.save (temp_path);

            var vtf_texture = new Vtf.Texture ();
            if (vtf_texture.load (temp_path)) {
                update_ui_with_texture (vtf_texture, get_file_name (file) + " (Converted)");
            }

            GLib.FileUtils.unlink (temp_path);
            Vtf.delete_image (handle);

        } catch (GLib.Error e) {
            warning ("Conversion failed: %s", e.message);
        }
    }

    private void update_ui_with_texture (Vtf.Texture texture, string display_name) {
        var gdk_texture = texture.to_gdk_texture ();
        if (gdk_texture != null) {
            vtf_picture.paintable = gdk_texture;
            content_stack.visible_child_name = "image";

            row_filename.subtitle = display_name;
            row_width.subtitle = texture.width.to_string ();
            row_height.subtitle = texture.height.to_string ();
            row_format.subtitle = texture.get_format ().to_string ();

            split_view.show_sidebar = true;
            title = display_name;
        }
    }

    private static string get_file_name (GLib.File file) {
        try {
            var info = file.query_info ("standard::name", GLib.FileQueryInfoFlags.NONE, null);
            return info.get_name ();
        } catch (GLib.Error e) {
            warning ("Failed to get file name: %s", e.message);
            return file.get_basename () ?? "Unknown";
        }
    }
}
