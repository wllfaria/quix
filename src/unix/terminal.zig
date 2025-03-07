const std = @import("std");
const posix = std.posix;

var original_terminal_mode_mutex: std.Thread.Mutex = .{};
var original_terminal_mode: ?std.posix.termios = null;

pub const WindowSize = struct {
    rows: u16,
    cols: u16,
    width: u16,
    height: u16,
};

const FileDesc = struct {
    fd: posix.fd_t,

    pub fn init(fd: posix.fd_t) @This() {
        return @This(){ .fd = fd };
    }
};

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

fn writeCsi(ptr: *const anyopaque, bytes: []const u8) !usize {
    const handle: *const FileDesc = @ptrCast(@alignCast(ptr));
    return posix.write(handle.fd, bytes);
}

fn csi(handle: FileDesc, comptime command: []const u8, args: anytype) !void {
    const writer = std.io.AnyWriter{ .context = &handle, .writeFn = writeCsi };
    _ = try writer.print("\x1b[" ++ command, args);
}

pub fn disableLineWrap(fd: posix.fd_t) !void {
    const handle = FileDesc.init(fd);
    try csi(handle, "?7l", .{});
}

pub fn enableLineWrap(fd: posix.fd_t) !void {
    const handle = FileDesc.init(fd);
    try csi(handle, "?7h", .{});
}

pub fn enterAlternateScreen(fd: posix.fd_t) !void {
    const handle = FileDesc.init(fd);
    try csi(handle, "?1049h", .{});
}

pub fn exitAlternateScreen(fd: posix.fd_t) !void {
    const handle = FileDesc.init(fd);
    try csi(handle, "?1049l", .{});
}

pub fn scrollUp(fd: posix.fd_t, amount: u16) !void {
    if (amount != 0) {
        const handle = FileDesc.init(fd);
        try csi(handle, "{}S", .{amount});
    }
}

pub fn scrollDown(fd: posix.fd_t, amount: u16) !void {
    if (amount != 0) {
        const handle = FileDesc.init(fd);
        try csi(handle, "{}T", .{amount});
    }
}
