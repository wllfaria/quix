const std = @import("std");
const windows = std.os.windows;
const HANDLE = windows.HANDLE;
const W = std.unicode.utf8ToUtf16LeStringLiteral;

const ConsoleError = @import("main.zig").ConsoleError;

pub const Handle = struct {
    inner: HANDLE,
    is_exclusive: bool,

    pub fn writer(self: *const @This()) std.io.AnyWriter {
        return std.io.AnyWriter{ .context = self, .writeFn = &writeAll };
    }
};

pub fn writeAll(context: *const anyopaque, bytes: []const u8) ConsoleError!usize {
    const self: *Handle = @constCast(@ptrCast(@alignCast(context)));

    var bytes_written: windows.DWORD = 0;
    const success = windows.kernel32.WriteFile(
        self.inner,
        bytes.ptr,
        @as(windows.DWORD, @intCast(bytes.len)),
        &bytes_written,
        null,
    );

    if (success == 0) return ConsoleError.FailedToWriteToHandle;
    if (bytes_written != bytes.len) return ConsoleError.FailedToWriteToHandle;
    return bytes_written;
}

fn makeExclusive(handle: HANDLE) Handle {
    return Handle{ .inner = handle, .is_exclusive = true };
}

fn makeShared(handle: HANDLE) Handle {
    return Handle{ .inner = handle, .is_exclusive = false };
}

fn createHandle(comptime name: []const u8) ConsoleError!HANDLE {
    const handle = windows.kernel32.CreateFileW(
        W(name),
        windows.GENERIC_READ | windows.GENERIC_WRITE,
        windows.FILE_SHARE_READ | windows.FILE_SHARE_WRITE,
        null,
        windows.OPEN_EXISTING,
        0,
        null,
    );

    if (handle == windows.INVALID_HANDLE_VALUE) {
        return ConsoleError.FailedToCreateHandle;
    }

    return handle;
}

pub fn getCurrentInHandle() ConsoleError!Handle {
    const conin = "CONIN$\x00";
    const handle = try createHandle(conin);
    return makeExclusive(handle);
}

pub fn getCurrentOutHandle() !Handle {
    const conout = "CONOUT$\x00";
    const handle = try createHandle(conout);
    return makeExclusive(handle);
}

pub fn close(handle: Handle) void {
    windows.CloseHandle(handle.inner);
}
