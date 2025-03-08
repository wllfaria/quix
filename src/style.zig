const std = @import("std");
const posix = std.posix;

const ansi = @import("ansi.zig");

pub const RgbColor = struct {
    r: u8,
    g: u8,
    b: u8,
};

pub const ColoredSection = enum(u2) {
    Foreground,
    Background,
    Underline,
};

pub const Color = union(enum) {
    Reset,
    Black,
    DarkGrey,
    Red,
    DarkRed,
    Green,
    DarkGreen,
    Yellow,
    DarkYellow,
    Blue,
    DarkBlue,
    Magenta,
    DarkMagenta,
    Cyan,
    DarkCyan,
    White,
    Grey,
    Rgb: RgbColor,
    AnsiValue: u8,

    pub fn asStr(self: @This(), kind: ColoredSection, buffer: []u8) []const u8 {
        const reset_code = switch (kind) {
            .Foreground => "39",
            .Background => "49",
            .Underline => "59",
        };

        if (self == .Reset) {
            @memcpy(buffer[0..reset_code.len], reset_code);
            return buffer[0..reset_code.len];
        }

        const prefix = switch (kind) {
            .Foreground => "38;",
            .Background => "48;",
            .Underline => "58;",
        };

        _ = std.fmt.bufPrint(buffer[0..], "{s}", .{prefix}) catch unreachable;

        if (self == .Rgb) {
            const rgb = self.Rgb;
            const color = std.fmt.bufPrint(buffer[prefix.len..], "2;{};{};{}", .{ rgb.r, rgb.g, rgb.b }) catch unreachable;
            return buffer[0 .. prefix.len + color.len];
        }

        if (self == .AnsiValue) {
            const ansi_val = self.AnsiValue;
            const color = std.fmt.bufPrint(buffer[prefix.len..], "5;{}", .{ansi_val}) catch unreachable;
            return buffer[0 .. prefix.len + color.len];
        }

        const color = switch (self) {
            .Black => "5;0",
            .DarkGrey => "5;8",
            .Red => "5;9",
            .DarkRed => "5;1",
            .Green => "5;10",
            .DarkGreen => "5;2",
            .Yellow => "5;11",
            .DarkYellow => "5;3",
            .Blue => "5;12",
            .DarkBlue => "5;4",
            .Magenta => "5;13",
            .DarkMagenta => "5;5",
            .Cyan => "5;14",
            .DarkCyan => "5;6",
            .White => "5;15",
            .Grey => "5;7",
            else => unreachable,
        };

        _ = std.fmt.bufPrint(buffer[prefix.len..], "{s}", .{color}) catch unreachable;

        return buffer[0 .. prefix.len + color.len];
    }
};

pub const Attribute = enum(u5) {
    Reset,
    Bold,
    Dim,
    Italic,
    Underlined,
    DoubleUnderlined,
    Undercurled,
    Underdotted,
    Underdashed,
    SlowBlink,
    RapidBlink,
    Reverse,
    Hidden,
    CrossedOut,
    Fraktur,
    NoBold,
    NormalIntensity,
    NoItalic,
    NoUnderline,
    NoBlink,
    NoReverse,
    NoHidden,
    NotCrossedOut,
    Framed,
    Encircled,
    Overlined,
    NotFramedOrEncircled,
    NotOverlined,
};

pub const ContentAttributes = packed struct {
    bold: bool = false,
    dim: bool = false,
    italic: bool = false,
    underlined: bool = false,
    double_underlined: bool = false,
    undercurled: bool = false,
    underdotted: bool = false,
    underdashed: bool = false,
    slow_blink: bool = false,
    rapid_blink: bool = false,
    reverse: bool = false,
    hidden: bool = false,
    crossed_out: bool = false,
    fraktur: bool = false,
    no_bold: bool = false,
    normal_intensity: bool = false,
    no_italic: bool = false,
    no_underline: bool = false,
    no_blink: bool = false,
    no_reverse: bool = false,
    no_hidden: bool = false,
    not_crossed_out: bool = false,
    framed: bool = false,
    encircled: bool = false,
    overlined: bool = false,
    not_framed_or_encircled: bool = false,
    not_overlined: bool = false,
    _pad: u5 = 0,

    pub fn bytes(self: *const @This()) u32 {
        return @bitCast(self);
    }

    pub fn set(self: *@This(), attribute: Attribute) void {
        switch (attribute) {
            .Reset => self.* = ContentAttributes{},
            .Bold => self.bold = true,
            .Dim => self.dim = true,
            .Italic => self.italic = true,
            .Underlined => self.underlined = true,
            .DoubleUnderlined => self.double_underlined = true,
            .Undercurled => self.undercurled = true,
            .Underdotted => self.underdotted = true,
            .Underdashed => self.underdashed = true,
            .SlowBlink => self.slow_blink = true,
            .RapidBlink => self.rapid_blink = true,
            .Reverse => self.reverse = true,
            .Hidden => self.hidden = true,
            .CrossedOut => self.crossed_out = true,
            .Fraktur => self.fraktur = true,
            .NoBold => self.no_bold = true,
            .NormalIntensity => self.normal_intensity = true,
            .NoItalic => self.no_italic = true,
            .NoUnderline => self.no_underline = true,
            .NoBlink => self.no_blink = true,
            .NoReverse => self.no_reverse = true,
            .NoHidden => self.no_hidden = true,
            .NotCrossedOut => self.not_crossed_out = true,
            .Framed => self.framed = true,
            .Encircled => self.encircled = true,
            .Overlined => self.overlined = true,
            .NotFramedOrEncircled => self.not_framed_or_encircled = true,
            .NotOverlined => self.not_overlined = true,
        }
    }

    pub fn unset(self: *@This(), attribute: Attribute) void {
        switch (attribute) {
            .Reset => self = ContentAttributes{},
            .Bold => self.bold = false,
            .Dim => self.dim = false,
            .Italic => self.italic = false,
            .Underlined => self.underlined = false,
            .DoubleUnderlined => self.double_underlined = false,
            .Undercurled => self.undercurled = false,
            .Underdotted => self.underdotted = false,
            .Underdashed => self.underdashed = false,
            .SlowBlink => self.slow_blink = false,
            .RapidBlink => self.rapid_blink = false,
            .Reverse => self.reverse = false,
            .Hidden => self.hidden = false,
            .CrossedOut => self.crossed_out = false,
            .Fraktur => self.fraktur = false,
            .NoBold => self.no_bold = false,
            .NormalIntensity => self.normal_intensity = false,
            .NoItalic => self.no_italic = false,
            .NoUnderline => self.no_underline = false,
            .NoBlink => self.no_blink = false,
            .NoReverse => self.no_reverse = false,
            .NoHidden => self.no_hidden = false,
            .NotCrossedOut => self.not_crossed_out = false,
            .Framed => self.framed = false,
            .Encircled => self.encircled = false,
            .Overlined => self.overlined = false,
            .NotFramedOrEncircled => self.not_framed_or_encircled = false,
            .NotOverlined => self.not_overlined = false,
        }
    }
};

pub const StyledContent = struct {
    content: []const u8,
    bg: ?Color,
    fg: ?Color,
    attributes: ContentAttributes,

    pub fn background(self: @This(), color: Color) @This() {
        return StyledContent{
            .attributes = self.attributes,
            .content = self.content,
            .fg = self.fg,
            .bg = color,
        };
    }

    pub fn foreground(self: @This(), color: Color) @This() {
        return StyledContent{
            .attributes = self.attributes,
            .content = self.content,
            .bg = self.bg,
            .fg = color,
        };
    }

    pub fn bold(self: @This()) @This() {
        var attributes = self.attributes;
        attributes.set(.Bold);

        return StyledContent{
            .content = self.content,
            .bg = self.bg,
            .fg = self.fg,
            .attributes = attributes,
        };
    }

    pub fn setAttribute(self: @This(), attribute: Attribute) @This() {
        var attributes = self.attributes;
        attributes.set(attribute);

        return StyledContent{
            .content = self.content,
            .bg = self.bg,
            .fg = self.fg,
            .attributes = attributes,
        };
    }

    pub fn unsetAttribute(self: @This(), attribute: Attribute) @This() {
        var attributes = self.attributes;
        attributes.unset(attribute);

        return StyledContent{
            .content = self.content,
            .bg = self.bg,
            .fg = self.fg,
            .attributes = attributes,
        };
    }
};

pub fn style(content: []const u8) StyledContent {
    return StyledContent{
        .content = content,
        .bg = null,
        .fg = null,
        .attributes = ContentAttributes{},
    };
}

pub fn printStyled(fd: posix.fd_t, styled_content: StyledContent) !void {
    var reset_bg = false;
    var reset_fg = false;

    if (styled_content.bg) |bg| {
        try setBackgroundColor(fd, bg);
        reset_bg = true;
    }
    if (styled_content.fg) |fg| {
        try setForegroundColor(fd, fg);
        reset_fg = true;
    }

    _ = try posix.write(fd, styled_content.content);

    if (reset_bg) {
        try setBackgroundColor(fd, .Reset);
    }
    if (reset_fg) {
        try setForegroundColor(fd, .Reset);
    }
}

pub fn setBackgroundColor(fd: posix.fd_t, color: Color) !void {
    const handle = ansi.FileDesc.init(fd);
    var buffer: [16]u8 = undefined;
    const color_str = color.asStr(.Background, buffer[0..]);
    try ansi.csi(handle, "{s}m", .{color_str});
}

pub fn setForegroundColor(fd: posix.fd_t, color: Color) !void {
    const handle = ansi.FileDesc.init(fd);
    var buffer: [16]u8 = undefined;
    const color_str = color.asStr(.Foreground, buffer[0..]);
    try ansi.csi(handle, "{s}m", .{color_str});
}
