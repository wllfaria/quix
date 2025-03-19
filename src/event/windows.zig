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
var surrogate_buffer_mutex: std.Thread.Mutex = .{};
var surrogate_buffer: ?u16 = null;

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

    while (true) {
        const handle = try quix_winapi.handle.getCurrentInHandle();
        const input_record = try console.readSingleInput(handle);
        const ev = try parseInputRecord(input_record);
        if (ev) |e| return e;
    }
}

fn readFile() !Event {
    const handle = try quix_winapi.handle.getCurrentInHandle();
    var buf: [ansi.IO_BUFFER_SIZE]u8 = undefined;

    while (true) {
        const bytes_read = try std.os.windows.ReadFile(handle.inner, &buf, null);
        if (bytes_read > 0) return ansi.parser.parseAnsi(buf[0..bytes_read]);
    }
}

fn parseInputRecord(input_record: quix_winapi.InputRecord) !?Event {
    switch (input_record) {
        .KeyEvent => |ev| {
            surrogate_buffer_mutex.lock();
            defer surrogate_buffer_mutex.unlock();
            const win_event = parseKeyEvent(ev) orelse return null;

            switch (win_event) {
                .Event => |e| {
                    // when a valid event is constructed, discard any
                    // surrogates, even if the previous one was partial
                    surrogate_buffer = null;
                    return e;
                },
                .Surrogate => |s| {
                    const ch = parseSurrogate(&surrogate_buffer, s) orelse return null;
                    const mods = modsFromControlState(ev.control_key_state);
                    return Event{ .KeyEvent = .{
                        .code = ch,
                        .event_kind = .Press,
                        .kind = .Char,
                        .mods = mods,
                    } };
                },
            }
        },
        .MouseEvent => |ev| {
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

            return mouse_event;
        },
        .WindowBufferSizeEvent => |ev| {
            const result = try parseBufferSizeEvent(ev);
            return result;
        },
        .MenuEvent => |ev| {
            const result = try parseMenuEvent(ev);
            return result;
        },
        .FocusEvent => |ev| {
            const result = try parseFocusEvent(ev);
            return result;
        },
    }
}

pub fn parseSurrogate(buffer: *?u16, new_surrogate: u16) ?u32 {
    if (buffer.* == null) {
        buffer.* = new_surrogate;
        return null;
    }

    const char = std.unicode.utf16DecodeSurrogatePair(&.{
        buffer.*.?,
        new_surrogate,
    }) catch unreachable;

    buffer.* = null;
    return @as(u32, char);
}

const WindowsEvent = union(enum) {
    Event: Event,
    Surrogate: u16,
};

fn parseKeyEvent(ev: quix_winapi.KeyEventRecord) ?WindowsEvent {
    const mods = modsFromControlState(ev.control_key_state);
    const virtual_key = ev.virtual_key_code;

    const result = switch (virtual_key) {
        quix_winapi.VK_SHIFT, quix_winapi.VK_CONTROL, quix_winapi.VK_MENU => null,
        quix_winapi.VK_BACK => event.KeyKind.Backspace,
        quix_winapi.VK_ESCAPE => event.KeyKind.Esc,
        quix_winapi.VK_RETURN => event.KeyKind.Enter,
        quix_winapi.VK_LEFT => event.KeyKind.Left,
        quix_winapi.VK_UP => event.KeyKind.Up,
        quix_winapi.VK_RIGHT => event.KeyKind.Right,
        quix_winapi.VK_DOWN => event.KeyKind.Down,
        quix_winapi.VK_PRIOR => event.KeyKind.PageUp,
        quix_winapi.VK_NEXT => event.KeyKind.PageDown,
        quix_winapi.VK_HOME => event.KeyKind.Home,
        quix_winapi.VK_END => event.KeyKind.End,
        quix_winapi.VK_DELETE => event.KeyKind.Delete,
        quix_winapi.VK_INSERT => event.KeyKind.Insert,
        quix_winapi.VK_TAB => if (mods.shift) event.KeyKind.BackTab else event.KeyKind.Tab,
        else => blk: {
            if (virtual_key >= quix_winapi.VK_F1 and virtual_key <= quix_winapi.VK_F24) {
                break :blk event.KeyKind.Function;
            }

            const utf16 = ev.u_char;

            if (utf16 >= 0x00 and utf16 <= 0x1F) {
                break :blk event.KeyKind.Char;
            } else if (std.unicode.utf16IsLowSurrogate(utf16)) {
                return WindowsEvent{ .Surrogate = utf16 };
            } else {
                break :blk event.KeyKind.Char;
            }
        },
    };

    const char = if (result) |kind| switch (kind) {
        .Char => getCharForKey(ev),
        .Function => 1,
        else => null,
    } else null;

    const event_kind: event.KeyEventKind = if (ev.key_down) .Press else .Release;

    if (result) |kind| {
        return WindowsEvent{
            .Event = Event{ .KeyEvent = .{
                .kind = kind,
                .mods = mods,
                .event_kind = event_kind,
                .code = if (char) |ch| ch else @as(u32, ev.u_char),
            } },
        };
    }

    return null;
}

/// Tries to return the character for a key accounting for user keyboard layout
///
/// Returns null when the event doesn't map to a character or when the key is
/// dead.
///
/// Uses the currently active keyboard to check which key an event maps. Which
/// may be wrong, as terminals process user input asynchronously. There is a
/// chance the user might have changed its layout in between the event being
/// fired and the processing starting. But this is unlikely to happen.
fn getCharForKey(ev: quix_winapi.KeyEventRecord) ?u32 {
    const virtual_key = @as(u32, ev.virtual_key_code);
    const virtual_scan = @as(u32, ev.virtual_scan_code);
    const key_state = [_]u8{0} ** 256;
    var utf16_buf = [_]u16{0} ** 16;
    const dont_change_kernel_keyboard_state = 0x4;

    const foreground_window = quix_winapi.getForegroundWindow();
    const foreground_thread = quix_winapi.getWindowThreadProcessId(foreground_window, null);
    const keyboard_layout = quix_winapi.getKeyboardLayout(foreground_thread);

    const result = quix_winapi.toUnicodeEx(
        virtual_key,
        virtual_scan,
        &key_state,
        @ptrCast(&utf16_buf),
        @as(i32, @intCast(utf16_buf.len)),
        dont_change_kernel_keyboard_state,
        keyboard_layout,
    );

    // -1 means its a dead key
    //  0 means no character for key
    if (result < 1) return null;

    // Key doesn't map to a single character (surrogate pair)
    if (result > 1) return null;

    return @as(u32, utf16_buf[0]);
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
        } else if (ev.button_state.scrollRight()) {
            kind = event.MouseEventKind.ScrollRight;
        }
    }

    const mods = modsFromControlState(ev.control_key_state);

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

fn modsFromControlState(
    control_state: quix_winapi.ControlKeyState,
) event.KeyMods {
    return event.KeyMods{
        .shift = control_state.shift,
        .control = control_state.controlPressed(),
        .alt = control_state.altPressed(),
        // legacy WinAPI doesn't support modifiers below
        .super = false,
        .hyper = false,
        .meta = false,
    };
}

fn convertRelativeY(y: i16) !i16 {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const csbi = try quix_winapi.console.getInfo(handle);
    const window_size = csbi.terminalWindow();
    return y - window_size.top;
}

fn parseBufferSizeEvent(ev: quix_winapi.WindowBufferSizeRecord) !Event {
    const columns = @as(u16, @intCast(@as(i32, ev.size.x) + 1));
    const rows = @as(u16, @intCast(@as(i32, ev.size.y) + 1));

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
