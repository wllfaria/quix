const builtin = @import("builtin");

const Handle = @import("main.zig").Handle;

const event = switch (builtin.os.tag) {
    .linux => @import("unix/event.zig"),
    else => @panic("TODO"),
};

const EventKind = enum { KeyEvent };

const KeyMods = packed struct {
    shift: bool = false,
    control: bool = false,
    alt: bool = false,
    super: bool = false,
    hyper: bool = false,
    meta: bool = false,
    _pad: u2 = 0,

    pub fn noModifiers(self: *KeyMods) bool {
        return @as(u8, @bitCast(self)) == 0;
    }
};

const KeyKind = enum {
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

const Key = struct {
    code: u8,
    kind: KeyKind,
    mods: KeyMods,
};

pub const Event = union(EventKind) {
    KeyEvent: Key,
};

pub fn read(handle: Handle) !Event {
    return event.read(handle);
}
