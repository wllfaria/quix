const std = @import("std");
const windows = std.os.windows;

pub extern "kernel32" fn CreateConsoleScreenBuffer(
    dwDesiredAccess: windows.DWORD,
    dwShareMode: windows.DWORD,
    lpSecurityAttributes: ?*const windows.SECURITY_ATTRIBUTES,
    dwFlags: windows.DWORD,
    lpScreenBufferData: ?*const anyopaque,
) callconv(windows.WINAPI) windows.HANDLE;

pub extern "kernel32" fn SetConsoleActiveScreenBuffer(
    hConsoleOutput: windows.HANDLE,
) callconv(windows.WINAPI) windows.BOOL;

pub extern "kernel32" fn SetConsoleWindowInfo(
    hConsoleOutput: windows.HANDLE,
    bAbsolute: windows.BOOL,
    small_rect: *const windows.SMALL_RECT,
) callconv(windows.WINAPI) windows.BOOL;
