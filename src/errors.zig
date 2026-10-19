const c = @import("c");

pub const Error = error{
    OutOfMemory,
    CannotOpenResource,
    UnknownFileFormat,
    InvalidFileFormat,
    InvalidArgument,
    UnimplementedFeature,
    InvalidGlyphIndex,
    InvalidPixelSize,
    CannotRenderGlyph,
    TableMissing,
    FreeTypeFailure,
};

pub fn check(result: c.FT_Error) Error!void {
    // FreeType may encode a module identifier in the high byte.
    return switch (result & 0xff) {
        c.FT_Err_Ok => {},
        c.FT_Err_Out_Of_Memory => error.OutOfMemory,
        c.FT_Err_Cannot_Open_Resource => error.CannotOpenResource,
        c.FT_Err_Unknown_File_Format => error.UnknownFileFormat,
        c.FT_Err_Invalid_File_Format => error.InvalidFileFormat,
        c.FT_Err_Invalid_Argument => error.InvalidArgument,
        c.FT_Err_Unimplemented_Feature => error.UnimplementedFeature,
        c.FT_Err_Invalid_Glyph_Index => error.InvalidGlyphIndex,
        c.FT_Err_Invalid_Pixel_Size => error.InvalidPixelSize,
        c.FT_Err_Cannot_Render_Glyph => error.CannotRenderGlyph,
        c.FT_Err_Table_Missing => error.TableMissing,
        else => error.FreeTypeFailure,
    };
}
