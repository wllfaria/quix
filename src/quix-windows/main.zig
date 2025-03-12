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
pub const ENABLE_VIRTUAL_TERMINAL_INPUT: DWORD  = 0x0200;
// zig fmt: on

pub const ConsoleError = error{
    FailedToRetrieveMode,
    FailedToSetMode,
    FailedToRetrieveInfo,
    FailedToCreateHandle,
    FailedToCreateScreenBuffer,
    FailedToShowScreenBuffer,
    FailedToWriteToHandle,
    FailedToSetWindowInfo,
    Unsupported,
};

pub const Size = struct {
    width: i16,
    height: i16,
};

pub const WindowPosition = struct {
    left: i16,
    right: i16,
    bottom: i16,
    top: i16,

    pub fn toSmallRect(self: @This()) windows.SMALL_RECT {
        return windows.SMALL_RECT{
            .Top = self.top,
            .Bottom = self.bottom,
            .Left = self.left,
            .Right = self.right,
        };
    }

    pub fn fromSmallRect(rect: windows.SMALL_RECT) @This() {
        return @This(){
            .left = rect.Left,
            .right = rect.Right,
            .bottom = rect.Bottom,
            .top = rect.Top,
        };
    }
};
