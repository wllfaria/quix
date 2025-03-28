const std = @import("std");
const windows = std.os.windows;

const quix_winapi = @import("quix_winapi");
const ConsoleError = quix_winapi.ConsoleError;
const console = quix_winapi.console;
const constants = @import("../constants.zig");
const screen_buffer = quix_winapi.screen_buffer;

const ansi = @import("../ansi/ansi.zig");
const cursor = @import("../cursor/windows.zig");
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

// nothing to do here
pub fn closeHandle() !void {}

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
    if (hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        try ansi.csi(handle.writer(), ansi.SET_SIZE_FMT, .{ rows, columns });
        return;
    }

    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const csbi = try quix_winapi.console.getInfo(handle);

    const current_size = csbi.bufferSize();
    var window = csbi.terminalWindow();

    var new_size = quix_winapi.Size{
        .width = current_size.width,
        .height = current_size.height,
    };

    var resize_buffer = false;

    const width = @as(u16, @intCast(columns));
    if (current_size.width < window.left + width) {
        if (window.left >= constants.I16_MAX - width) return error.TerminalWidthTooLarge;
        new_size.width = window.left + width;
        resize_buffer = true;
    }

    const height = @as(u16, @intCast(rows));
    if (current_size.height < window.top + height) {
        if (window.top > constants.I16_MAX - height) return error.TerminalHeightTooLarge;
        new_size.height = window.top + height;
        resize_buffer = true;
    }

    // if the window would be bigger than the buffer, there might be clipping or
    // scrolling issues, resizing the buffer here temporarily avoids that.
    if (resize_buffer) {
        try quix_winapi.console.setSize(
            handle,
            new_size.width - 1,
            new_size.height - 1,
        );
    }

    // update window size preserving its position
    window.bottom = window.top + height - 1;
    window.right = window.left + width - 1;
    try quix_winapi.console.setInfo(handle, .absolute, window);

    // if the buffer was resized, un-resize it to maintain the original size.
    if (resize_buffer) {
        try quix_winapi.console.setSize(
            handle,
            current_size.width - 1,
            current_size.height - 1,
        );
    }

    const bounds = try quix_winapi.console.largestWindowSize(handle);

    if (width > bounds.x) return error.TerminalWidthTooLarge;
    if (height > bounds.y) return error.TerminalHeightTooLarge;
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

    if (hasAnsiSupport()) {
        switch (clear_type) {
            .All => try ansi.csi(handle.writer(), ansi.CLEAR_ALL_FMT, .{}),
            .Purge => try ansi.csi(handle.writer(), ansi.CLEAR_PURGE_FMT, .{}),
            .FromCursorDown => try ansi.csi(handle.writer(), ansi.CLEAR_CURSOR_DOWN_FMT, .{}),
            .FromCursorUp => try ansi.csi(handle.writer(), ansi.CLEAR_CURSOR_UP_FMT, .{}),
            .CurrentLine => try ansi.csi(handle.writer(), ansi.CLEAR_CURRENT_LINE_FMT, .{}),
            .UntilNewline => try ansi.csi(handle.writer(), ansi.CLEAR_UNTIL_NEWLINE_FMT, .{}),
        }
        return;
    }

    const csbi = try console.getInfo(handle);
    const pos = csbi.cursorPosition();
    const buffer_size = csbi.bufferSize();
    const attributes = csbi.attributes();

    switch (clear_type) {
        .All => try clearEntireScreen(buffer_size, attributes),
        .FromCursorDown => try clearAfterCursor(pos, buffer_size, attributes),
        .FromCursorUp => try clearBeforeCursor(pos, buffer_size, attributes),
        .CurrentLine => try clearCurrentLine(pos, buffer_size, attributes),
        .UntilNewline => try clearUntilNewline(pos, buffer_size, attributes),
        else => try clearEntireScreen(buffer_size, attributes),
    }
}

fn clearEntireScreen(buffer_size: quix_winapi.Size, attributes: u16) !void {
    const width = @as(u32, @intCast(buffer_size.width));
    const height = @as(u32, @intCast(buffer_size.height));
    const total_cells: u32 = width * height;
    const start_location = quix_winapi.Coord.new(0, 0);
    try clearWinapi(start_location, total_cells, attributes);
    try cursor.moveTo(0, 0);
}

fn clearAfterCursor(
    position: quix_winapi.Coord,
    buffer_size: quix_winapi.Size,
    attributes: u16,
) !void {
    var x = position.x;
    var y = position.y;

    if (x > buffer_size.width) {
        x = 0;
        y += 1;
    }

    const start_location = quix_winapi.Coord.new(x, y);
    const width = @as(u32, @intCast(buffer_size.width));
    const height = @as(u32, @intCast(buffer_size.height));
    const total_cells: u32 = width * height;

    try clearWinapi(start_location, total_cells, attributes);
}

fn clearBeforeCursor(
    position: quix_winapi.Coord,
    buffer_size: quix_winapi.Size,
    attributes: u16,
) !void {
    const xPos = @as(u32, @intCast(position.x));
    const yPos = @as(u32, @intCast(position.x));

    const x = 0;
    const y = 0;

    const start_location = quix_winapi.Coord.new(x, y);
    const width = @as(u32, @intCast(buffer_size.width));
    const total_cells: u32 = (width * yPos) + (xPos + 1);

    try clearWinapi(start_location, total_cells, attributes);
}

fn clearCurrentLine(
    position: quix_winapi.Coord,
    buffer_size: quix_winapi.Size,
    attributes: u16,
) !void {
    const start_location = quix_winapi.Coord.new(0, position.y);
    const total_cells: u32 = @as(u32, @intCast(buffer_size.width));

    try clearWinapi(start_location, total_cells, attributes);
    try cursor.moveTo(0, @as(u16, @intCast(position.y)));
}

fn clearUntilNewline(
    position: quix_winapi.Coord,
    buffer_size: quix_winapi.Size,
    attributes: u16,
) !void {
    const x = position.x;
    const y = position.y;

    const start_location = quix_winapi.Coord.new(x, y);
    const width = @as(u32, @intCast(buffer_size.width));
    const total_cells: u32 = width - @as(u32, @intCast(x));

    try clearWinapi(start_location, total_cells, attributes);
    try cursor.moveTo(@as(u16, @intCast(position.x)), @as(u16, @intCast(position.y)));
}

fn clearWinapi(start_location: quix_winapi.Coord, total_cells: u32, attribute: u16) !void {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    _ = try console.fillWithChar(handle, ' ', total_cells, start_location);
    _ = try console.fillWithAttribute(handle, attribute, total_cells, start_location);
}
