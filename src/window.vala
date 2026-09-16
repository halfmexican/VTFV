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

    public Window (Adw.Application application) {
        Object (application: application);
    }

    construct {
        var open_action = new GLib.SimpleAction ("open-vtf", null);
        open_action.activate.connect (() => {
            open_vtf.begin ();
        });
        add_action (open_action);
    }

    private async void open_vtf () {
        var dialog = new Gtk.FileDialog ();
        dialog.title = _("Open VTF file");

        var filter = new Gtk.FileFilter ();
        filter.name = _("VTF files");
        filter.add_pattern ("*.vtf");
        filter.add_pattern ("*.VTF");

        dialog.default_filter = filter;

        try {
            var file = yield dialog.open (this, null);
            if (file != null) {
                load_vtf_file (file);
            }
        } catch (GLib.Error e) {
            if (!(e is Gtk.DialogError.DISMISSED)) {
                warning ("Could not open VTF file: %s", e.message);
            }
        }
    }

    private void load_vtf_file (GLib.File file) {
        var texture = new Vtf.Texture ();

        var path = file.get_path ();
        if (path == null) {
            warning ("Cannot load non-local file directly with VTFLib.");
            return;
        }

        if (!texture.load (path)) {
            warning ("Failed to load VTF.");
            return;
        }

        var gdk_texture = texture.to_gdk_texture ();

        if (gdk_texture != null) {
            vtf_picture.paintable = gdk_texture;
            content_stack.visible_child_name = "image";
        }

        // sidebar metadata
        row_filename.subtitle = file.get_basename ();
        row_width.subtitle = texture.width.to_string ();
        row_height.subtitle = texture.height.to_string ();
        row_format.subtitle = texture.get_format ().to_string ();

        split_view.show_sidebar = true;
        title = file.get_basename ();
    }
}
