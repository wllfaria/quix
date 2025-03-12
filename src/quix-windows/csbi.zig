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

    pub fn terminalWindow(self: @This()) quix_winapi.WindowPosition {
        const rect = self.csbi.srWindow;
        return quix_winapi.WindowPosition.fromSmallRect(rect);
    }

    pub fn bufferSize(self: @This()) quix_winapi.Size {
        return quix_winapi.Size{
            .width = self.csbi.dwSize.X,
            .height = self.csbi.dwSize.Y,
        };
    }
};

pub fn init() Csbi {
    return std.mem.zeroInit(Csbi, .{});
}
