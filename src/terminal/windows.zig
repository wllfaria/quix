const std = @import("std");
const windows = std.os.windows;

const quix_winapi = @import("quix_winapi");
const ConsoleError = quix_winapi.ConsoleError;
const console = quix_winapi.console;
const screen_buffer = quix_winapi.screen_buffer;

const ansi = @import("../ansi/ansi.zig");
const terminal = @import("terminal.zig");

const COOKED_MODE_FLAGS: windows.DWORD =
    quix_winapi.ENABLE_LINE_INPUT |
    quix_winapi.ENABLE_PROCESSED_INPUT |
    quix_winapi.ENABLE_ECHO_INPUT;

var has_ansi_support = std.atomic.Value(bool).init(false);
var has_ansi_support_initializer = std.once(ansiInitializer);
var original_mode: ?windows.DWORD = null;

pub fn enableVirtualTerminal() ConsoleError!void {
    const mask = quix_winapi.ENABLE_VIRTUAL_TERMINAL_INPUT;
    const handle = try quix_winapi.handle.getCurrentInHandle();
    const mode = try console.getMode(handle);
    // flag is not set, so virtual terminal mode is not enabled
    if (mode & mask == 0) try console.setMode(handle, mode | mask);
}

pub fn hasAnsiSupport() bool {
    has_ansi_support_initializer.call();
    return has_ansi_support.load(.seq_cst);
}

fn ansiInitializer() void {
    enableVirtualTerminal() catch return;
    has_ansi_support.store(true, .seq_cst);
}

pub fn isRawModeEnabled() ConsoleError!bool {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    const mode = try console.getMode(handle);
    // every bit of cooked mode must be zero for the terminal to be in raw mode
    return mode & COOKED_MODE_FLAGS == 0;
}

pub fn enableRawMode() ConsoleError!void {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    const mode = try console.getMode(handle);

    const new_mode = mode & (~COOKED_MODE_FLAGS);
    try console.setMode(handle, new_mode);
    // only store the original mode if we were able to switch
    original_mode = mode;
}

pub fn disableRawMode() ConsoleError!void {
    if (original_mode) |og| {
        const handle = try quix_winapi.handle.getCurrentInHandle();
        try console.setMode(handle, og);
        // only replace if we were able to wswitch
        original_mode = null;
    }
}

// I (wiru) couldn't find a way to get the size in pixels of the terminal on
// windows.
pub fn windowSize() ConsoleError!terminal.WindowSize {
    return ConsoleError.Unsupported;
}

pub fn size() ConsoleError!terminal.Size {
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

pub fn disableLineWrap() ConsoleError!void {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    var mode = try console.getMode(handle);
    mode &= ~quix_winapi.ENABLE_WRAP_AT_EOL_OUTPUT;
    console.setMode(handle, mode);
}

pub fn enableLineWrap() ConsoleError!void {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    var mode = try console.getMode(handle);
    mode |= quix_winapi.ENABLE_WRAP_AT_EOL_OUTPUT;
    console.setMode(handle, mode);
}

pub fn enterAlternateScreen() !void {
    if (hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        try ansi.csi(handle.writer(), ansi.ENTER_ALTERNATE_SCREEN_FMT, .{});
        return;
    }

    const alternate_screen = try screen_buffer.create();
    try alternate_screen.show();
}

pub fn exitAlternateScreen() !void {
    if (hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        try ansi.csi(handle.writer(), ansi.EXIT_ALTERNATE_SCREEN_FMT, .{});
        return;
    }

    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const sb = screen_buffer.fromHandle(handle);
    try sb.show();
}

pub fn scrollUp(amount: u16) !void {
    if (amount == 0) return;

    const handle = try quix_winapi.handle.getCurrentOutHandle();
    if (hasAnsiSupport()) {
        try ansi.csi(handle.writer(), ansi.SCROLL_UP_FMT, .{amount});
        return;
    }

    const csbi = try console.getInfo(handle);
    var window = csbi.terminalWindow();

    const count = @as(i16, @intCast(amount));
    // check if we would hit the top of the screen buffer.
    if (window.top >= count) {
        window.top -= count;
        window.bottom -= count;
        try console.setInfo(handle, .absolute, window);
    }
}

pub fn scrollDown(amount: u16) !void {
    if (amount == 0) return;

    const handle = try quix_winapi.handle.getCurrentOutHandle();
    if (hasAnsiSupport()) {
        try ansi.csi(handle.writer(), ansi.SCROLL_DOWN_FMT, .{amount});
        return;
    }

    const csbi = try console.getInfo(handle);
    var window = csbi.terminalWindow();
    const buffer_size = csbi.bufferSize();

    const count = @as(i16, @intCast(amount));
    // check if we would hit the bottom of the screen buffer.
    if (window.bottom < buffer_size.height - count) {
        window.top += count;
        window.bottom += count;
        try console.setInfo(handle, .absolute, window);
    }
}

pub fn clear(clear_type: terminal.ClearType) !void {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    switch (clear_type) {
        .All => try ansi.csi(handle.writer(), ansi.CLEAR_ALL_FMT, .{}),
        .Purge => try ansi.csi(handle.writer(), ansi.CLEAR_PURGE_FMT, .{}),
        .FromCursorDown => try ansi.csi(handle.writer(), ansi.CLEAR_CURSOR_DOWN_FMT, .{}),
        .FromCursorUp => try ansi.csi(handle.writer(), ansi.CLEAR_CURSOR_UP_FMT, .{}),
        .CurrentLine => try ansi.csi(handle.writer(), ansi.CLEAR_CURRENT_LINE_FMT, .{}),
        .UntilNewline => try ansi.csi(handle.writer(), ansi.CLEAR_UNTIL_NEWLINE_FMT, .{}),
    }
}
