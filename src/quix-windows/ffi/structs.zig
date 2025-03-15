const std = @import("std");
const windows = std.os.windows;

pub const KEY_EVENT_UCHAR = extern union {
    UnicodeChar: windows.WCHAR,
    CHAR: windows.CHAR,
};

pub const KEY_EVENT_RECORD = extern struct {
    bKeyDown: windows.BOOL,
    wRepeatCount: windows.WORD,
    wVirtualKeyCode: windows.WORD,
    wVirtualScanCode: windows.WORD,
    uChar: KEY_EVENT_UCHAR,
    dwControlKeyState: windows.DWORD,
};

pub const MOUSE_EVENT_RECORD = extern struct {
    dwMousePosition: windows.COORD,
    dwButtonState: windows.DWORD,
    dwControlKeyState: windows.DWORD,
    dwEventFlags: windows.DWORD,
};

pub const WINDOW_BUFFER_SIZE_RECORD = extern struct {
    dwSize: windows.COORD,
};

pub const MENU_EVENT_RECORD = extern struct {
    dwCommandId: windows.UINT,
};

pub const FOCUS_EVENT_RECORD = extern struct {
    bSetFocus: windows.BOOL,
};

pub const INPUT_RECORD_EVENT = extern union {
    KeyEvent: KEY_EVENT_RECORD,
    MouseEvent: MOUSE_EVENT_RECORD,
    WindowBufferSizeEvent: WINDOW_BUFFER_SIZE_RECORD,
    MenuEvent: MENU_EVENT_RECORD,
    FocusEvent: FOCUS_EVENT_RECORD,
};

pub const INPUT_RECORD = extern struct {
    EventType: windows.WORD,
    Event: INPUT_RECORD_EVENT,
};
