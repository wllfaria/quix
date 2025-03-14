const quix_winapi = @import("quix_winapi");

const ansi = @import("../ansi/ansi.zig");
const terminal = @import("../terminal/windows.zig");

pub fn print(content: []const u8) !void {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const writer = handle.writer();
    _ = try writer.write(content);
}

pub fn printAnsi(comptime content: []const u8, args: anytype) !void {
    if (!terminal.hasAnsiSupport()) return;

    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const writer = handle.writer();
    try ansi.csi(writer, content, args);
}
