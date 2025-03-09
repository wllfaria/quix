const builtin = @import("builtin");

const Handle = @import("../main.zig").Handle;

const cursor_impl = switch (builtin.os.tag) {
    .linux => @import("unix.zig"),
    .macos => @import("unix.zig"),
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

pub fn moveTo(handle: Handle, column: u16, row: u16) !void {
    return cursor_impl.moveTo(handle, column, row);
}

pub fn moveToPreviousLine(handle: Handle, amount: u16) !void {
    return cursor_impl.moveToPreviousLine(handle, amount);
}

pub fn moveToNextLine(handle: Handle, amount: u16) !void {
    return cursor_impl.moveToNextLine(handle, amount);
}

pub fn moveToColumn(handle: Handle, column: u16) !void {
    return cursor_impl.moveToColumn(handle, column);
}

pub fn moveToRow(handle: Handle, row: u16) !void {
    return cursor_impl.moveToRow(handle, row);
}

pub fn moveTop(handle: Handle, amount: u16) !void {
    return cursor_impl.moveTop(handle, amount);
}

pub fn moveRight(handle: Handle, amount: u16) !void {
    return cursor_impl.moveRight(handle, amount);
}

pub fn moveDown(handle: Handle, amount: u16) !void {
    return cursor_impl.moveDown(handle, amount);
}

pub fn moveLeft(handle: Handle, amount: u16) !void {
    return cursor_impl.moveLeft(handle, amount);
}

pub fn savePosition(handle: Handle) !void {
    return cursor_impl.savePosition(handle);
}

pub fn restorePosition(handle: Handle) !void {
    return cursor_impl.restorePosition(handle);
}

pub fn hide(handle: Handle) !void {
    return cursor_impl.hide(handle);
}

pub fn show(handle: Handle) !void {
    return cursor_impl.show(handle);
}

pub fn enableBlinking(handle: Handle) !void {
    return cursor_impl.enableBlinking(handle);
}

pub fn disableBlinking(handle: Handle) !void {
    return cursor_impl.disableBlinking(handle);
}

pub fn setCursorStyle(handle: Handle, style: CursorStyle) !void {
    return cursor_impl.setCursorStyle(handle, style);
}
