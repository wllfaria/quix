const std = @import("std");

const event = @import("../event/event.zig");
const Event = event.Event;
const terminal = @import("../terminal/terminal.zig");

pub const IO_BUFFER_SIZE: usize = 1024;

const ParseState = enum {
    Initial,
    ESC,
    CSI,
    MouseNormal,
    MouseExtended,
};

const ParseResult = struct {
    state: ParseState,
    event: ?Event,
};

pub fn parseAnsi(buf: []const u8) !Event {
    std.debug.assert(buf.len > 0);

    var result = ParseResult{ .state = .Initial, .event = null };

    for (buf, 0..) |byte, idx| {
        switch (result.state) {
            .Initial => result = try parseAnsiInitial(byte, buf.len),
            .ESC => result = parseAnsiEsc(byte, idx),
            .CSI => result = parseAnsiCsi(byte),
            .MouseNormal => result = try parseAnsiMouseNormal(buf),
            .MouseExtended => result = try parseAnsiMouseExtended(buf),
        }

        if (result.event) |ev| {
            return ev;
        }
    }

    unreachable;
}

fn parseAnsiInitial(byte: u8, len: usize) !ParseResult {
    switch (byte) {
        0x1B => {
            if (len == 1) {
                const ev = Event{ .KeyEvent = .{
                    .code = 0x1B,
                    .kind = .Esc,
                    .mods = .{},
                    .event_kind = .Press,
                } };
                return ParseResult{ .state = .ESC, .event = ev };
            }
            return ParseResult{ .state = .ESC, .event = null };
        },
        // Carriage Return (CR)
        '\r' => {
            const ev = Event{ .KeyEvent = .{
                .code = 0x0D,
                .kind = .Enter,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .Initial, .event = ev };
        },
        // Newline (Line Feed)
        '\n' => {
            if (!try terminal.isRawModeEnabled()) {
                const ev = Event{ .KeyEvent = .{
                    .code = 0x0A,
                    .kind = .Enter,
                    .mods = .{},
                    .event_kind = .Press,
                } };
                return ParseResult{ .state = .Initial, .event = ev };
            }
        },
        '\t' => {
            const ev = Event{ .KeyEvent = .{
                .code = 0x09,
                .kind = .Tab,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .Initial, .event = ev };
        },
        0x7F => {
            const ev = Event{ .KeyEvent = .{
                .code = 0x7F,
                .kind = .Backspace,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .Initial, .event = ev };
        },
        // Control + Enter yields a null byte
        0x00 => {
            const ev = Event{ .KeyEvent = .{
                .code = 0x20,
                .kind = .Char,
                .mods = .{ .control = true },
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .Initial, .event = ev };
        },
        else => {
            if (byte >= 0x01 and byte <= 0x1A) {
                const ev = Event{ .KeyEvent = .{
                    .code = byte - 0x1 + 'a',
                    .kind = .Char,
                    .mods = .{ .control = true },
                    .event_kind = .Press,
                } };
                return ParseResult{ .state = .Initial, .event = ev };
            } else if (byte >= 0x1C and byte <= 0x1F) {
                const ev = Event{ .KeyEvent = .{
                    .code = byte - 0x1C + '4',
                    .kind = .Char,
                    .mods = .{ .control = true },
                    .event_kind = .Press,
                } };
                return ParseResult{ .state = .Initial, .event = ev };
            }

            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Char,
                .mods = .{},
                .event_kind = .Press,
            } };

            return ParseResult{ .state = .Initial, .event = ev };
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
                const ev = Event{ .KeyEvent = .{
                    .code = 0x1B,
                    .kind = .Esc,
                    .mods = .{},
                    .event_kind = .Press,
                } };
                return ParseResult{ .state = .ESC, .event = ev };
            },
            // I (wiru) am not sure if anything else can actually happen here
            else => @panic("TODO"),
        }
    }

    switch (byte) {
        'D' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Left,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = ev };
        },
        'C' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Right,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = ev };
        },
        'A' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Up,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = ev };
        },
        'B' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Down,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = ev };
        },
        'H' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Home,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = ev };
        },
        'F' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .End,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .ESC, .event = ev };
        },
        else => {
            // F1-F4
            // we cannot get other function keys, apparently
            if (byte >= 'P' and byte <= 'S') {
                const ev = Event{ .KeyEvent = .{
                    .code = 1 + byte - 'P',
                    .kind = .End,
                    .mods = .{},
                    .event_kind = .Press,
                } };
                return ParseResult{ .state = .ESC, .event = ev };
            }
            @panic("TODO");
        },
    }
}

fn parseAnsiCsi(byte: u8) ParseResult {
    switch (byte) {
        'D' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Left,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = ev };
        },
        'C' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Right,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = ev };
        },
        'A' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Up,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = ev };
        },
        'B' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Down,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = ev };
        },
        'H' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .Home,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = ev };
        },
        'F' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .End,
                .mods = .{},
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = ev };
        },
        'Z' => {
            const ev = Event{ .KeyEvent = .{
                .code = byte,
                .kind = .BackTab,
                .mods = .{ .shift = true },
                .event_kind = .Press,
            } };
            return ParseResult{ .state = .CSI, .event = ev };
        },
        '<' => return ParseResult{ .state = .MouseExtended, .event = null },
        'M' => return ParseResult{ .state = .MouseNormal, .event = null },
        'I' => {
            const ev = Event.FocusGained;
            return ParseResult{ .state = .CSI, .event = ev };
        },
        'O' => {
            const ev = Event.FocusLost;
            return ParseResult{ .state = .CSI, .event = ev };
        },
        else => {
            std.debug.print("did not work for byte {X:02}\n", .{byte});
            @panic("TODO");
        },
    }
}

/// Parses an ansi normal mouse event, enabled by setting the `ESC[?1000h` flag.
///
/// Events are received as `ESC [ M CB CX CY` where:
///
/// CB is the byte used to describe which button was pressed, the modifiers that
/// were active and whether the mouse was dragging or not.
///
/// # CB bit layout
///
/// | Bit | Name              |
/// |-----|-------------------|
/// |  0  | button number     |
/// |  1  | button number     |
/// |  2  | shift             |
/// |  3  | meta (alt)        |
/// |  4  | control           |
/// |  5  | mouse is dragging |
/// |  6  | button number     |
/// |  7  | button number     |
///
/// See page 47 of <https://invisible-island.net/xterm/ctlseqs/ctlseqs.pdf>
fn parseAnsiMouseNormal(buf: []const u8) !ParseResult {
    std.debug.assert(std.mem.eql(u8, buf[0..3], "\x1B[M"));
    if (buf.len < 6) return error.CouldNotParseEventError;

    const unparsed_cb = std.math.sub(u8, buf[3], 32) catch return error.CouldNotParseEventError;
    const cb = try parseCb(unparsed_cb);

    // values on this escape sequence have 32 added to them, remove it here
    const cx = @as(u16, std.math.sub(u8, buf[4], 32) catch 0) - 1;
    const cy = @as(u16, std.math.sub(u8, buf[5], 32) catch 0) - 1;

    const ev = Event{ .MouseEvent = .{
        .kind = cb.kind,
        .mods = cb.mods,
        .column = cx,
        .row = cy,
    } };

    return ParseResult{
        .state = .MouseNormal,
        .event = ev,
    };
}

fn nextParsed(
    comptime T: type,
    iter: *std.mem.SplitIterator(u8, .sequence),
) !T {
    const next = iter.next() orelse return error.CouldNotParseEventError;
    return std.fmt.parseInt(T, next, 10) catch error.CouldNotParseEventError;
}

// fn logToFile(text: []const u8) void {
//     const file = std.fs.cwd().openFile("log.log", .{ .mode = .read_write }) catch unreachable;
//     file.seekFromEnd(0) catch unreachable;
//     const writer = file.writer();
//     writer.print("{X:02}\n", .{text}) catch unreachable;
// }

/// Parses an ansi sgr mouse event, enabled by setting the `ESC[?1006h` flag.
///
/// Events are received as `ESC [ < CB ; CX ; CY (;) (M or m)` where:
/// - M is for button press
/// - m is for button release
///
/// CB is the byte used to describe which button was pressed, the modifiers that
/// were active and whether the mouse was dragging or not.
///
/// # CB bit layout
///
/// | Bit | Name              |
/// |-----|-------------------|
/// |  0  | button number     |
/// |  1  | button number     |
/// |  2  | shift             |
/// |  3  | meta (alt)        |
/// |  4  | control           |
/// |  5  | mouse is dragging |
/// |  6  | button number     |
/// |  7  | button number     |
///
///
/// See page 49 of <https://invisible-island.net/xterm/ctlseqs/ctlseqs.pdf>
fn parseAnsiMouseExtended(buf: []const u8) !ParseResult {
    std.debug.assert(std.mem.eql(u8, buf[0..3], "\x1B[<"));
    std.debug.assert(std.mem.endsWith(u8, buf, "M") or std.mem.endsWith(u8, buf, "m"));

    // the last semicolon is not mandatory, therefore it isn't reliable to count
    // on splitting the last character (m or M) here. This is why the last
    // character is ignored on the split, to ensure only actual digits are
    // parsed
    var split = std.mem.splitSequence(u8, buf[3 .. buf.len - 1], ";");

    var cb = try parseCb(try nextParsed(u8, &split));
    const cx = try nextParsed(u16, &split) - 1;
    const cy = try nextParsed(u16, &split) - 1;

    const ending = buf[buf.len - 1];

    if (ending == 'm') switch (cb.kind) {
        .Down => |btn| cb.kind = .{ .Up = btn },
        else => {},
    };

    const ev = Event{ .MouseEvent = .{
        .kind = cb.kind,
        .mods = cb.mods,
        .column = cx,
        .row = cy,
    } };

    return ParseResult{
        .state = .MouseNormal,
        .event = ev,
    };
}

const CbResult = struct {
    kind: event.MouseEventKind,
    mods: event.KeyMods,
};

const MouseButtonEvent = packed struct {
    button_number_low: u2,
    shift: bool,
    alt: bool,
    control: bool,
    dragging: bool,
    button_number_high: u2,
};

fn parseCb(cb: u8) !CbResult {
    const ev: MouseButtonEvent = @bitCast(cb);
    const button_number: u8 = ev.button_number_low | (@as(u8, ev.button_number_high) << 2);
    var kind: event.MouseEventKind = undefined;

    if (ev.dragging) {
        switch (button_number) {
            0 => kind = .{ .Drag = .Left },
            1 => kind = .{ .Drag = .Middle },
            2 => kind = .{ .Drag = .Right },
            3, 4, 5 => kind = .Moved,
            else => return error.CouldNotParseEventError,
        }
    } else {
        switch (button_number) {
            0 => kind = .{ .Down = .Left },
            1 => kind = .{ .Down = .Middle },
            2 => kind = .{ .Down = .Right },
            3 => kind = .{ .Up = .Left },
            4 => kind = .ScrollUp,
            5 => kind = .ScrollDown,
            6 => kind = .ScrollLeft,
            7 => kind = .ScrollRight,
            else => return error.CouldNotParseEventError,
        }
    }

    const mods = event.KeyMods{
        .shift = ev.shift,
        .control = ev.control,
        .alt = ev.alt,
    };

    return CbResult{
        .kind = kind,
        .mods = mods,
    };
}

fn checkedSub(comptime T: type, a: T, b: T) ?T {
    return if (a < b) null else a - b;
}

test "parse csi normal mouse event" {
    const sequence = "\x1B[M0\x60\x70";

    const result = try parseAnsi(sequence);

    const expected = Event{ .MouseEvent = .{
        .kind = .{ .Down = .Left },
        .column = 63,
        .row = 79,
        .mods = .{ .control = true },
    } };
    try std.testing.expectEqual(expected, result);
}

test "parse sgr (extended) mouse event" {
    // some tests were taken from crossterm, as they have good edge cases
    // coverage
    var sequence: []const u8 = "\x1B[<0;44;12;M";
    var result = try parseAnsi(sequence);

    var expected = Event{ .MouseEvent = .{
        .kind = .{ .Down = .Left },
        .column = 43,
        .row = 11,
        .mods = .{},
    } };
    try std.testing.expectEqual(expected, result);

    sequence = "\x1B[<0;20;10;m";
    result = try parseAnsi(sequence);

    expected = Event{ .MouseEvent = .{
        .kind = .{ .Up = .Left },
        .column = 19,
        .row = 9,
        .mods = .{},
    } };
    try std.testing.expectEqual(expected, result);

    // ensure it works without semicolon after row number
    sequence = "\x1B[<0;20;10m";
    result = try parseAnsi(sequence);

    expected = Event{ .MouseEvent = .{
        .kind = .{ .Up = .Left },
        .column = 19,
        .row = 9,
        .mods = .{},
    } };
    try std.testing.expectEqual(expected, result);
}
