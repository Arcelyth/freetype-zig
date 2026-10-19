const GlyphSlot = @This();
const c = @import("c");
const errors = @import("errors.zig");
const Bitmap = @import("Bitmap.zig");

ref: c.FT_GlyphSlot,

pub fn fromRef(ref: c.FT_GlyphSlot) GlyphSlot {
    return .{ .ref = ref };
}

pub fn getMetrics(self: GlyphSlot) c.FT_Glyph_Metrics {
    return self.ref.*.metrics;
}

pub fn getAdvance(self: GlyphSlot) c.FT_Vector {
    return self.ref.*.advance;
}

pub fn render(self: GlyphSlot, mode: c.FT_Render_Mode) errors.Error!Bitmap {
    try errors.check(c.FT_Render_Glyph(self.ref, mode));
    return self.getBitmap();
}

pub fn getBitmap(self: GlyphSlot) Bitmap {
    return .{ .raw = self.ref.*.bitmap };
}

pub fn getBitmapLeft(self: GlyphSlot) c.FT_Int {
    return self.ref.*.bitmap_left;
}

pub fn getBitmapTop(self: GlyphSlot) c.FT_Int {
    return self.ref.*.bitmap_top;
}
