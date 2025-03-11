const std = @import("std");
const windows = std.os.windows;

const terminal = @import("terminal.zig");
const quix_winapi = @import("../quix-windows/main.zig");
const console = quix_winapi.console;
const screen_buffer = quix_winapi.screen_buffer;

const COOKED_MODE_FLAGS: windows.DWORD =
    quix_winapi.ENABLE_LINE_INPUT |
    quix_winapi.ENABLE_PROCESSED_INPUT |
    quix_winapi.ENABLE_ECHO_INPUT;

pub fn isRawModeEnabled() !bool {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    const mode = try console.getMode(handle);

    // every bit of cooked mode must be zero for the terminal to be in raw mode
    return mode & COOKED_MODE_FLAGS == 0;
}

pub fn enableRawMode() quix_winapi.ConsoleError!void {
    const handle = try quix_winapi.handle.getCurrentInHandle();

    const mode = try console.getMode(handle);

    const new_mode = mode & (~COOKED_MODE_FLAGS);

    try console.setMode(handle, new_mode);
}

pub fn disableRawMode() quix_winapi.ConsoleError!void {
    const handle = try quix_winapi.handle.getCurrentInHandle();

    var mode = try console.getMode(handle);

    mode |= COOKED_MODE_FLAGS;

    try console.setMode(handle, mode);
}

pub fn windowSize() quix_winapi.ConsoleError!terminal.WindowSize {
    return quix_winapi.ConsoleError.Unsupported;
}

pub fn size() quix_winapi.ConsoleError!terminal.Size {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const info = try console.getInfo(handle);
    const term_size = info.terminalSize();
    // windows width and height are 0 based, in unix they are 1 based, +1 here
    // makes it uniform across platforms.
    return terminal.Size{
        .rows = @as(u16, @intCast(term_size.height)) + 1,
        .cols = @as(u16, @intCast(term_size.width)) + 1,
    };
}

pub fn setSize(columns: u16, rows: u16) !void {
    _ = columns; // autofix
    _ = rows; // autofix
    @panic("TODO");
}

pub fn disableLineWrap() quix_winapi.ConsoleError!void {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    var mode = try console.getMode(handle);
    mode &= ~quix_winapi.ENABLE_WRAP_AT_EOL_OUTPUT;
    console.setMode(handle, mode);
}

pub fn enableLineWrap() quix_winapi.ConsoleError!void {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    var mode = try console.getMode(handle);
    mode |= quix_winapi.ENABLE_WRAP_AT_EOL_OUTPUT;
    console.setMode(handle, mode);
}

pub fn enterAlternateScreen() !void {
    const alternate_screen = try screen_buffer.create();
    try alternate_screen.show();
}

pub fn exitAlternateScreen() !void {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const sb = screen_buffer.fromHandle(handle);
    try sb.show();
}

pub fn scrollUp(amount: u16) !void {
    _ = amount; // autofix
    @panic("TODO");
}

pub fn scrollDown(amount: u16) !void {
    _ = amount; // autofix
    @panic("TODO");
}

pub fn clear(clear_type: terminal.ClearType) !void {
    _ = clear_type; // autofix
    @panic("TODO");
}
