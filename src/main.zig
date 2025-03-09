const std = @import("std");
const builtin = @import("builtin");

pub const terminal = @import("terminal/terminal.zig");
pub const event = @import("event/event.zig");
pub const cursor = @import("cursor/cursor.zig");
pub const style = @import("style/style.zig");

pub const Handle = switch (builtin.os.tag) {
    .linux => std.posix.fd_t,
    .windows => std.os.windows.HANDLE,
    else => @panic("TODO"),
};

test {
    std.testing.refAllDecls(@This());
}
