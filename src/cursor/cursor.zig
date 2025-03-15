const std = @import("std");
const builtin = @import("builtin");

const Handle = @import("../main.zig").Handle;
const terminal = @import("../terminal/terminal.zig");

const cursor_impl = switch (builtin.os.tag) {
    .linux => @import("unix.zig"),
    .macos => @import("unix.zig"),
    .windows => @import("windows.zig"),
    else => @panic("TODO"),
};

/// Available cursor styles.
pub const CursorStyle = enum(u7) {
    /// The default user-configured cursor shape.
    DefaultUserShape,
    /// Blinking block cursor shape (█).
    BlinkingBlock,
    /// Steady block cursor shape (█).
    SteadyBlock,
    /// Blinking underscore cursor shape (_).
    BlinkingUnderScore,
    /// Steady underscore cursor shape (_).
    SteadyUnderScore,
    /// Blinking bar cursor shape ( ▏).
    BlinkingBar,
    /// Steady bar cursor shape ( ▏).
    SteadyBar,
};

pub fn moveTo(column: u16, row: u16) !void {
    return cursor_impl.moveTo(column, row);
}

pub fn moveToPreviousLine(amount: u16) !void {
    return cursor_impl.moveToPreviousLine(amount);
}

pub fn moveToNextLine(amount: u16) !void {
    return cursor_impl.moveToNextLine(amount);
}

pub fn moveToColumn(column: u16) !void {
    return cursor_impl.moveToColumn(column);
}

pub fn moveToRow(row: u16) !void {
    return cursor_impl.moveToRow(row);
}

pub fn moveTop(amount: u16) !void {
    return cursor_impl.moveTop(amount);
}

pub fn moveRight(amount: u16) !void {
    return cursor_impl.moveRight(amount);
}

pub fn moveDown(amount: u16) !void {
    return cursor_impl.moveDown(amount);
}

pub fn moveLeft(amount: u16) !void {
    return cursor_impl.moveLeft(amount);
}

pub fn position() !terminal.Size {
    return cursor_impl.position();
}

pub fn savePosition() !void {
    return cursor_impl.savePosition();
}

pub fn restorePosition() !void {
    return cursor_impl.restorePosition();
}

pub fn hide() !void {
    return cursor_impl.hide();
}

pub fn show() !void {
    return cursor_impl.show();
}

pub fn enableBlinking() !void {
    return cursor_impl.enableBlinking();
}

pub fn disableBlinking() !void {
    return cursor_impl.disableBlinking();
}

pub fn setCursorStyle(style: CursorStyle) !void {
    return cursor_impl.setCursorStyle(style);
}
