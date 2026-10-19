const Bitmap = @This();
const std = @import("std");
const c = @import("c");

raw: c.FT_Bitmap,

/// Returns a row from top to bottom, including pitch padding. Supports either
/// pitch sign and empty bitmaps. The bytes retain FreeType's native pixel format.
pub fn row(self: Bitmap, y: usize) []const u8 {
    std.debug.assert(y < self.raw.rows);

    if (self.raw.buffer == null or self.raw.width == 0) return &.{};
    const stride: usize = @intCast(@abs(self.raw.pitch));
    const storage_row = if (self.raw.pitch < 0) self.raw.rows - 1 - y else y;
    const start = self.raw.buffer + storage_row * stride;

    return start[0..stride];
}
