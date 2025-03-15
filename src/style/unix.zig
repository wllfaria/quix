const terminal = @import("../terminal/unix.zig");
const ansi = @import("../ansi/ansi.zig");

pub fn print(content: []const u8) !void {
    const fd = try terminal.getFd();
    const writer = fd.writer();
    _ = try writer.write(content);
}

pub fn printAnsi(comptime content: []const u8, args: anytype) !void {
    const fd = try terminal.getFd();
    const writer = fd.writer();
    try ansi.csi(writer, content, args);
}
