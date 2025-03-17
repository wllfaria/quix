const std = @import("std");
const posix = std.posix;
const timeout = @import("timeout.zig");

const ansi = @import("../ansi/ansi.zig");
const FileDesc = @import("../file_desc.zig");
const terminal = @import("../terminal/unix.zig");
const event = @import("event.zig");
const Event = @import("event.zig").Event;

/// Enables mouse tracking
pub fn enableMouse() !void {
    const fd = try terminal.getFd();
    ansi.enableMouse(fd.writer());
}

/// Disables mouse tracking
pub fn disableMouse() !void {
    const fd = try terminal.getFd();
    ansi.disableMouse(fd.writer());
}

pub fn read() !Event {
    const fd = try terminal.getFd();
    var buf: [ansi.IO_BUFFER_SIZE]u8 = undefined;

    while (true) {
        const bytes_read = try posix.read(fd.handle, &buf);
        if (bytes_read > 0) return ansi.parser.parseAnsi(buf[0..bytes_read]);
    }
}

pub fn poll(duration_ms: u32) !bool {
    const poll_timeout = timeout.PollTimeout.new(duration_ms);

    while (poll_timeout.leftover() > 0) {
        const fd = try terminal.getFd();

        const poll_fd = posix.pollfd{
            .fd = fd.handle,
            .events = posix.POLL.IN,
            .revents = 0,
        };

        const ret = try posix.poll(
            &[_]posix.pollfd{poll_fd},
            @as(i32, @intCast(poll_timeout.leftover())),
        );

        if (ret > 0) return true;
    }

    return false;
}
