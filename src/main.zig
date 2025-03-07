const std = @import("std");
const builtin = @import("builtin");

pub const Terminal = @import("terminal.zig");
pub const Event = @import("event.zig");

pub const Handle = switch (builtin.os.tag) {
    .linux => std.posix.fd_t,
    .windows => std.os.windows.HANDLE,
    else => @panic("TODO"),
};

test {
    std.testing.refAllDecls(@This());
}
