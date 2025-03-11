const std = @import("std");
const windows = std.os.windows;

const quix_winapi = @import("main.zig");

pub const Csbi = struct {
    csbi: windows.CONSOLE_SCREEN_BUFFER_INFO,

    pub fn terminalSize(self: @This()) quix_winapi.Size {
        return quix_winapi.Size{
            .width = self.csbi.srWindow.Right - self.csbi.srWindow.Left,
            .height = self.csbi.srWindow.Bottom - self.csbi.srWindow.Top,
        };
    }
};

pub fn init() Csbi {
    return std.mem.zeroInit(Csbi, .{});
}
