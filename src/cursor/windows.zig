const std = @import("std");

const quix_winapi = @import("quix_winapi");

const ansi = @import("../ansi/ansi.zig");
const terminal = @import("../terminal/windows.zig");
const cursor = @import("cursor.zig");

pub fn moveTo(column: u16, row: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_TO, .{ row + 1, column + 1 });
    }
}

pub fn moveToPreviousLine(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_PREV_LINE, .{amount});
    }
}

pub fn moveToNextLine(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_NEXT_LINE, .{amount});
    }
}

pub fn moveToColumn(column: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_TO_COLUMN, .{column});
    }
}

pub fn moveToRow(row: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_TO_ROW, .{row});
    }
}

pub fn moveTop(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_TOP, .{amount});
    }
}

pub fn moveRight(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_RIGHT, .{amount});
    }
}

pub fn moveDown(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_DOWN, .{amount});
    }
}

pub fn moveLeft(amount: u16) !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_MOVE_LEFT, .{amount});
    }
}

pub fn savePosition() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.esc(handle.writer(), ansi.CURSOR_SAVE_POSITION, .{});
    }
}

pub fn restorePosition() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.esc(handle.writer(), ansi.CURSOR_RESTORE_POSITION, .{});
    }
}

pub fn hide() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_HIDE, .{});
    }
}

pub fn show() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_SHOW, .{});
    }
}

pub fn enableBlinking() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_ENABLE_BLINKING, .{});
    }
}

pub fn disableBlinking() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        return ansi.csi(handle.writer(), ansi.CURSOR_DISABLE_BLINKING, .{});
    }
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
}
