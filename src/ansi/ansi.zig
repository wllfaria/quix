const std = @import("std");
const posix = std.posix;

const FileDesc = @import("../file_desc.zig").FileDesc;
pub const parser = @import("parser.zig");
pub const IO_BUFFER_SIZE = parser.IO_BUFFER_SIZE;

// zig fmt: off
pub const SCROLL_UP_FMT: []const u8                         = "{}S";
pub const SCROLL_DOWN_FMT: []const u8                       = "{}T";

pub const CLEAR_CURSOR_DOWN_FMT: []const u8                 = "J";
pub const CLEAR_CURSOR_UP_FMT: []const u8                   = "1J";
pub const CLEAR_ALL_FMT: []const u8                         = "2J";
pub const CLEAR_PURGE_FMT: []const u8                       = "3J";
pub const CLEAR_UNTIL_NEWLINE_FMT: []const u8               = "K";
pub const CLEAR_CURRENT_LINE_FMT: []const u8                = "2K";

pub const ENTER_ALTERNATE_SCREEN_FMT: []const u8            = "?1049h";
pub const EXIT_ALTERNATE_SCREEN_FMT: []const u8             = "?1049l";

pub const SET_SIZE_FMT: []const u8                          = "8;{};{}t";

pub const MOUSE_NORMAL_TRACKING_ENABLE: []const u8          = "?1000h";
pub const MOUSE_BUTTON_EVENT_TRACKING_ENABLE: []const u8    = "?1002h";
pub const MOUSE_ANY_EVENT_TRACKING_ENABLE: []const u8       = "?1003h";
pub const MOUSE_RXVT_TRACKING_ENABLE: []const u8            = "?1015h";
pub const MOUSE_SGR_TRACKING_ENABLE: []const u8             = "?1006h";
pub const MOUSE_NORMAL_TRACKING_DISABLE: []const u8         = "?1000l";
pub const MOUSE_BUTTON_EVENT_TRACKING_DISABLE: []const u8   = "?1002l";
pub const MOUSE_ANY_EVENT_TRACKING_DISABLE: []const u8      = "?1003l";
pub const MOUSE_RXVT_TRACKING_DISABLE: []const u8           = "?1015l";
pub const MOUSE_SGR_TRACKING_DISABLE: []const u8            = "?1006l";

pub const CURSOR_MOVE_TO: []const u8                        = "{};{}H";
pub const CURSOR_MOVE_PREV_LINE: []const u8                 = "{}F";
pub const CURSOR_MOVE_NEXT_LINE: []const u8                 = "{}E";
pub const CURSOR_MOVE_TO_COLUMN: []const u8                 = "{}G";
pub const CURSOR_MOVE_TO_ROW: []const u8                    = "{}d";
pub const CURSOR_MOVE_TOP: []const u8                       = "{}A";
pub const CURSOR_MOVE_RIGHT: []const u8                     = "{}C";
pub const CURSOR_MOVE_DOWN: []const u8                      = "{}B";
pub const CURSOR_MOVE_LEFT: []const u8                      = "{}D";
pub const CURSOR_SAVE_POSITION: []const u8                  = "7";
pub const CURSOR_RESTORE_POSITION: []const u8               = "8";
pub const CURSOR_HIDE: []const u8                           = "?25l";
pub const CURSOR_SHOW: []const u8                           = "?25h";
pub const CURSOR_ENABLE_BLINKING: []const u8                = "?12h";
pub const CURSOR_DISABLE_BLINKING: []const u8               = "?12l";
pub const CURSOR_SHAPE_USER_DEFAULT: []const u8             = "0 q";
pub const CURSOR_SHAPE_BLINKING_BLOCK: []const u8           = "1 q";
pub const CURSOR_SHAPE_STEADY_BLOCK: []const u8             = "2 q";
pub const CURSOR_SHAPE_BLINKING_UNDERSCORE: []const u8      = "3 q";
pub const CURSOR_SHAPE_STEADY_UNDERSCORE: []const u8        = "4 q";
pub const CURSOR_SHAPE_BLINKING_BAR: []const u8             = "5 q";
pub const CURSOR_SHAPE_STEADY_BAR: []const u8               = "6 q";
// zig fmt: on

pub fn csi(writer: std.io.AnyWriter, comptime command: []const u8, args: anytype) !void {
    return esc(writer, "[" ++ command, args);
}

pub fn esc(writer: std.io.AnyWriter, comptime command: []const u8, args: anytype) !void {
    _ = try writer.print("\x1b" ++ command, args);
}

pub fn enableMouse(writer: std.io.AnyWriter) !void {
    // Normal tracking: Send mouse X & Y on button press and release
    try csi(writer, MOUSE_NORMAL_TRACKING_ENABLE, .{});
    // Button-event tracking: Report button motion events (dragging)
    try csi(writer, MOUSE_BUTTON_EVENT_TRACKING_ENABLE, .{});
    // Any-event tracking: Report all motion events
    try csi(writer, MOUSE_ANY_EVENT_TRACKING_ENABLE, .{});
    // RXVT mouse mode: Allows mouse coordinates of >223
    try csi(writer, MOUSE_RXVT_TRACKING_ENABLE, .{});
    // SGR mouse mode: Allows mouse coordinates of >223, preferred over RXVT mode
    try csi(writer, MOUSE_SGR_TRACKING_ENABLE, .{});
}

pub fn disableMouse(writer: std.io.AnyWriter) !void {
    // The inverse commands of EnableMouseCapture, in reverse order.
    try csi(writer, MOUSE_SGR_TRACKING_DISABLE, .{});
    try csi(writer, MOUSE_RXVT_TRACKING_DISABLE, .{});
    try csi(writer, MOUSE_ANY_EVENT_TRACKING_DISABLE, .{});
    try csi(writer, MOUSE_BUTTON_EVENT_TRACKING_DISABLE, .{});
    try csi(writer, MOUSE_NORMAL_TRACKING_DISABLE, .{});
}
