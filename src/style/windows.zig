const std = @import("std");
const quix_winapi = @import("quix_winapi");

const ansi = @import("../ansi/ansi.zig");
const ansi_style = @import("ansi_style.zig");
const terminal = @import("../terminal/windows.zig");
const Attribute = @import("attributes.zig").Attribute;
const colors = @import("colors.zig");
const Color = colors.Color;
const Colors = @import("style.zig").Colors;
const ContentAttributes = @import("content_attributes.zig").ContentAttributes;
const ContentStyle = @import("style.zig").ContentStyle;
const StyledContent = @import("styled_content.zig").StyledContent;

pub fn print(content: []const u8) !void {
    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const writer = handle.writer();
    _ = try writer.write(content);
}

pub fn printAnsi(comptime content: []const u8, args: anytype) !void {
    if (!terminal.hasAnsiSupport()) return;

    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const writer = handle.writer();
    try ansi.csi(writer, content, args);
}

pub fn printStyled(styled_content: StyledContent) !void {
    if (terminal.hasAnsiSupport()) return ansi_style.printStyled(styled_content);

    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const csbi = try quix_winapi.console.getInfo(handle);

    const attributes = mapStyleToWinAPI(styled_content.style);
    try quix_winapi.console.setTextAttribute(handle, attributes);

    try print(styled_content.content);

    try quix_winapi.console.setTextAttribute(handle, csbi.attributes());
}

fn mapStyleToWinAPI(style: ContentStyle) u16 {
    var attributes: u16 = 0;

    if (style.fg) |fg| attributes |= mapColorToWinAPI(fg, .Foreground);
    if (style.bg) |bg| attributes |= mapColorToWinAPI(bg, .Background);

    if (style.attributes.bold) attributes |= quix_winapi.FOREGROUND_INTENSITY;
    if (style.attributes.underlined) attributes |= quix_winapi.COMMON_LVB_UNDERSCORE;
    if (style.attributes.reverse) attributes |= quix_winapi.COMMON_LVB_REVERSE_VIDEO;

    if (style.attributes.no_bold) attributes &= ~quix_winapi.FOREGROUND_INTENSITY;
    if (style.attributes.no_underline) attributes &= ~quix_winapi.COMMON_LVB_UNDERSCORE;
    if (style.attributes.no_reverse) attributes &= ~quix_winapi.COMMON_LVB_REVERSE_VIDEO;

    return attributes;
}

fn isBrightRGB(rgb: colors.RgbColor) bool {
    const r_float = @as(f16, @floatFromInt(rgb.r));
    const g_float = @as(f16, @floatFromInt(rgb.g));
    const b_float = @as(f16, @floatFromInt(rgb.b));

    // The perceived luminance of an RGB color can be calculated using the following formula:
    // L = 0.299 * R + 0.587 * G + 0.114 * B
    const luminance: f16 = 0.299 * r_float + 0.587 * g_float + 0.114 * b_float;
    // luminance ranges from 0..=255.
    return luminance > 127.0;
}

fn mapColorToWinAPI(color: Color, region: colors.ColoredSection) u16 {
    const qa = quix_winapi;
    var c = color;

    // if color is an ANSI value (256 indexed color), it is converted either to
    // an RGB color or to one of the 16 SYSTEM colors.
    if (c == .AnsiValue) c = c.convertAnsiValue();

    if (region == .Foreground) {
        if (c == .Rgb) {
            const rgb = c.Rgb;
            const is_bright = isBrightRGB(rgb);

            var color_attr: u16 = if (is_bright) qa.FOREGROUND_INTENSITY else 0;
            // set attribute if rgb has enough of a color. Values were chosen
            // sorta of arbitrarily.
            if (rgb.r > 127) color_attr |= qa.FOREGROUND_RED;
            if (rgb.g > 127) color_attr |= qa.FOREGROUND_GREEN;
            if (rgb.b > 127) color_attr |= qa.FOREGROUND_BLUE;
            return color_attr;
        }

        return switch (c) {
            .Reset => 0,
            .Black => 0,
            .DarkGrey => qa.FOREGROUND_BLUE | qa.FOREGROUND_GREEN | qa.FOREGROUND_RED,
            .Red => qa.FOREGROUND_RED,
            .DarkRed => qa.FOREGROUND_RED | qa.FOREGROUND_INTENSITY,
            .Green => qa.FOREGROUND_GREEN,
            .DarkGreen => qa.FOREGROUND_GREEN | qa.FOREGROUND_INTENSITY,
            .Yellow => qa.FOREGROUND_RED | qa.FOREGROUND_GREEN,
            .DarkYellow => qa.FOREGROUND_RED | qa.FOREGROUND_GREEN | qa.FOREGROUND_INTENSITY,
            .Blue => qa.FOREGROUND_BLUE,
            .DarkBlue => qa.FOREGROUND_BLUE | qa.FOREGROUND_INTENSITY,
            .Magenta => qa.FOREGROUND_RED | qa.FOREGROUND_BLUE,
            .DarkMagenta => qa.FOREGROUND_RED | qa.FOREGROUND_BLUE | qa.FOREGROUND_INTENSITY,
            .Cyan => qa.FOREGROUND_GREEN | qa.FOREGROUND_BLUE,
            .DarkCyan => qa.FOREGROUND_GREEN | qa.FOREGROUND_BLUE | qa.FOREGROUND_INTENSITY,
            .White => qa.FOREGROUND_RED | qa.FOREGROUND_GREEN | qa.FOREGROUND_BLUE,
            .Grey => qa.FOREGROUND_RED | qa.FOREGROUND_GREEN | qa.FOREGROUND_BLUE | qa.FOREGROUND_INTENSITY,
            else => unreachable,
        };
    }

    if (c == .Rgb) {
        const rgb = color.Rgb;
        const is_bright = isBrightRGB(rgb);

        var color_attr: u16 = if (is_bright) qa.BACKGROUND_INTENSITY else 0;
        // set attribute if rgb has enough of a color. Values were chosen
        // sorta of arbitrarily.
        if (rgb.r > 127) color_attr |= qa.BACKGROUND_RED;
        if (rgb.g > 127) color_attr |= qa.BACKGROUND_GREEN;
        if (rgb.b > 127) color_attr |= qa.BACKGROUND_BLUE;
        return color_attr;
    }

    return switch (c) {
        .Reset => 0,
        .Black => 0,
        .DarkGrey => qa.BACKGROUND_BLUE | qa.BACKGROUND_GREEN | qa.BACKGROUND_RED,
        .Red => qa.BACKGROUND_RED,
        .DarkRed => qa.BACKGROUND_RED | qa.BACKGROUND_INTENSITY,
        .Green => qa.BACKGROUND_GREEN,
        .DarkGreen => qa.BACKGROUND_GREEN | qa.BACKGROUND_INTENSITY,
        .Yellow => qa.BACKGROUND_RED | qa.BACKGROUND_GREEN,
        .DarkYellow => qa.BACKGROUND_RED | qa.BACKGROUND_GREEN | qa.BACKGROUND_INTENSITY,
        .Blue => qa.BACKGROUND_BLUE,
        .DarkBlue => qa.BACKGROUND_BLUE | qa.BACKGROUND_INTENSITY,
        .Magenta => qa.BACKGROUND_RED | qa.BACKGROUND_BLUE,
        .DarkMagenta => qa.BACKGROUND_RED | qa.BACKGROUND_BLUE | qa.BACKGROUND_INTENSITY,
        .Cyan => qa.BACKGROUND_GREEN | qa.BACKGROUND_BLUE,
        .DarkCyan => qa.BACKGROUND_GREEN | qa.BACKGROUND_BLUE | qa.BACKGROUND_INTENSITY,
        .White => qa.BACKGROUND_RED | qa.BACKGROUND_GREEN | qa.BACKGROUND_BLUE,
        .Grey => qa.BACKGROUND_RED | qa.BACKGROUND_GREEN | qa.BACKGROUND_BLUE | qa.BACKGROUND_INTENSITY,
        else => unreachable,
    };
}

pub fn setBackgroundColor(color: Color) !void {
    if (terminal.hasAnsiSupport()) return ansi_style.setBackgroundColor(color);

    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const csbi = try quix_winapi.console.getInfo(handle);

    const win_color = mapColorToWinAPI(color, .Background);
    try quix_winapi.console.setTextAttribute(csbi.attributes() | win_color);
}

pub fn setForegroundColor(color: Color) !void {
    if (terminal.hasAnsiSupport()) return ansi_style.setForegroundColor(color);

    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const csbi = try quix_winapi.console.getInfo(handle);

    const win_color = mapColorToWinAPI(color, .Foreground);
    try quix_winapi.console.setTextAttribute(csbi.attributes() | win_color);
}

pub fn setColors(c: Colors) !void {
    if (terminal.hasAnsiSupport()) return ansi_style.setColors(c);

    if (c.fg) |fg| try setForegroundColor(fg);
    if (c.bg) |bg| try setBackgroundColor(bg);
}

pub fn setAttribute(attribute: Attribute) !void {
    if (terminal.hasAnsiSupport()) return ansi_style.setAttribute(attribute);

    const handle = try quix_winapi.handle.getCurrentOutHandle();
    const csbi = try quix_winapi.console.getInfo(handle);
    var attributes = csbi.attributes();

    switch (attribute) {
        .Bold => attributes |= quix_winapi.FOREGROUND_INTENSITY,
        .Underlined => attributes |= quix_winapi.COMMON_LVB_UNDERSCORE,
        .Reverse => attributes |= quix_winapi.COMMON_LVB_REVERSE_VIDEO,
        .NoBold => attributes &= ~quix_winapi.FOREGROUND_INTENSITY,
        .NoUnderline => attributes &= ~quix_winapi.COMMON_LVB_UNDERSCORE,
        .NoReverse => attributes &= &quix_winapi.COMMON_LVB_REVERSE_VIDEO,
        // Legacy WinAPI does not suppport any other attributes
        else => {},
    }

    try quix_winapi.console.setTextAttribute(attributes);
}

pub fn setAttributes(attributes: ContentAttributes) !void {
    if (terminal.hasAnsiSupport()) return ansi_style.setAttributes(attributes);

    for (Attribute.iter()) |attribute| {
        if (attributes.has(attribute)) {
            try setAttribute(attribute);
        }
    }
}

pub fn setStyle(content_style: ContentStyle) !void {
    if (terminal.hasAnsiSupport()) return ansi_style.setStyle(content_style);

    if (content_style.bg) |bg| try setBackgroundColor(bg);
    if (content_style.fg) |fg| try setForegroundColor(fg);

    if (!content_style.attributes.isEmpty()) {
        try setAttributes(content_style.attributes);
    }
}

pub fn resetColor() !void {
    if (terminal.hasAnsiSupport()) return ansi_style.resetColor();

    // no equivalent in WinAPI
}
