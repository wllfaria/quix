const std = @import("std");
const posix = std.posix;

const ansi = @import("../ansi/ansi.zig");
const FileDesc = @import("../file_desc.zig");
const quix_winapi = @import("../quix-windows/main.zig");
const console = quix_winapi.console;
const terminal = @import("../terminal/windows.zig");
const event = @import("event.zig");
const Event = @import("event.zig").Event;

pub fn enableMouse() !void {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    if (terminal.hasAnsiSupport()) {
        ansi.enableMouse(handle.writer());
        return;
    }

    @panic("TODO");
}

pub fn disableMouse() !void {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    if (terminal.hasAnsiSupport()) {
        ansi.disableMouse(handle.writer());
        return;
    }

    @panic("TODO");
}

pub fn read() !Event {
    if (terminal.hasAnsiSupport()) return readFile();

    const handle = try quix_winapi.handle.getCurrentInHandle();
    var buffer: [32]quix_winapi.InputRecord = undefined;
    _ = try console.readConsoleInput(handle, &buffer);

    @panic("TODO");
}

fn readFile() !Event {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    var buf: [ansi.IO_BUFFER_SIZE]u8 = undefined;

    while (true) {
        const bytes_read = try std.os.windows.ReadFile(handle.inner, &buf, null);
        if (bytes_read > 0) {
            return ansi.parser.parseAnsi(buf[0..bytes_read]);
        }
    }
}
