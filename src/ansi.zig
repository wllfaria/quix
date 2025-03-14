const std = @import("std");
const posix = std.posix;
const FileDesc = @import("file_desc.zig").FileDesc;

pub const SCROLL_UP_FMT: []const u8 = "{}S";
pub const SCROLL_DOWN_FMT: []const u8 = "{}T";

pub const CLEAR_CURSOR_DOWN_FMT: []const u8 = "J";
pub const CLEAR_CURSOR_UP_FMT: []const u8 = "1J";
pub const CLEAR_ALL_FMT: []const u8 = "2J";
pub const CLEAR_PURGE_FMT: []const u8 = "3J";
pub const CLEAR_UNTIL_NEWLINE_FMT: []const u8 = "K";
pub const CLEAR_CURRENT_LINE_FMT: []const u8 = "2K";

pub const ENTER_ALTERNATE_SCREEN_FMT: []const u8 = "?1049h";
pub const EXIT_ALTERNATE_SCREEN_FMT: []const u8 = "?1049l";

pub const MOUSE_NORMAL_TRACKING_ENABLE: []const u8 = "?1000h";
pub const MOUSE_BUTTON_EVENT_TRACKING_ENABLE: []const u8 = "?1002h";
pub const MOUSE_ANY_EVENT_TRACKING_ENABLE: []const u8 = "?1003h";
pub const MOUSE_RXVT_TRACKING_ENABLE: []const u8 = "?1015h";
pub const MOUSE_SGR_TRACKING_ENABLE: []const u8 = "?1006h";
pub const MOUSE_NORMAL_TRACKING_DISABLE: []const u8 = "?1000l";
pub const MOUSE_BUTTON_EVENT_TRACKING_DISABLE: []const u8 = "?1002l";
pub const MOUSE_ANY_EVENT_TRACKING_DISABLE: []const u8 = "?1003l";
pub const MOUSE_RXVT_TRACKING_DISABLE: []const u8 = "?1015l";
pub const MOUSE_SGR_TRACKING_DISABLE: []const u8 = "?1006l";

pub fn csi(writer: std.io.AnyWriter, comptime command: []const u8, args: anytype) !void {
    return esc(writer, "[" ++ command, args);
}

pub fn esc(writer: std.io.AnyWriter, comptime command: []const u8, args: anytype) !void {
    _ = try writer.print("\x1b" ++ command, args);
}
