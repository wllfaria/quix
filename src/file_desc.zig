const std = @import("std");
const posix = std.posix;

pub const FileDesc = struct {
    handle: posix.fd_t,
    close_handle: bool,

    pub fn init(fd: posix.fd_t) @This() {
        return @This(){ .handle = fd, .close_handle = false };
    }

    pub fn writer(self: *const @This()) std.io.AnyWriter {
        return std.io.AnyWriter{ .context = self, .writeFn = &writeAll };
    }
};

pub fn writeAll(context: *const anyopaque, bytes: []const u8) !usize {
    const self: *FileDesc = @constCast(@ptrCast(@alignCast(context)));
    const amount = try posix.write(self.handle, bytes);
    return amount;
}
