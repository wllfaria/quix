const std = @import("std");
const posix = std.posix;

const ansi = @import("../ansi.zig");
const event = @import("event.zig");
const FileDesc = @import("../file_desc.zig");
const terminal = @import("../terminal/windows.zig");
const quix_winapi = @import("../quix-windows/main.zig");
const console = quix_winapi.console;

const Event = @import("event.zig").Event;

pub fn read() !Event {
    // if (terminal.hasAnsiSupport()) {
    //     return error.NotSupported;
    // }
    const handle = try quix_winapi.handle.getCurrentInHandle();
    var buffer: [32]quix_winapi.InputRecord = undefined;
    const input = try console.readConsoleInput(handle, &buffer);
    std.debug.print("{any}\n", .{input});

    return Event.FocusGained;
}

pub fn enableMouse() !void {}

pub fn disableMouse() !void {}
