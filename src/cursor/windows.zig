const std = @import("std");

const quix_winapi = @import("quix_winapi");

const ansi = @import("../ansi/ansi.zig");
const terminal = @import("../terminal/windows.zig");
const cursor = @import("cursor.zig");

const U64_MAX = 0xFFFFFFFF_FFFFFFFF;

/// The position of the cursor, written when you save the cursor's position in
/// legacy terminals which don't support ansi.
var SAVED_CURSOR_POS = std.atomic.Value(u64).init(U64_MAX);

fn convertRelativeY(csbi: quix_winapi.csbi.Csbi, relative_y: i16) i16 {
    const terminal_size = csbi.terminalSize();
    const window_size = csbi.terminalWindow();

    if (relative_y <= terminal_size.height) return relative_y;
    return relative_y - window_size.top;
}

fn position() !cursor.Position {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const csbi = try quix_winapi.console.getInfo(handle);

    var pos = csbi.cursorPosition();

    pos.y = convertRelativeY(handle, pos.y);

    return cursor.Position{
        .column = @as(u16, pos.x),
        .row = @as(u16, pos.y),
    };
}

pub fn moveTo(column: u16, row: u16) !void {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    if (terminal.hasAnsiSupport()) {
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_TO, .{ row + 1, column + 1 });
    }

    const win_column = @as(i16, @intCast(column));
    const win_row = @as(i16, @intCast(row));
    const coord = quix_winapi.Coord.new(win_column, win_row);
    try quix_winapi.console.setCursorPosition(handle, coord);
}

pub fn moveToPreviousLine(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_PREV_LINE, .{amount});
    }

    const pos = try position();
    try moveTo(0, pos.row - amount);
}

pub fn moveToNextLine(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_NEXT_LINE, .{amount});
    }

    const pos = try position();
    try moveTo(0, pos.row + amount);
}

pub fn moveToColumn(column: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_TO_COLUMN, .{column});
    }

    const pos = try position();
    try moveTo(column, pos.row);
}

pub fn moveToRow(row: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_TO_ROW, .{row});
    }

    const pos = try position();
    try moveTo(pos.column, row);
}

pub fn moveUp(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_TOP, .{amount});
    }

    const pos = try position();
    try moveTo(pos.column, pos.row - amount);
}

pub fn moveRight(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_RIGHT, .{amount});
    }

    const pos = try position();
    try moveTo(pos.column + amount, pos.row);
}

pub fn moveDown(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_DOWN, .{amount});
    }

    const pos = try position();
    try moveTo(pos.column, pos.row + amount);
}

pub fn moveLeft(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_LEFT, .{amount});
    }

    const pos = try position();
    try moveTo(pos.column - amount, pos.row);
}

pub fn savePosition() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.esc(handle.writer(), ansi.CURSOR_SAVE_POSITION, .{});
    }

    const pos = try position();
    const upper = @as(u32, pos.x) << 16;
    const lower = @as(u32, pos.y);
    const bits = @as(u64, upper | lower);
    SAVED_CURSOR_POS.store(bits, .acq_rel);
}

pub fn restorePosition() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.esc(handle.writer(), ansi.CURSOR_RESTORE_POSITION, .{});
    }

    const stored_pos: u32 = @truncate(SAVED_CURSOR_POS.load(.acq_rel));
    const column = stored_pos >> 16;
    const row = stored_pos;
    try moveTo(column, row);
}

pub fn hide() !void {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    if (terminal.hasAnsiSupport()) {
        return ansi.csi(handle.writer(), ansi.CURSOR_HIDE, .{});
    }

    try setCursorVisibility(handle, false);
}

pub fn show() !void {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    if (terminal.hasAnsiSupport()) {
        return ansi.csi(handle.writer(), ansi.CURSOR_SHOW, .{});
    }

    try setCursorVisibility(handle, true);
}

fn setCursorVisibility(handle: quix_winapi.handle.Handle, visible: bool) !void {
    const cursor_info = quix_winapi.ConsoleCursorInfo.new(100, visible);
    quix_winapi.console.setCursorInfo(handle, cursor_info);
}

pub fn enableBlinking() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_ENABLE_BLINKING, .{});
    }

    // as far as I (wiru) know, there is no equivalent in legacy windows
    // terminals
}

pub fn disableBlinking() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_DISABLE_BLINKING, .{});
    }

    // as far as I (wiru) know, there is no equivalent in legacy windows
    // terminals
}

pub fn setCursorStyle(style: cursor.CursorStyle) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        switch (style) {
            .DefaultUserShape => return ansi.csi(handle.writer(), ansi.CURSOR_SHAPE_USER_DEFAULT, .{}),
            .BlinkingBlock => return ansi.csi(handle.writer(), ansi.CURSOR_SHAPE_BLINKING_BLOCK, .{}),
            .SteadyBlock => return ansi.csi(handle.writer(), ansi.CURSOR_SHAPE_STEADY_BLOCK, .{}),
            .BlinkingUnderScore => return ansi.csi(handle.writer(), ansi.CURSOR_SHAPE_BLINKING_UNDERSCORE, .{}),
            .SteadyUnderScore => return ansi.csi(handle.writer(), ansi.CURSOR_SHAPE_STEADY_UNDERSCORE, .{}),
            .BlinkingBar => return ansi.csi(handle.writer(), ansi.CURSOR_SHAPE_BLINKING_BAR, .{}),
            .SteadyBar => return ansi.csi(handle.writer(), ansi.CURSOR_SHAPE_STEADY_BAR, .{}),
        }
    }

    // as far as I (wiru) know, there is no equivalent in legacy windows
    // terminals
}
