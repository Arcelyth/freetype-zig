const Library = @This();
const std = @import("std");
const c = @import("c");
const errors = @import("errors.zig");
const Face = @import("Face.zig");

ref: c.FT_Library,

pub fn fromRef(ref: c.FT_Library) Library {
    return .{ .ref = ref };
}

pub fn init() errors.Error!Library {
    var ref: c.FT_Library = null;
    try errors.check(c.FT_Init_FreeType(&ref));

    return .fromRef(ref);
}

pub fn deinit(self: Library) void {
    _ = c.FT_Done_FreeType(self.ref);
}

/// Opens a face by file path and collection index.
pub fn newFace(self: Library, path: [:0]const u8, face_index: c.FT_Long) errors.Error!Face {
    if (std.mem.indexOfScalar(u8, path, 0) != null) return error.InvalidArgument;
    var ref: c.FT_Face = null;
    try errors.check(c.FT_New_Face(self.ref, path.ptr, face_index, &ref));

    return .fromRef(ref);
}

pub fn newMemoryFace(self: Library, bytes: []const u8, face_index: c.FT_Long) !Face {
    if (bytes.len == 0) return error.InvalidArgument;
    const size = std.math.cast(c.FT_Long, bytes.len) orelse return error.InputTooLong;
    var ref: c.FT_Face = null;
    try errors.check(c.FT_New_Memory_Face(
        self.ref,
        bytes.ptr,
        size,
        face_index,
        &ref,
    ));

    return .fromRef(ref);
}
