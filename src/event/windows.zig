const std = @import("std");
const posix = std.posix;

const quix_winapi = @import("quix_winapi");
const console = quix_winapi.console;

const ansi = @import("../ansi/ansi.zig");
const FileDesc = @import("../file_desc.zig");
const terminal = @import("../terminal/windows.zig");
const constants = @import("../constants.zig");
const event = @import("event.zig");
const Event = event.Event;

const ENABLE_MOUSE_MODE =
    quix_winapi.ENABLE_MOUSE_INPUT |
    quix_winapi.ENABLE_WINDOW_INPUT |
    quix_winapi.ENABLE_EXTENDED_FLAGS;

var ORIGINAL_MODE = std.atomic.Value(u64).init(constants.U64_MAX);

fn initOriginalMode(original_mode: u32) void {
    _ = ORIGINAL_MODE.cmpxchgWeak(constants.U64_MAX, original_mode, .acq_rel, .acq_rel);
}

fn getOriginalMode() !u32 {
    const original_mode = ORIGINAL_MODE.load(.acq_rel);
    if (original_mode == constants.U64_MAX) return error.OriginalModeNotInitialized;
    return @as(u32, @intCast(original_mode));
}

pub fn enableMouse() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        ansi.enableMouse(handle.writer());
        return;
    }

    const handle = try quix_winapi.handle.getCurrentInHandle();
    const mode = try quix_winapi.console.getMode(handle);
    initOriginalMode(mode);
    try quix_winapi.console.setMode(handle, ENABLE_MOUSE_MODE);
}

pub fn disableMouse() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        ansi.disableMouse(handle.writer());
        return;
    }

    const handle = try quix_winapi.handle.getCurrentInHandle();
    const origina_mode = try getOriginalMode();
    try quix_winapi.console.setMode(handle, origina_mode);
}

pub fn poll(_: u32) !bool {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentInHandle();
        const bytes_available = try quix_winapi.console.peekNamedPipe(handle);
        return bytes_available > 0;
    } else {
        const handle = try quix_winapi.handle.getCurrentInHandle();
        const events_read = try quix_winapi.console.peekInput(handle);
        return events_read > 0;
    }
}

pub fn read() !Event {
    if (terminal.hasAnsiSupport()) return readFile();

    const handle = try quix_winapi.handle.getCurrentInHandle();
    const input_record = try console.readSingleInput(handle);
    return parseInputRecord(input_record);
}

fn readFile() !Event {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    var buf: [ansi.IO_BUFFER_SIZE]u8 = undefined;

    while (true) {
        const bytes_read = try std.os.windows.ReadFile(handle.inner, &buf, null);
        if (bytes_read > 0) return ansi.parser.parseAnsi(buf[0..bytes_read]);
    }
}

fn parseInputRecord(input_record: quix_winapi.InputRecord) !Event {
    return switch (input_record) {
        .KeyEvent => |ev| parseKeyEvent(ev),
        .MouseEvent => |ev| parseMouseEvent(ev),
        .WindowBufferSizeEvent => |ev| parseBufferSizeEvent(ev),
        .MenuEvent => |ev| parseMenuEvent(ev),
        .FocusEvent => |ev| parseFocusEvent(ev),
    };
}

fn parseKeyEvent(_: quix_winapi.KeyEventRecord) !Event {
    @panic("TODO");
}

fn parseMouseEvent(_: quix_winapi.MouseEventRecord) !Event {
    @panic("TODO");
}

fn parseBufferSizeEvent(_: quix_winapi.WindowBufferSizeRecord) !Event {
    @panic("TODO");
}
fn parseMenuEvent(_: quix_winapi.MenuEventRecord) !Event {
    @panic("TODO");
}
fn parseFocusEvent(_: quix_winapi.FocusEventRecord) !Event {
    @panic("TODO");
}
