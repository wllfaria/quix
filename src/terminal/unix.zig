const std = @import("std");
const posix = std.posix;

const ansi = @import("../ansi/ansi.zig");
const FileDesc = @import("../file_desc.zig").FileDesc;
const terminal = @import("terminal.zig");
const WindowSize = terminal.WindowSize;

var original_terminal_mode_mutex: std.Thread.Mutex = .{};
var original_terminal_mode: ?std.posix.termios = null;

var global_tty_fd_mutex: std.Thread.Mutex = .{};
var global_tty_fd: ?FileDesc = null;

pub fn hasAnsiSupport() bool {
    return true;
}

pub fn closeHandle() !void {
    global_tty_fd_mutex.lock();
    defer global_tty_fd_mutex.unlock();

    if (global_tty_fd) |handle| {
        if (handle.close_handle) posix.close(handle.handle);
    }
}

pub fn isRawModeEnabled() bool {
    original_terminal_mode_mutex.lock();
    defer original_terminal_mode_mutex.unlock();
    return original_terminal_mode != null;
}

pub fn enableRawMode() !void {
    original_terminal_mode_mutex.lock();
    defer original_terminal_mode_mutex.unlock();

    // we are already on raw mode
    if (original_terminal_mode != null) return;

    const fd = try getFd();
    const original_ios = try posix.tcgetattr(fd.handle);
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

    try posix.tcsetattr(fd.handle, .FLUSH, ios);
    // only set the original mode if we were able to switch
    original_terminal_mode = original_ios;
}

pub fn disableRawMode() !void {
    original_terminal_mode_mutex.lock();
    defer original_terminal_mode_mutex.unlock();

    if (original_terminal_mode) |original_mode_ios| {
        const fd = try getFd();
        try posix.tcsetattr(fd.handle, .FLUSH, original_mode_ios);
        // only reset the original mode if we were able to switch back
        original_terminal_mode = null;
    }
}

pub fn windowSize() !WindowSize {
    var window_size = posix.winsize{
        .row = 0,
        .col = 0,
        .xpixel = 0,
        .ypixel = 0,
    };

    const fd = try getFd();
    const result = posix.system.ioctl(
        fd.handle,
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

pub fn setSize(columns: u16, rows: u16) !void {
    const fd = try getFd();
    try ansi.csi(fd.writer(), ansi.SET_SIZE_FMT, .{ rows, columns });
}

// when getting the size of the terminal, we can either use the `windowSize`
// escape sequence, or fallback to using `tput`, if available.
pub fn size() !terminal.Size {
    const window_size = windowSize() catch return tputSize();

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

pub fn disableLineWrap() !void {
    const fd = try getFd();
    try ansi.csi(fd.writer(), ansi.DISABLE_LINE_WRAP_FMT, .{});
}

pub fn enableLineWrap() !void {
    const fd = try getFd();
    try ansi.csi(fd.writer(), ansi.ENABLE_LINE_WRAP_FMT, .{});
}

pub fn enterAlternateScreen() !void {
    const fd = try getFd();
    try ansi.csi(fd.writer(), ansi.ENTER_ALTERNATE_SCREEN_FMT, .{});
}

pub fn exitAlternateScreen() !void {
    const fd = try getFd();
    try ansi.csi(fd.writer(), ansi.EXIT_ALTERNATE_SCREEN_FMT, .{});
}

pub fn scrollUp(amount: u16) !void {
    if (amount != 0) {
        const fd = try getFd();
        try ansi.csi(fd.writer(), ansi.SCROLL_UP_FMT, .{amount});
    }
}

pub fn scrollDown(amount: u16) !void {
    if (amount != 0) {
        const fd = try getFd();
        try ansi.csi(fd.writer(), ansi.SCROLL_DOWN_FMT, .{amount});
    }
}

pub fn clear(clear_type: terminal.ClearType) !void {
    const fd = try getFd();
    switch (clear_type) {
        .All => try ansi.csi(fd.writer(), ansi.CLEAR_ALL_FMT, .{}),
        .Purge => try ansi.csi(fd.writer(), ansi.CLEAR_PURGE_FMT, .{}),
        .FromCursorDown => try ansi.csi(fd.writer(), ansi.CLEAR_CURSOR_DOWN_FMT, .{}),
        .FromCursorUp => try ansi.csi(fd.writer(), ansi.CLEAR_CURSOR_UP_FMT, .{}),
        .CurrentLine => try ansi.csi(fd.writer(), ansi.CLEAR_CURRENT_LINE_FMT, .{}),
        .UntilNewline => try ansi.csi(fd.writer(), ansi.CLEAR_UNTIL_NEWLINE_FMT, .{}),
    }
}

pub fn getFd() !FileDesc {
    global_tty_fd_mutex.lock();
    defer global_tty_fd_mutex.unlock();

    if (global_tty_fd) |fd| return fd;

    const is_tty = posix.isatty(posix.STDIN_FILENO);

    const fd = if (is_tty) blk: {
        break :blk FileDesc.init(posix.STDIN_FILENO);
    } else blk: {
        const fd = try posix.open("/dev/tty", .{ .ACCMODE = .RDWR }, 0);
        break :blk FileDesc{ .handle = fd, .close_handle = true };
    };

    global_tty_fd = fd;
    return fd;
}
