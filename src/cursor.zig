const builtin = @import("builtin");

const Handle = @import("main.zig").Handle;

const cursor = switch (builtin.os.tag) {
    .linux => @import("unix/cursor.zig"),
    .macos => @import("unix/cursor.zig"),
    else => @panic("TODO"),
};

pub const CursorStyle = enum(u7) {
    DefaultUserShape,
    BlinkingBlock,
    SteadyBlock,
    BlinkingUnderScore,
    SteadyUnderScore,
    BlinkingBar,
    SteadyBar,
};

pub fn moveTo(handle: Handle, column: u16, row: u16) !void {
    return cursor.moveTo(handle, column, row);
}

pub fn moveToPreviousLine(handle: Handle, amount: u16) !void {
    return cursor.moveToPreviousLine(handle, amount);
}

pub fn moveToNextLine(handle: Handle, amount: u16) !void {
    return cursor.moveToNextLine(handle, amount);
}

pub fn moveToColumn(handle: Handle, column: u16) !void {
    return cursor.moveToColumn(handle, column);
}

pub fn moveToRow(handle: Handle, row: u16) !void {
    return cursor.moveToRow(handle, row);
}

pub fn moveTop(handle: Handle, amount: u16) !void {
    return cursor.moveTop(handle, amount);
}

pub fn moveRight(handle: Handle, amount: u16) !void {
    return cursor.moveRight(handle, amount);
}

pub fn moveDown(handle: Handle, amount: u16) !void {
    return cursor.moveDown(handle, amount);
}

pub fn moveLeft(handle: Handle, amount: u16) !void {
    return cursor.moveLeft(handle, amount);
}

pub fn savePosition(handle: Handle) !void {
    return cursor.savePosition(handle);
}

pub fn restorePosition(handle: Handle) !void {
    return cursor.restorePosition(handle);
}

pub fn hide(handle: Handle) !void {
    return cursor.hide(handle);
}

pub fn show(handle: Handle) !void {
    return cursor.show(handle);
}

pub fn enableBlinking(handle: Handle) !void {
    return cursor.enableBlinking(handle);
}

pub fn disableBlinking(handle: Handle) !void {
    return cursor.disableBlinking(handle);
}

pub fn setCursorStyle(handle: Handle, style: cursor.CursorStyle) !void {
    return cursor.setCursorStyle(handle, style);
}
