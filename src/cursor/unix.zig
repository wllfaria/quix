const std = @import("std");

const ansi = @import("../ansi/ansi.zig");
const cursor = @import("cursor.zig");
const unix_terminal = @import("../terminal/unix.zig");
const FileDesc = @import("../file_desc.zig");

pub fn moveTo(column: u16, row: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_MOVE_TO, .{ row + 1, column + 1 });
}

pub fn moveToPreviousLine(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_MOVE_PREV_LINE, .{amount});
}

pub fn moveToNextLine(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_MOVE_NEXT_LINE, .{amount});
}

pub fn moveToColumn(column: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_MOVE_TO_COLUMN, .{column});
}

pub fn moveToRow(row: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_MOVE_TO_ROW, .{row});
}

pub fn moveTop(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_MOVE_TOP, .{amount});
}

pub fn moveRight(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_MOVE_RIGHT, .{amount});
}

pub fn moveDown(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_MOVE_DOWN, .{amount});
}

pub fn moveLeft(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_MOVE_LEFT, .{amount});
}

pub fn savePosition() !void {
    const fd = try unix_terminal.getFd();
    return ansi.esc(fd.writer(), ansi.CURSOR_SAVE_POSITION, .{});
}

pub fn restorePosition() !void {
    const fd = try unix_terminal.getFd();
    return ansi.esc(fd.writer(), ansi.CURSOR_RESTORE_POSITION, .{});
}

pub fn hide() !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_HIDE, .{});
}

pub fn show() !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_SHOW, .{});
}

pub fn enableBlinking() !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_ENABLE_BLINKING, .{});
}

pub fn disableBlinking() !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), ansi.CURSOR_DISABLE_BLINKING, .{});
}

pub fn setCursorStyle(style: cursor.CursorStyle) !void {
    const fd = try unix_terminal.getFd();
    switch (style) {
        .DefaultUserShape => return ansi.csi(fd.writer(), ansi.CURSOR_SHAPE_USER_DEFAULT, .{}),
        .BlinkingBlock => return ansi.csi(fd.writer(), ansi.CURSOR_SHAPE_BLINKING_BLOCK, .{}),
        .SteadyBlock => return ansi.csi(fd.writer(), ansi.CURSOR_SHAPE_STEADY_BLOCK, .{}),
        .BlinkingUnderScore => return ansi.csi(fd.writer(), ansi.CURSOR_SHAPE_BLINKING_UNDERSCORE, .{}),
        .SteadyUnderScore => return ansi.csi(fd.writer(), ansi.CURSOR_SHAPE_STEADY_UNDERSCORE, .{}),
        .BlinkingBar => return ansi.csi(fd.writer(), ansi.CURSOR_SHAPE_BLINKING_BAR, .{}),
        .SteadyBar => return ansi.csi(fd.writer(), ansi.CURSOR_SHAPE_STEADY_BAR, .{}),
    }
}
