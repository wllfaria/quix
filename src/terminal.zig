const std = @import("std");
const testing = std.testing;
const posix = std.posix;
const builtin = @import("builtin");

const Handle = @import("main.zig").Handle;

const terminal = switch (builtin.os.tag) {
    .linux => @import("unix/terminal.zig"),
    else => @panic("TODO"),
};

pub const ClearType = enum(u3) {
    All,
    Purge,
    FromCursorDown,
    FromCursorUp,
    CurrentLine,
    UntilNewline,
};

pub fn isRawModeEnabled() !bool {
    return terminal.isRawModeEnabled();
}

pub fn enableRawMode(handle: Handle) !void {
    return terminal.enableRawMode(handle);
}

pub fn disableRawMode(handle: Handle) !void {
    return terminal.disableRawMode(handle);
}

pub fn windowSize(handle: Handle) !terminal.WindowSize {
    return terminal.windowSize(handle);
}

pub fn disableLineWrap(handle: Handle) !void {
    return terminal.disableLineWrap(handle);
}

pub fn enableLineWrap(handle: Handle) !void {
    return terminal.enableLineWrap(handle);
}

pub fn enterAlternateScreen(handle: Handle) !void {
    return terminal.enterAlternateScreen(handle);
}

pub fn exitAlternateScreen(handle: Handle) !void {
    return terminal.exitAlternateScreen(handle);
}

pub fn scrollUp(handle: Handle, amount: u16) !void {
    return terminal.scrollUp(handle, amount);
}

pub fn scrollDown(handle: Handle, amount: u16) !void {
    return terminal.scrollDown(handle, amount);
}

pub fn clear(handle: Handle, clear_type: ClearType) !void {
    return terminal.clear(handle, clear_type);
}
