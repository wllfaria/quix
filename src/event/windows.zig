const std = @import("std");
const posix = std.posix;

const quix_winapi = @import("quix_winapi");
const console = quix_winapi.console;

const ansi = @import("../ansi/ansi.zig");
const FileDesc = @import("../file_desc.zig");
const terminal = @import("../terminal/windows.zig");
const constants = @import("../constants.zig");
const event = @import("event.zig");
const Event = event.Event;

const ENABLE_MOUSE_MODE =
    quix_winapi.ENABLE_MOUSE_INPUT |
    quix_winapi.ENABLE_WINDOW_INPUT |
    quix_winapi.ENABLE_EXTENDED_FLAGS;

var ORIGINAL_MODE = std.atomic.Value(u64).init(constants.U64_MAX);

const MouseButtonsPressed = struct {
    left: bool = false,
    right: bool = false,
    middle: bool = false,
};

var mouse_buttons_pressed_mutex: std.Thread.Mutex = .{};
var mouse_buttons_pressed: MouseButtonsPressed = .{};

fn initOriginalMode(original_mode: u32) void {
    _ = ORIGINAL_MODE.cmpxchgWeak(constants.U64_MAX, original_mode, .acq_rel, .acq_rel);
}

fn getOriginalMode() !u32 {
    const original_mode = ORIGINAL_MODE.load(.acq_rel);
    if (original_mode == constants.U64_MAX) return error.OriginalModeNotInitialized;
    return @as(u32, @intCast(original_mode));
}

pub fn enableMouse() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        ansi.enableMouse(handle.writer());
        return;
    }

    const handle = try quix_winapi.handle.getCurrentInHandle();
    const mode = try quix_winapi.console.getMode(handle);
    initOriginalMode(mode);
    try quix_winapi.console.setMode(handle, ENABLE_MOUSE_MODE);
}

pub fn disableMouse() !void {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentOutHandle();
        ansi.disableMouse(handle.writer());
        return;
    }

    const handle = try quix_winapi.handle.getCurrentInHandle();
    const origina_mode = try getOriginalMode();
    try quix_winapi.console.setMode(handle, origina_mode);
}

pub fn poll(_: u32) !bool {
    if (terminal.hasAnsiSupport()) {
        const handle = try quix_winapi.handle.getCurrentInHandle();
        const bytes_available = try quix_winapi.console.peekNamedPipe(handle);
        return bytes_available > 0;
    } else {
        const handle = try quix_winapi.handle.getCurrentInHandle();
        const events_read = try quix_winapi.console.peekInput(handle);
        return events_read > 0;
    }
}

pub fn read() !Event {
    if (terminal.hasAnsiSupport()) return readFile();

    const handle = try quix_winapi.handle.getCurrentInHandle();
    const input_record = try console.readSingleInput(handle);
    return parseInputRecord(input_record);
}

fn readFile() !Event {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    var buf: [ansi.IO_BUFFER_SIZE]u8 = undefined;

    while (true) {
        const bytes_read = try std.os.windows.ReadFile(handle.inner, &buf, null);
        if (bytes_read > 0) return ansi.parser.parseAnsi(buf[0..bytes_read]);
    }
}

fn parseInputRecord(input_record: quix_winapi.InputRecord) !Event {
    return switch (input_record) {
        .KeyEvent => |ev| parseKeyEvent(ev),
        .MouseEvent => |ev| blk: {
            mouse_buttons_pressed_mutex.lock();
            defer mouse_buttons_pressed_mutex.unlock();

            const mouse_event = try parseMouseEvent(ev, mouse_buttons_pressed);

            // update current pressed buttons to be able to dictate whether or
            // not we are double clicking, dragging, pressing or releasing a
            // button
            mouse_buttons_pressed = MouseButtonsPressed{
                .left = ev.button_state.leftButtonPressed(),
                .right = ev.button_state.rightButtonPressed(),
                .middle = ev.button_state.middleButtonPressed(),
            };

            break :blk mouse_event;
        },
        .WindowBufferSizeEvent => |ev| parseBufferSizeEvent(ev),
        .MenuEvent => |ev| parseMenuEvent(ev),
        .FocusEvent => |ev| parseFocusEvent(ev),
    };
}

fn parseKeyEvent(_: quix_winapi.KeyEventRecord) !Event {
    @panic("TODO");
}

fn parseMouseEvent(
    ev: quix_winapi.MouseEventRecord,
    buttons_pressed: MouseButtonsPressed,
) !Event {
    var kind: ?event.MouseEventKind = null;

    if (ev.event_flags.pressOrRelease() or ev.event_flags.double_click) {
        if (ev.button_state.leftButtonPressed() and !buttons_pressed.left) {
            kind = event.MouseEventKind{ .Down = .Left };
        } else if (!ev.button_state.leftButtonPressed() and buttons_pressed.left) {
            kind = event.MouseEventKind{ .Up = .Left };
        } else if (ev.button_state.rightButtonPressed() and !buttons_pressed.left) {
            kind = event.MouseEventKind{ .Down = .Right };
        } else if (!ev.button_state.rightButtonPressed() and buttons_pressed.left) {
            kind = event.MouseEventKind{ .Up = .Right };
        } else if (ev.button_state.middleButtonPressed() and !buttons_pressed.middle) {
            kind = event.MouseEventKind{ .Down = .Middle };
        } else if (!ev.button_state.middleButtonPressed() and buttons_pressed.middle) {
            kind = event.MouseEventKind{ .Up = .Middle };
        }
    } else if (ev.event_flags.mouse_move) {
        const button = if (ev.button_state.rightButtonPressed()) blk: {
            break :blk event.MouseButton.Right;
        } else if (ev.button_state.middleButtonPressed()) blk: {
            break :blk event.MouseButton.Middle;
        } else event.MouseButton.Left;

        if (ev.button_state.releaseButton()) {
            kind = event.MouseEventKind.Moved;
        } else {
            kind = event.MouseEventKind{ .Drag = button };
        }
    } else if (ev.event_flags.mouse_scroll) {
        if (ev.button_state.scrollUp()) {
            kind = event.MouseEventKind.ScrollUp;
        } else if (ev.button_state.scrollDown()) {
            kind = event.MouseEventKind.ScrollUp;
        }
    } else {
        // horizontal scroll.
        if (ev.button_state.scrollLeft()) {
            kind = event.MouseEventKind.ScrollLeft;
        } else if (ev.button_state.scrollRight) {
            kind = event.MouseEventKind.ScrollRight;
        }
    }

    const mods = event.KeyMods{
        .shift = ev.control_key_state.shift,
        .control = ev.control_key_state.controlPressed(),
        .alt = ev.control_key_state.altPressed(),
        // legacy WinAPI doesn't support modifiers below
        .super = false,
        .hyper = false,
        .meta = false,
    };

    const column = @as(u16, @intCast(ev.mouse_position.x));
    const row = @as(u16, @intCast(try convertRelativeY(ev.mouse_position.y)));

    const mouse_event = event.MouseEvent{
        .kind = kind.?,
        .column = column,
        .row = row,
        .mods = mods,
    };

    return Event{ .MouseEvent = mouse_event };
}

fn convertRelativeY(y: i16) !i16 {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const csbi = try quix_winapi.console.getInfo(handle);
    const window_size = csbi.terminalWindow();
    return y - window_size.top;
}

fn parseBufferSizeEvent(ev: quix_winapi.WindowBufferSizeRecord) !Event {
    const columns = @as(u16, @intCast(ev.size.x));
    const rows = @as(u16, @intCast(ev.size.y));

    return Event{ .Resize = .{
        .columns = columns,
        .rows = rows,
    } };
}

fn parseMenuEvent(_: quix_winapi.MenuEventRecord) !Event {
    return error.ReservedEvent;
}

fn parseFocusEvent(ev: quix_winapi.FocusEventRecord) !Event {
    return if (ev.set_focus) event.Event.FocusGained else event.Event.FocusLost;
}
