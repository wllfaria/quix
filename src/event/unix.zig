const std = @import("std");
const posix = std.posix;

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
        if (bytes_read > 0) {
            return ansi.parser.parseAnsi(buf[0..bytes_read]);
        }
    }
}
