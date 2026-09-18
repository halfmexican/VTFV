/* VTFTexture.vala
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

public class Vtf.Texture : GLib.Object {
    private uint id;

    public uint width { get; private set; }
    public uint height { get; private set; }

    private bool loaded = false;

    public Texture () {
        Vtf.create_image (out id);
    }

    ~Texture () {
        if (loaded) {
            Vtf.bind_image (0); // Unbind
        }
        Vtf.delete_image (id);
    }

    private void bind () {
        Vtf.bind_image (id);
    }

    public bool load (string path) {
        bind ();
        if (!Vtf.load (path, false)) {
            warning ("VTFLib error: %s", Vtf.get_last_error ());
            return false;
        }
        this.width = Vtf.get_width ();
        this.height = Vtf.get_height ();
        this.loaded = true;
        return true;
    }

    public Vtf.ImageFormat get_format () {
        bind ();
        return Vtf.get_format ();
    }

    public Gdk.Texture? to_gdk_texture () {
        if (!loaded) return null;
        bind ();

        uint8[] pixels = new uint8[width * height * 4];
        uint8* raw = Vtf.get_data (0, 0, 0, 0);
        if (raw == null) return null;

        if (!Vtf.convert_to_rgba8888 (raw, (uint8*) pixels, width, height, Vtf.get_format ())) {
            warning ("Failed to convert to RGBA8888: %s", Vtf.get_last_error ());
            return null;
        }

        var bytes = new GLib.Bytes (pixels);
        return new Gdk.MemoryTexture ((int) width, (int) height, Gdk.MemoryFormat.R8G8B8A8, bytes, (int) (width * 4));
    }
}
