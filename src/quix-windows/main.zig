const std = @import("std");
const windows = std.os.windows;
const DWORD = windows.DWORD;

pub const console = @import("console.zig");
pub const handle = @import("handle.zig");
pub const screen_buffer = @import("screen_buffer.zig");

// zig fmt: off
pub const ENABLE_LINE_INPUT: DWORD              = 0x0002;
pub const ENABLE_PROCESSED_INPUT: DWORD         = 0x0001;
pub const ENABLE_ECHO_INPUT: DWORD              = 0x0004;
pub const ENABLE_WRAP_AT_EOL_OUTPUT: DWORD      = 0x0002;
pub const CONSOLE_TEXTMODE_BUFFER: DWORD        = 0x0001;
// zig fmt: on

pub const ConsoleError = error{
    FailedToRetrieveMode,
    FailedToSetMode,
    FailedToRetrieveInfo,
    FailedToCreateHandle,
    FailedToCreateScreenBuffer,
    FailedToShowScreenBuffer,
    Unsupported,
};

pub const Size = struct {
    width: i16,
    height: i16,
};
