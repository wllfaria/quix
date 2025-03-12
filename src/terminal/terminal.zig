const std = @import("std");
const testing = std.testing;
const posix = std.posix;
const builtin = @import("builtin");

const Handle = @import("../main.zig").Handle;

const terminal_impl = switch (builtin.os.tag) {
    .linux => @import("unix.zig"),
    .macos => @import("unix.zig"),
    .windows => @import("windows.zig"),
    else => @panic("TODO"),
};

/// Different ways in which the terminal screen can be cleared.
pub const ClearType = enum(u3) {
    /// Clear every line on the terminal screen.
    All,
    /// Clear saved lines.
    Purge,
    /// Clear lines starting from the cursor to the end of the screen.
    FromCursorDown,
    /// Clear lines starting from the cursor to the start of the screen.
    FromCursorUp,
    /// Clear the current line.
    CurrentLine,
    /// Clear from the cursor position until next line.
    UntilNewline,
};

/// Current terminal window size in rows/cols and also in pixels.
pub const WindowSize = struct {
    /// Amount of lines on the terminal screen.
    rows: u16,
    /// Amount of columns on the terminal screen.
    cols: u16,
    /// Pixel width of the terminal screen.
    width: u16,
    /// Pixel height of the terminal screen.
    height: u16,
};

pub const Size = struct {
    cols: u16,
    rows: u16,
};

pub fn closeHandle() !void {
    return terminal_impl.closeHandle();
}

pub fn isRawModeEnabled() !bool {
    return terminal_impl.isRawModeEnabled();
}

pub fn enableRawMode() !void {
    return terminal_impl.enableRawMode();
}

pub fn disableRawMode() !void {
    return terminal_impl.disableRawMode();
}

pub fn windowSize() !WindowSize {
    return terminal_impl.windowSize();
}

pub fn size() !Size {
    return terminal_impl.size();
}

pub fn setSize(columns: u16, rows: u16) !void {
    return terminal_impl.setSize(columns, rows);
}

pub fn disableLineWrap() !void {
    return terminal_impl.disableLineWrap();
}

pub fn enableLineWrap() !void {
    return terminal_impl.enableLineWrap();
}

pub fn enterAlternateScreen() !void {
    return terminal_impl.enterAlternateScreen();
}

pub fn exitAlternateScreen() !void {
    return terminal_impl.exitAlternateScreen();
}

pub fn scrollUp(amount: u16) !void {
    return terminal_impl.scrollUp(amount);
}

pub fn scrollDown(amount: u16) !void {
    return terminal_impl.scrollDown(amount);
}

pub fn clear(clear_type: ClearType) !void {
    return terminal_impl.clear(clear_type);
}

test "raw mode" {
    try std.testing.expectEqual(false, try isRawModeEnabled());

    try enableRawMode();
    try std.testing.expectEqual(true, try isRawModeEnabled());

    // setting raw mode again should do nothing
    try enableRawMode();
    try std.testing.expectEqual(true, try isRawModeEnabled());

    try disableRawMode();
    try std.testing.expectEqual(false, try isRawModeEnabled());
}

test {
    std.testing.refAllDecls(@This());
}
