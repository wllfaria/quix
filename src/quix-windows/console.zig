const std = @import("std");
const windows = std.os.windows;
const csbi = @import("csbi.zig");
const quix_winapi = @import("main.zig");
const ffi = @import("ffi.zig");
const Handle = @import("handle.zig").Handle;
const ConsoleError = quix_winapi.ConsoleError;
const DWORD = windows.DWORD;

pub fn getMode(handle: Handle) ConsoleError!u32 {
    var console_mode: DWORD = 0;
    const result = windows.kernel32.GetConsoleMode(handle.inner, &console_mode);
    if (result == 0) return ConsoleError.FailedToRetrieveMode;
    return console_mode;
}

pub fn setMode(handle: Handle, new_mode: DWORD) ConsoleError!void {
    const result = windows.kernel32.SetConsoleMode(handle.inner, new_mode);
    if (result == 0) return ConsoleError.FailedToSetMode;
}

pub fn getInfo(handle: Handle) ConsoleError!csbi.Csbi {
    var screen_buf_info = csbi.init();
    const result = windows.kernel32.GetConsoleScreenBufferInfo(
        handle.inner,
        &screen_buf_info.csbi,
    );
    if (result == 0) return ConsoleError.FailedToRetrieveInfo;
    return screen_buf_info;
}

pub const WindowPlacement = enum {
    absolute,
    relative,
};

pub fn setInfo(
    handle: Handle,
    placement: WindowPlacement,
    rect: quix_winapi.WindowPosition,
) ConsoleError!void {
    const absolute: windows.BOOL = switch (placement) {
        .absolute => 1,
        .relative => 0,
    };
    const small_rect = rect.toSmallRect();
    const result = ffi.SetConsoleWindowInfo(handle.inner, absolute, &small_rect);
    if (result == 0) return ConsoleError.FailedToSetWindowInfo;
}
