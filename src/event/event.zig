const builtin = @import("builtin");

const Handle = @import("../main.zig").Handle;

const event_impl = switch (builtin.os.tag) {
    .linux => @import("unix.zig"),
    else => @panic("TODO"),
};

const EventKind = enum {
    KeyEvent,
    FocusGained,
    FocusLost,
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
};

/// Blocking read from handle until a new event is available.
pub fn read(handle: Handle) !Event {
    return event_impl.read(handle);
}
