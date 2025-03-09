const std = @import("std");
const posix = std.posix;

const Terminal = @import("../terminal/unix.zig");

const Event = @import("event.zig").Event;

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
            .CSI => result = parseAnsiCsi(byte),
        }

        if (result.event) |event| {
            return event;
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
                    .event_kind = .Press,
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
                .event_kind = .Press,
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
                    .event_kind = .Press,
                } };
                return ParseResult{ .state = .Initial, .event = event };
            }
        },
        '\t' => {
            const event = Event{ .KeyEvent = .{
                .code = 0x09,
                .kind = .Tab,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .Initial, .event = event };
        },
        0x7F => {
            const event = Event{ .KeyEvent = .{
                .code = 0x7F,
                .kind = .Backspace,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .Initial, .event = event };
        },
        // Control + Enter yields a null byte
        0x00 => {
            const event = Event{ .KeyEvent = .{
                .code = 0x20,
                .kind = .Char,
                .mods = .{ .control = true },
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .Initial, .event = event };
        },
        else => {
            if (byte >= 0x01 and byte <= 0x1A) {
                const event = Event{ .KeyEvent = .{
                    .code = byte - 0x1 + 'a',
                    .kind = .Char,
                    .mods = .{ .control = true },
                    .event_kind = .Press,
                } };
                return ParseResult{ .state = .Initial, .event = event };
            } else if (byte >= 0x1C and byte <= 0x1F) {
                const event = Event{ .KeyEvent = .{
                    .code = byte - 0x1C + '4',
                    .kind = .Char,
                    .mods = .{ .control = true },
                    .event_kind = .Press,
                } };
                return ParseResult{ .state = .Initial, .event = event };
            }

            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Char,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .Initial, .event = event };
        },
    }

    unreachable;
}

fn parseAnsiEsc(byte: u8, idx: usize) ParseResult {
    if (idx == 1) {
        switch (byte) {
            'O' => return ParseResult{ .state = .ESC, .event = null },
            '[' => return ParseResult{ .state = .CSI, .event = null },
            0x1B => {
                const event = Event{ .KeyEvent = .{
                    .code = 0x1B,
                    .kind = .Esc,
                    .mods = .{},
                    .event_kind = .Press,
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
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        'C' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Right,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        'A' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Up,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        'B' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Down,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        'H' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Home,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        'F' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .End,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = event };
        },
        else => {
            // F1-F4
            // we cannot get other function keys, apparently
            if (byte >= 'P' and byte <= 'S') {
                const event = Event{ .KeyEvent = .{
                    .code = 1 + byte - 'P',
                    .kind = .End,
                    .mods = .{},
                    .event_kind = .Press,
                } };
                return ParseResult{ .state = .ESC, .event = event };
            }
            @panic("TODO");
        },
    }
}

fn parseAnsiCsi(byte: u8) ParseResult {
    switch (byte) {
        'D' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Left,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = event };
        },
        'C' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Right,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = event };
        },
        'A' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Up,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = event };
        },
        'B' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Down,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = event };
        },
        'H' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Home,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = event };
        },
        'F' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .End,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = event };
        },
        'Z' => {
            const event = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .BackTab,
                .mods = .{ .shift = true },
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = event };
        },

        'I' => {
            const event = Event.FocusGained;
            return ParseResult{ .state = .CSI, .event = event };
        },
        'O' => {
            const event = Event.FocusLost;
            return ParseResult{ .state = .CSI, .event = event };
        },
        else => @panic("TODO"),
    }
}
