const std = @import("std");
const posix = std.posix;

const ansi = @import("../ansi.zig");
const cursor = @import("cursor.zig");
const terminal = @import("../terminal/terminal.zig");
const unix_terminal = @import("../terminal/unix.zig");

pub fn moveTo(fd: posix.fd_t, column: u16, row: u16) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "{};{}H", .{ row + 1, column + 1 });
}

pub fn moveToPreviousLine(fd: posix.fd_t, amount: u16) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "{}F", .{amount});
}

pub fn moveToNextLine(fd: posix.fd_t, amount: u16) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "{}E", .{amount});
}

pub fn moveToColumn(fd: posix.fd_t, column: u16) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "{}G", .{column});
}

pub fn moveToRow(fd: posix.fd_t, row: u16) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "{}d", .{row});
}

pub fn moveTop(fd: posix.fd_t, amount: u16) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "{}A", .{amount});
}

pub fn moveRight(fd: posix.fd_t, amount: u16) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "{}C", .{amount});
}

pub fn moveDown(fd: posix.fd_t, amount: u16) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "{}B", .{amount});
}

pub fn moveLeft(fd: posix.fd_t, amount: u16) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "{}D", .{amount});
}

pub fn savePosition(fd: posix.fd_t) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.esc(handle, "7", .{});
}

pub fn restorePosition(fd: posix.fd_t) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.esc(handle, "8", .{});
}

pub fn hide(fd: posix.fd_t) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "?25l", .{});
}

pub fn show(fd: posix.fd_t) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "?25h", .{});
}

pub fn enableBlinking(fd: posix.fd_t) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "?12h", .{});
}

pub fn disableBlinking(fd: posix.fd_t) !void {
    const handle = ansi.FileDesc.init(fd);
    return ansi.csi(handle, "?12l", .{});
}

pub fn setCursorStyle(fd: posix.fd_t, style: cursor.CursorStyle) !void {
    const handle = ansi.FileDesc.init(fd);
    switch (style) {
        .DefaultUserShape => return ansi.csi(handle, "0 q", .{}),
        .BlinkingBlock => return ansi.csi(handle, "1 q", .{}),
        .SteadyBlock => return ansi.csi(handle, "2 q", .{}),
        .BlinkingUnderScore => return ansi.csi(handle, "3 q", .{}),
        .SteadyUnderScore => return ansi.csi(handle, "4 q", .{}),
        .BlinkingBar => return ansi.csi(handle, "5 q", .{}),
        .SteadyBar => return ansi.csi(handle, "6 q", .{}),
    }
}
