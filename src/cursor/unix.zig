const std = @import("std");
const posix = std.posix;

const ansi = @import("../ansi.zig");
const cursor = @import("cursor.zig");
const terminal = @import("../terminal/terminal.zig");
const unix_terminal = @import("../terminal/unix.zig");
const FileDesc = @import("../file_desc.zig");

pub fn moveTo(column: u16, row: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "{};{}H", .{ row + 1, column + 1 });
}

pub fn moveToPreviousLine(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "{}F", .{amount});
}

pub fn moveToNextLine(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "{}E", .{amount});
}

pub fn moveToColumn(column: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "{}G", .{column});
}

pub fn moveToRow(row: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "{}d", .{row});
}

pub fn moveTop(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "{}A", .{amount});
}

pub fn moveRight(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "{}C", .{amount});
}

pub fn moveDown(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "{}B", .{amount});
}

pub fn moveLeft(amount: u16) !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "{}D", .{amount});
}

pub fn savePosition() !void {
    const fd = try unix_terminal.getFd();
    return ansi.esc(fd.writer(), "7", .{});
}

pub fn restorePosition() !void {
    const fd = try unix_terminal.getFd();
    return ansi.esc(fd.writer(), "8", .{});
}

pub fn hide() !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "?25l", .{});
}

pub fn show() !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "?25h", .{});
}

pub fn enableBlinking() !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "?12h", .{});
}

pub fn disableBlinking() !void {
    const fd = try unix_terminal.getFd();
    return ansi.csi(fd.writer(), "?12l", .{});
}

pub fn setCursorStyle(style: cursor.CursorStyle) !void {
    const fd = try unix_terminal.getFd();
    switch (style) {
        .DefaultUserShape => return ansi.csi(fd.writer(), "0 q", .{}),
        .BlinkingBlock => return ansi.csi(fd.writer(), "1 q", .{}),
        .SteadyBlock => return ansi.csi(fd.writer(), "2 q", .{}),
        .BlinkingUnderScore => return ansi.csi(fd.writer(), "3 q", .{}),
        .SteadyUnderScore => return ansi.csi(fd.writer(), "4 q", .{}),
        .BlinkingBar => return ansi.csi(fd.writer(), "5 q", .{}),
        .SteadyBar => return ansi.csi(fd.writer(), "6 q", .{}),
    }
}
