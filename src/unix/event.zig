const std = @import("std");
const posix = std.posix;

const Terminal = @import("terminal.zig");

const Event = @import("../event.zig").Event;

const IO_BUFFER_SIZE: usize = 1024;

const ParseState = enum {
    Initial,
    ESC,
    CSI,
};

const ParseResult = struct {
    state: ParseState,
    event: ?Event,
};

pub fn read(fd: posix.fd_t) !Event {
    var buf: [IO_BUFFER_SIZE]u8 = .{0} ** IO_BUFFER_SIZE;

    while (true) {
        const bytes_read = try posix.read(fd, &buf);
        if (bytes_read > 0) {
            return parseAnsi(buf[0..bytes_read]);
        }
    }
}

fn parseAnsi(buf: []const u8) Event {
    std.debug.assert(buf.len > 0);

    var result = ParseResult{ .state = .Initial, .event = null };

    for (buf, 0..) |byte, idx| {
        switch (result.state) {
            .Initial => result = parseAnsiInitial(byte, buf.len),
            .ESC => result = parseAnsiEsc(byte, idx),
            .CSI => @panic("TODO"),
        }

        if (result.event != null) {
            return result.event.?;
        }
    }

    unreachable;
}

fn parseAnsiInitial(byte: u8, len: usize) ParseResult {
    switch (byte) {
        0x1B => {
            if (len == 1) {
                const event = Event{ .KeyEvent = .{
                    .code = 0x1B,
                    .kind = .Esc,
                    .mods = .{},
                } };
                return ParseResult{ .state = .ESC, .event = event };
            }
            return ParseResult{ .state = .ESC, .event = null };
        },
        // Carriage Return (CR)
        '\r' => {
            const event = Event{ .KeyEvent = .{
                .code = 0x0D,
                .kind = .Enter,
                .mods = .{},
            } };
            return ParseResult{ .state = .Initial, .event = event };
        },
        // Newline (Line Feed)
        '\n' => {
            if (!Terminal.isRawModeEnabled()) {
                const event = Event{ .KeyEvent = .{
                    .code = 0x0A,
                    .kind = .Enter,
                    .mods = .{},
                } };
                return ParseResult{ .state = .Initial, .event = event };
            }
        },
        '\t' => {
            const event = Event{ .KeyEvent = .{
                .code = 0x09,
                .kind = .Tab,
                .mods = .{},
            } };
            return ParseResult{ .state = .Initial, .event = event };
        },
        0x7F => {
            const event = Event{ .KeyEvent = .{
                .code = 0x7F,
                .kind = .Backspace,
                .mods = .{},
            } };
            return ParseResult{ .state = .Initial, .event = event };
        },
        // Control + Enter yields a null byte
        0x00 => {
            const event = Event{ .KeyEvent = .{
                .code = 0x20,
                .kind = .Char,
                .mods = .{ .control = true },
            } };
            return ParseResult{ .state = .Initial, .event = event };
        },
        else => {
            if (byte >= 0x01 and byte <= 0x1A) {
                const event = Event{ .KeyEvent = .{
                    .code = byte - 0x1 + 'a',
                    .kind = .Char,
                    .mods = .{ .control = true },
                } };
                return ParseResult{ .state = .Initial, .event = event };
            } else if (byte >= 0x1C and byte <= 0x1F) {
                const event = Event{ .KeyEvent = .{
                    .code = byte - 0x1C + '4',
                    .kind = .Char,
                    .mods = .{ .control = true },
                } };
                return ParseResult{ .state = .Initial, .event = event };
            }

            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Char,
                .mods = .{},
            } };
            return ParseResult{ .state = .Initial, .event = event };
        },
    }

    unreachable;
}

fn parseAnsiEsc(byte: u8, idx: usize) ParseResult {
    std.debug.print("parsing ansi ESCAPE byte {d}", .{byte});
    if (idx == 1) {
        switch (byte) {
            'O' => return ParseResult{ .state = .ESC, .event = null },
            '[' => return ParseResult{ .state = .CSI, .event = null },
            0x1B => {
                const event = Event{ .KeyEvent = .{
                    .code = 0x1B,
                    .kind = .Esc,
                    .mods = .{},
                } };
                return ParseResult{ .state = .ESC, .event = event };
            },
            // I (wiru) am not sure if anything else can actually happen here
            else => @panic("TODO"),
        }
    }

    switch (byte) {
        'D' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Left,
                .mods = .{},
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        'C' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Right,
                .mods = .{},
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        'A' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Up,
                .mods = .{},
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        'B' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Down,
                .mods = .{},
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        'H' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Home,
                .mods = .{},
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        'F' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .End,
                .mods = .{},
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        else => {
            if (byte >= 'P' and byte <= 'S') {
                const event = Event{ .KeyEvent = .{
                    .code = 1 + byte - 'P',
                    .kind = .End,
                    .mods = .{},
                } };
                return ParseResult{ .state = .ESC, .event = event };
            }
            @panic("TODO");
        },
    }
}
