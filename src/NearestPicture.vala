
public class Vtfv.NearestPicture : Gtk.Widget {
    private Gdk.Texture? _texture = null;

    public Gdk.Texture? texture {
        get { return _texture; }
        set {
            _texture = value;
            queue_draw ();
        }
    }

    construct {
        set_layout_manager (new Gtk.BinLayout ());
        set_hexpand (false);
        set_vexpand (false);
    }

    protected override void snapshot (Gtk.Snapshot snapshot) {
        if (_texture == null) return;

        int tex_w = _texture.get_width ();
        int tex_h = _texture.get_height ();
        int widget_w = get_width ();
        int widget_h = get_height ();

        if (tex_w == 0 || tex_h == 0 || widget_w == 0 || widget_h == 0) return;

        // Calculate aspect ratios
        double tex_aspect = (double) tex_w / tex_h;
        double widget_aspect = (double) widget_w / widget_h;

        int draw_w, draw_h;

        // Mimic Gtk.ContentFit.CONTAIN
        if (tex_aspect > widget_aspect) {
            draw_w = widget_w;
            draw_h = (int) (widget_w / tex_aspect);
        } else {
            draw_h = widget_h;
            draw_w = (int) (widget_h * tex_aspect);
        }

        // Center it
        int offset_x = (widget_w - draw_w) / 2;
        int offset_y = (widget_h - draw_h) / 2;

        var rect = Graphene.Rect ();
        rect.init (offset_x, offset_y, draw_w, draw_h);

        snapshot.append_scaled_texture (
            _texture,
            Gsk.ScalingFilter.NEAREST,
            rect
        );
    }
}

