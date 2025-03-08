const std = @import("std");
const posix = std.posix;

const ansi = @import("../ansi.zig");
const terminal = @import("terminal.zig");
const WindowSize = terminal.WindowSize;

var original_terminal_mode_mutex: std.Thread.Mutex = .{};
var original_terminal_mode: ?std.posix.termios = null;

pub fn isRawModeEnabled() bool {
    original_terminal_mode_mutex.lock();
    defer original_terminal_mode_mutex.unlock();
    return original_terminal_mode != null;
}

pub fn enableRawMode(fd: posix.fd_t) !void {
    original_terminal_mode_mutex.lock();
    defer original_terminal_mode_mutex.unlock();

    // we are already on raw mode
    if (original_terminal_mode != null) {
        return;
    }

    const original_ios = try posix.tcgetattr(fd);
    var ios = original_ios;

    // see termios(3) man page
    ios.oflag.OPOST = false;

    ios.iflag.IGNBRK = false;
    ios.iflag.BRKINT = false;
    ios.iflag.PARMRK = false;
    ios.iflag.ISTRIP = false;
    ios.iflag.INLCR = false;
    ios.iflag.IGNCR = false;
    ios.iflag.ICRNL = false;
    ios.iflag.IXON = false;

    ios.lflag.ECHO = false;
    ios.lflag.ECHONL = false;
    ios.lflag.ICANON = false;
    ios.lflag.ISIG = false;
    ios.lflag.IEXTEN = false;

    ios.cflag.CSIZE = .CS8;
    ios.cflag.PARENB = false;

    try posix.tcsetattr(fd, .FLUSH, ios);
    // only set the original mode if we were able to switch
    original_terminal_mode = original_ios;
}

pub fn disableRawMode(fd: posix.fd_t) !void {
    original_terminal_mode_mutex.lock();
    defer original_terminal_mode_mutex.unlock();

    if (original_terminal_mode) |original_mode_ios| {
        try posix.tcsetattr(fd, .FLUSH, original_mode_ios);
        // only reset the original mode if we were able to switch back
        original_terminal_mode = null;
    }
}

pub fn windowSize(fd: posix.fd_t) !WindowSize {
    var window_size = posix.winsize{
        .row = 0,
        .col = 0,
        .xpixel = 0,
        .ypixel = 0,
    };

    const result = posix.system.ioctl(
        fd,
        posix.T.IOCGWINSZ,
        @intFromPtr(&window_size),
    );

    if (posix.errno(result) == .SUCCESS) {
        return WindowSize{
            .rows = window_size.row,
            .cols = window_size.col,
            .width = window_size.xpixel,
            .height = window_size.ypixel,
        };
    }

    return error.IoctlError;
}

pub fn setSize(fd: posix.fd_t, columns: u16, rows: u16) !void {
    const handle = ansi.FileDesc.init(fd);
    try ansi.csi(handle, "8;{};{}t", .{ rows, columns });
}

// when getting the size of the terminal, we can either use the `windowSize`
// escape sequence, or fallback to using `tput`, if available.
pub fn size(fd: posix.fd_t) !terminal.Size {
    const window_size = windowSize(fd) catch {
        return tputSize();
    };

    return .{
        .cols = window_size.cols,
        .rows = window_size.rows,
    };
}

pub fn tputSize() !terminal.Size {
    const cols = try tputValue("cols");
    const lines = try tputValue("lines");

    return .{
        .cols = cols,
        .rows = lines,
    };
}

pub fn tputValue(arg: []const u8) !u16 {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    var child = std.process.Child.init(&[_][]const u8{ "tput", arg }, gpa);

    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    var stdout = std.ArrayListUnmanaged(u8){};
    var stderr = std.ArrayListUnmanaged(u8){};
    defer stdout.deinit(gpa);
    defer stderr.deinit(gpa);

    try child.spawn();
    try child.collectOutput(gpa, &stdout, &stderr, 1024);

    const res = try child.wait();

    if (res.Exited > 0) return error.FailedToGetWindowSize;

    var result: u16 = 0;
    for (stdout.items) |item| {
        const value = std.fmt.parseInt(u8, &[_]u8{item}, 10) catch continue;
        result = result * 10 + @as(u16, value);
    }

    return result;
}

pub fn disableLineWrap(fd: posix.fd_t) !void {
    const handle = ansi.FileDesc.init(fd);
    try ansi.csi(handle, "?7l", .{});
}

pub fn enableLineWrap(fd: posix.fd_t) !void {
    const handle = ansi.FileDesc.init(fd);
    try ansi.csi(handle, "?7h", .{});
}

pub fn enterAlternateScreen(fd: posix.fd_t) !void {
    const handle = ansi.FileDesc.init(fd);
    try ansi.csi(handle, "?1049h", .{});
}

pub fn exitAlternateScreen(fd: posix.fd_t) !void {
    const handle = ansi.FileDesc.init(fd);
    try ansi.csi(handle, "?1049l", .{});
}

pub fn scrollUp(fd: posix.fd_t, amount: u16) !void {
    if (amount != 0) {
        const handle = ansi.FileDesc.init(fd);
        try ansi.csi(handle, "{}S", .{amount});
    }
}

pub fn scrollDown(fd: posix.fd_t, amount: u16) !void {
    if (amount != 0) {
        const handle = ansi.FileDesc.init(fd);
        try ansi.csi(handle, "{}T", .{amount});
    }
}

pub fn clear(fd: posix.fd_t, clear_type: terminal.ClearType) !void {
    const handle = ansi.FileDesc.init(fd);
    switch (clear_type) {
        .All => try ansi.csi(handle, "2J", .{}),
        .Purge => try ansi.csi(handle, "3J", .{}),
        .FromCursorDown => try ansi.csi(handle, "J", .{}),
        .FromCursorUp => try ansi.csi(handle, "1J", .{}),
        .CurrentLine => try ansi.csi(handle, "2K", .{}),
        .UntilNewline => try ansi.csi(handle, "K", .{}),
    }
}
