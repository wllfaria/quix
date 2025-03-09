const std = @import("std");
const testing = std.testing;
const posix = std.posix;
const builtin = @import("builtin");

const Handle = @import("../main.zig").Handle;

const terminal_impl = switch (builtin.os.tag) {
    .linux => @import("unix.zig"),
    .macos => @import("unix.zig"),
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

pub fn isRawModeEnabled() !bool {
    return terminal_impl.isRawModeEnabled();
}

pub fn enableRawMode(handle: Handle) !void {
    return terminal_impl.enableRawMode(handle);
}

pub fn disableRawMode(handle: Handle) !void {
    return terminal_impl.disableRawMode(handle);
}

pub fn windowSize(handle: Handle) !WindowSize {
    return terminal_impl.windowSize(handle);
}

pub fn size(handle: Handle) !Size {
    return terminal_impl.size(handle);
}

pub fn setSize(handle: Handle, columns: u16, rows: u16) !void {
    return terminal_impl.setSize(handle, columns, rows);
}

pub fn disableLineWrap(handle: Handle) !void {
    return terminal_impl.disableLineWrap(handle);
}

pub fn enableLineWrap(handle: Handle) !void {
    return terminal_impl.enableLineWrap(handle);
}

pub fn enterAlternateScreen(handle: Handle) !void {
    return terminal_impl.enterAlternateScreen(handle);
}

pub fn exitAlternateScreen(handle: Handle) !void {
    return terminal_impl.exitAlternateScreen(handle);
}

pub fn scrollUp(handle: Handle, amount: u16) !void {
    return terminal_impl.scrollUp(handle, amount);
}

pub fn scrollDown(handle: Handle, amount: u16) !void {
    return terminal_impl.scrollDown(handle, amount);
}

pub fn clear(handle: Handle, clear_type: ClearType) !void {
    return terminal_impl.clear(handle, clear_type);
}

test "raw mode" {
    const handle = try std.posix.open("/dev/tty", .{ .ACCMODE = .RDWR }, 0);
    try std.testing.expectEqual(false, try isRawModeEnabled());

    try enableRawMode(handle);
    try std.testing.expectEqual(true, try isRawModeEnabled());

    // setting raw mode again should do nothing
    try enableRawMode(handle);
    try std.testing.expectEqual(true, try isRawModeEnabled());

    try disableRawMode(handle);
    try std.testing.expectEqual(false, try isRawModeEnabled());
}

test {
    std.testing.refAllDecls(@This());
}
