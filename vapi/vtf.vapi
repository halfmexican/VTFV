[CCode (cheader_filename = "VTFLib.h,VTFWrapper.h")]
namespace Vtf {

    [CCode (cname = "VTFImageFormat", cprefix = "IMAGE_FORMAT_", has_type_id = false)]
    public enum ImageFormat {
        RGBA8888,
        ABGR8888,
        RGB888,
        BGR888,
        RGB565,
        I8,
        IA88,
        P8,
        A8,
        RGB888_BLUESCREEN,
        BGR888_BLUESCREEN,
        ARGB8888,
        BGRA8888,
        DXT1,
        DXT3,
        DXT5,
        BGRX8888,
        BGR565,
        BGRX5551,
        BGRA4444,
        DXT1_ONEBITALPHA,
        BGRA5551,
        UV88,
        UVWQ8888,
        RGBA16161616F,
        RGBA16161616,
        UVLX8888,
        R32F,
        RGB323232F,
        RGBA32323232F,
        NV_DST16,
        NV_DST24,
        NV_INTZ,
        NV_RAWZ,
        ATI_DST16,
        ATI_DST24,
        NV_NULL,
        ATI2N,
        ATI1N,
        COUNT,
        NONE = -1
    }

    [CCode (cname = "vlInitialize")]
    public static bool initialize();

    [CCode (cname = "vlShutdown")]
    public static void shutdown();

    [CCode (cname = "vlCreateImage")]
    public static bool create_image(out uint image);

    [CCode (cname = "vlBindImage")]
    public static bool bind_image(uint image);

    [CCode (cname = "vlDeleteImage")]
    public static void delete_image(uint image);

    [CCode (cname = "vlImageCreate")]
    public static bool image_create(
        uint width, uint height, uint frames, uint faces, uint slices,
        ImageFormat format,
        bool thumbnail, bool mipmaps, bool null_image_data
    );

    [CCode (cname = "vlImageLoad")]
    public static bool load(string filename, bool header_only);

    [CCode (cname = "vlImageSave")]
    public static bool save(string filename);

    [CCode (cname = "vlGetLastError")]
    public static unowned string get_last_error();
    
    [CCode (cname = "vlImageGetWidth")]
    public static uint get_width();

    [CCode (cname = "vlImageGetHeight")]
    public static uint get_height();

    [CCode (cname = "vlImageGetFormat")]
    public static ImageFormat get_format();
    
    [CCode (cname = "vlImageGetData")] 
    public static unowned uint8* get_data(uint frame, uint face, uint slice, uint mipmap_level);

    [CCode (cname = "vlImageConvertToRGBA8888")] 
    public static bool convert_to_rgba8888(uint8* source, uint8* dest, uint width, uint height, ImageFormat source_format);
}
