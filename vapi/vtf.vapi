[CCode (cheader_filename = "VTFLib.h,VTFWrapper.h")]
namespace Vtf {
    [CCode (cname = "vlUInt")] public struct UInt : uint {}
    [CCode (cname = "vlByte")] public struct Byte : uint8 {}
    [CCode (cname = "vlBool")] public struct Bool : uint {}

    [CCode (cname = "vlInitialize")] public Bool initialize();
    [CCode (cname = "vlShutdown")] public void shutdown();

    [CCode (cname = "vlCreateImage")] public Bool create_image(out UInt image);
    [CCode (cname = "vlBindImage")] public Bool bind_image(UInt image);
    [CCode (cname = "vlDeleteImage")] public void delete_image(UInt image);

    [CCode (cname = "vlImageLoad")] public Bool load(string filename, Bool header_only);
    [CCode (cname = "vlImageSave")] public Bool save(string filename);
    [CCode (cname = "vlGetLastError")] public unowned string get_last_error ();
    
    [CCode (cname = "vlImageGetWidth")] public UInt get_width();
    [CCode (cname = "vlImageGetHeight")] public UInt get_height();
    [CCode (cname = "vlImageGetFormat")] public int get_format(); 
    
    [CCode (cname = "vlImageGetData")] 
    public Byte* get_data(UInt frame, UInt face, UInt slice, UInt mipmap_level);

    [CCode (cname = "vlImageConvertToRGBA8888")] 
    public Bool convert_to_rgba8888(Byte* source, Byte* dest, UInt width, UInt height, int source_format);
}
