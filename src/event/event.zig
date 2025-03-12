const std = @import("std");
const builtin = @import("builtin");

const Handle = @import("../main.zig").Handle;

const event_impl = switch (builtin.os.tag) {
    .linux => @import("unix.zig"),
    .macos => @import("unix.zig"),
    else => @panic("TODO"),
};

const EventKind = enum {
    KeyEvent,
    FocusGained,
    FocusLost,
    MouseEvent,

    pub fn isFocusGained(self: @This()) bool {
        return self == .FocusGained;
    }

    pub fn isFocusLost(self: @This()) bool {
        return self == .FocusLost;
    }

    pub fn isKey(self: @This()) bool {
        return self == .KeyEvent;
    }

    pub fn isMouse(self: @This()) bool {
        return self == .MouseEvent;
    }
};

/// Bitset of every possible modifier on a key event.
pub const KeyMods = packed struct {
    shift: bool = false,
    control: bool = false,
    alt: bool = false,
    super: bool = false,
    hyper: bool = false,
    meta: bool = false,
    /// Additional padding to fit on a u8.
    _pad: u2 = 0,

    pub fn noModifiers(self: *KeyMods) bool {
        return @as(u8, @bitCast(self)) == 0;
    }
};

/// Represent different kinds of keys that can be sent on an event.
///
/// This is useful for quickly checking whether some special key was pressed.
pub const KeyKind = enum {
    Char,
    Backspace,
    Enter,
    Left,
    Right,
    Up,
    Down,
    Home,
    End,
    PageUp,
    PageDown,
    Tab,
    BackTab,
    Delete,
    Insert,
    Function,
    Esc,
    Capslock,
    ScrollLock,
    NumLock,
    PrintScreen,
    Pause,
    Menu,

    /// Returns a string representation of the key kind
    pub fn toString(self: @This()) []const u8 {
        return switch (self) {
            .Char => "char",
            .Backspace => "backspace",
            .Enter => "enter",
            .Left => "left",
            .Right => "right",
            .Up => "up",
            .Down => "down",
            .Home => "home",
            .End => "end",
            .PageUp => "page_up",
            .PageDown => "page_down",
            .Tab => "tab",
            .BackTab => "back_tab",
            .Delete => "delete",
            .Insert => "insert",
            .Function => "fn",
            .Esc => "esc",
            .Capslock => "caps_lock",
            .ScrollLock => "scroll_lock",
            .NumLock => "num_lock",
            .PrintScreen => "print_screen",
            .Pause => "pause",
            .Menu => "menu",
        };
    }
};

/// Whick kind of key event was received.
pub const KeyEventKind = enum {
    Press,
};

/// Represents a Key Event.
pub const Key = struct {
    /// The actual byte of the key event
    code: u8,
    /// Which kind of event it is.
    ///
    /// This is useful for special keys, such as `Enter` or `BackTab`.
    kind: KeyKind,
    /// Key modifiers on the event.
    mods: KeyMods,
    /// Which kind of key event this is.
    event_kind: KeyEventKind = .Press,
};

/// Represent an terminal event.
pub const Event = union(EventKind) {
    /// A key event, such as user input.
    KeyEvent: Key,
    /// Terminal was focused.
    FocusGained,
    /// Terminal lost focus.
    FocusLost,
    /// A mouse event
    MouseEvent: MouseEvent,
};

pub const MouseEventKind = union(enum) {
    Down: MouseButton,
    Up: MouseButton,
    Drag: MouseButton,
    Moved,
    ScrollDown,
    ScrollUp,
    ScrollLeft,
    ScrollRight,
};

pub const MouseButton = enum {
    Left,
    Middle,
    Right,
};

pub const MouseEvent = struct {
    kind: MouseEventKind,
    column: u16,
    row: u16,
    mods: KeyMods,
};

/// Blocking read from handle until a new event is available.
pub fn read() !Event {
    return event_impl.read();
}

pub fn enableMouse() !void {
    return event_impl.enableMouse();
}

pub fn disableMouse() !void {
    return event_impl.disableMouse();
}

test "event is" {
    var event = Event.FocusGained;
    try std.testing.expect(event.isFocusGained());
    try std.testing.expect(!event.isFocusLost());
    try std.testing.expect(!event.isKey());
    try std.testing.expect(!event.isMouse());

    event = Event.FocusLost;
    try std.testing.expect(!event.isFocusGained());
    try std.testing.expect(event.isFocusLost());
    try std.testing.expect(!event.isKey());
    try std.testing.expect(!event.isMouse());

    event = Event{ .MouseEvent = .{
        .column = 100,
        .row = 100,
        .kind = .{ .Down = .Left },
        .mods = .{},
    } };
    try std.testing.expect(!event.isFocusGained());
    try std.testing.expect(!event.isFocusLost());
    try std.testing.expect(!event.isKey());
    try std.testing.expect(event.isMouse());

    event = Event{ .KeyEvent = .{
        .code = 65,
        .event_kind = .Press,
        .kind = .Char,
        .mods = .{},
    } };
    try std.testing.expect(!event.isFocusGained());
    try std.testing.expect(!event.isFocusLost());
    try std.testing.expect(event.isKey());
    try std.testing.expect(!event.isMouse());
}

test {
    std.testing.refAllDecls(@This());
}
