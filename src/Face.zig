const Face = @This();
const std = @import("std");
const c = @import("c");
const errors = @import("errors.zig");
const GlyphSlot = @import("GlyphSlot.zig");

ref: c.FT_Face,

pub fn fromRef(ref: c.FT_Face) Face {
    return .{ .ref = ref };
}

pub fn retain(self: Face) errors.Error!Face {
    try errors.check(c.FT_Reference_Face(self.ref));
    return self;
}

pub fn deinit(self: Face) void {
    _ = c.FT_Done_Face(self.ref);
}

pub fn getFamilyName(self: Face) ?[]const u8 {
    const name = self.ref.*.family_name;
    return if (name == null) null else std.mem.span(name);
}

pub fn getPostScriptName(self: Face) ?[]const u8 {
    const name = c.FT_Get_Postscript_Name(self.ref);
    return if (name == null) null else std.mem.span(name);
}

pub const Metrics = struct {
    units_per_em: u16,
    ascent: i16,
    descent: i16,
    height: i16,
};

pub fn getMetrics(self: Face) Metrics {
    return .{
        .units_per_em = self.ref.*.units_per_EM,
        .ascent = self.ref.*.ascender,
        .descent = self.ref.*.descender,
        .height = self.ref.*.height,
    };
}

pub fn getOS2Table(self: Face) ?*const c.TT_OS2 {
    return @ptrCast(@alignCast(c.FT_Get_Sfnt_Table(self.ref, c.FT_SFNT_OS2)));
}

/// Copies a raw SFNT table. The tag uses big-endian order (e.g. 0x4f532f32
/// for OS/2). Returns null for a missing table.
pub fn copyTable(self: Face, allocator: std.mem.Allocator, tag: u32) !?[]u8 {
    var length: c.FT_ULong = 0;
    errors.check(c.FT_Load_Sfnt_Table(
        self.ref,
        tag,
        0,
        null,
        &length,
    )) catch |err| {
        if (err == error.TableMissing) return null;
        return err;
    };

    const size = std.math.cast(usize, length) orelse return error.InputTooLong;
    const bytes = try allocator.alloc(u8, size);
    errdefer allocator.free(bytes);
    if (size != 0) try errors.check(c.FT_Load_Sfnt_Table(
        self.ref,
        tag,
        0,
        bytes.ptr,
        &length,
    ));

    return bytes;
}

pub fn selectCharmap(self: Face, encoding: c.FT_Encoding) errors.Error!void {
    try errors.check(c.FT_Select_Charmap(self.ref, encoding));
}

/// Returns zero when the active charmap has no glyph for the codepoint.
pub fn getCharIndex(self: Face, codepoint: u21) c.FT_UInt {
    return c.FT_Get_Char_Index(self.ref, codepoint);
}

pub fn setCharSize(
    self: Face,
    width: c.FT_F26Dot6,
    height: c.FT_F26Dot6,
    h_dpi: c.FT_UInt,
    v_dpi: c.FT_UInt,
) errors.Error!void {
    try errors.check(c.FT_Set_Char_Size(self.ref, width, height, h_dpi, v_dpi));
}

/// Selects an integer pixel size, including bitmap-only fonts.
pub fn setPixelSizes(self: Face, width: c.FT_UInt, height: c.FT_UInt) errors.Error!void {
    try errors.check(c.FT_Set_Pixel_Sizes(self.ref, width, height));
}

pub fn getSizeMetrics(self: Face) ?c.FT_Size_Metrics {
    const size = self.ref.*.size;
    return if (size == null) null else size.*.metrics;
}

pub fn setTransform(self: Face, matrix: ?c.FT_Matrix, delta: ?c.FT_Vector) void {
    var m = matrix;
    var d = delta;
    c.FT_Set_Transform(
        self.ref,
        if (m) |*value| value else null,
        if (d) |*value| value else null,
    );
}

/// Replaces the face's current glyph slot and invalidates its previous bitmap.
pub fn loadGlyph(self: Face, glyph_index: c.FT_UInt, flags: c.FT_Int32) errors.Error!GlyphSlot {
    try errors.check(c.FT_Load_Glyph(self.ref, glyph_index, flags));
    return .fromRef(self.ref.*.glyph);
}
