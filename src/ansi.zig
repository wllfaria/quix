const std = @import("std");
const posix = std.posix;

pub const FileDesc = struct {
    fd: posix.fd_t,

    pub fn init(fd: posix.fd_t) @This() {
        return @This(){ .fd = fd };
    }
};

pub fn write(ptr: *const anyopaque, bytes: []const u8) !usize {
    const handle: *const FileDesc = @ptrCast(@alignCast(ptr));
    return posix.write(handle.fd, bytes);
}

pub fn csi(handle: FileDesc, comptime command: []const u8, args: anytype) !void {
    const writer = std.io.AnyWriter{ .context = &handle, .writeFn = write };
    _ = try writer.print("\x1b[" ++ command, args);
}

pub fn esc(handle: FileDesc, comptime command: []const u8, args: anytype) !void {
    const writer = std.io.AnyWriter{ .context = &handle, .writeFn = write };
    _ = try writer.print("\x1b" ++ command, args);
}
