const std = @import("std");
const builtin = @import("builtin");

pub const terminal = @import("terminal.zig");
pub const event = @import("event.zig");
pub const cursor = @import("cursor.zig");
pub const style = @import("style.zig");

pub const Handle = switch (builtin.os.tag) {
    .linux => std.posix.fd_t,
    .windows => std.os.windows.HANDLE,
    else => @panic("TODO"),
};

test {
    std.testing.refAllDecls(@This());
}
