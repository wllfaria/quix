const std = @import("std");
const posix = std.posix;

pub const Color = @import("colors.zig").Color;
pub const RgbColor = @import("colors.zig").RgbColor;
pub const ColoredSection = @import("colors.zig").ColoredSection;
pub const Attribute = @import("attributes.zig").Attribute;
pub const ContentAttributes = @import("content_attributes.zig").ContentAttributes;

const ansi = @import("../ansi.zig");

/// Represents the colors for a text
pub const Colors = struct {
    fg: ?Color,
    bg: ?Color,
};

/// Represents the styling of a particular text content
pub const ContentStyle = struct {
    bg: ?Color = null,
    fg: ?Color = null,
    attributes: ContentAttributes = .{},
};

/// Represents a styled piece of text.
pub const StyledContent = struct {
    content: []const u8,
    style: ContentStyle,

    /// Sets the background of the content.
    pub fn background(self: @This(), color: Color) @This() {
        var new_style = self.style;
        new_style.bg = color;

        return StyledContent{
            .content = self.content,
            .style = new_style,
        };
    }

    /// Sets the foreground of the content.
    pub fn foreground(self: @This(), color: Color) @This() {
        var new_style = self.style;
        new_style.fg = color;

        return StyledContent{
            .content = self.content,
            .style = new_style,
        };
    }

    /// Sets the bold attribute of the content.
    pub fn bold(self: @This()) @This() {
        return self.setAttribute(.Bold);
    }

    /// Sets the dim attribute of the content.
    pub fn dim(self: @This()) @This() {
        return self.setAttribute(.Dim);
    }

    /// Sets the italic attribute of the content.
    pub fn italic(self: @This()) @This() {
        return self.setAttribute(.Italic);
    }

    /// Sets the underlined attribute of the content.
    pub fn underlined(self: @This()) @This() {
        return self.setAttribute(.Underlined);
    }

    /// Sets the slow blink attribute of the content.
    pub fn slowBlink(self: @This()) @This() {
        return self.setAttribute(.SlowBlink);
    }

    /// Sets the rapid blink attribute of the content.
    pub fn rapidBlink(self: @This()) @This() {
        return self.setAttribute(.RapidBlink);
    }

    /// Sets the reverse attribute of the content.
    pub fn reverse(self: @This()) @This() {
        return self.setAttribute(.Reverse);
    }

    /// Sets the hidden attribute of the content.
    pub fn hidden(self: @This()) @This() {
        return self.setAttribute(.Hidden);
    }

    /// Sets the crossed out attribute of the content.
    pub fn crossedOut(self: @This()) @This() {
        return self.setAttribute(.CrossedOut);
    }

    /// Sets the fraktur attribute of the content.
    pub fn fraktur(self: @This()) @This() {
        return self.setAttribute(.Fraktur);
    }

    /// Sets the no bold attribute of the content.
    pub fn noBold(self: @This()) @This() {
        return self.setAttribute(.NoBold);
    }

    /// Sets the normal intensity attribute of the content.
    pub fn normalIntensity(self: @This()) @This() {
        return self.setAttribute(.NormalIntensity);
    }

    /// Sets the no italic attribute of the content.
    pub fn noItalic(self: @This()) @This() {
        return self.setAttribute(.NoItalic);
    }

    /// Sets the no underline attribute of the content.
    pub fn noUnderline(self: @This()) @This() {
        return self.setAttribute(.NoUnderline);
    }

    /// Sets the no blink attribute of the content.
    pub fn noBlink(self: @This()) @This() {
        return self.setAttribute(.NoBlink);
    }

    /// Sets the no reverse attribute of the content.
    pub fn noReverse(self: @This()) @This() {
        return self.setAttribute(.NoReverse);
    }

    /// Sets the no hidden attribute of the content.
    pub fn noHidden(self: @This()) @This() {
        return self.setAttribute(.NoHidden);
    }

    /// Sets the not crossed out attribute of the content.
    pub fn notCrossedOut(self: @This()) @This() {
        return self.setAttribute(.NotCrossedOut);
    }

    /// Sets the framed attribute of the content.
    pub fn framed(self: @This()) @This() {
        return self.setAttribute(.Framed);
    }

    /// Sets the encircled attribute of the content.
    pub fn encircled(self: @This()) @This() {
        return self.setAttribute(.Encircled);
    }

    /// Sets the overlined attribute of the content.
    pub fn overlined(self: @This()) @This() {
        return self.setAttribute(.Overlined);
    }

    /// Sets the not framed or encircled attribute of the content.
    pub fn notFramedOrEncircled(self: @This()) @This() {
        return self.setAttribute(.NotFramedOrEncircled);
    }

    /// Sets the not overlined attribute of the content.
    pub fn notOverlined(self: @This()) @This() {
        return self.setAttribute(.NotOverlined);
    }

    /// Sets the reset attribute of the content.
    pub fn reset(self: @This()) @This() {
        return self.setAttribute(.Reset);
    }

    /// Sets the given attribute of the content.
    pub fn setAttribute(self: @This(), attribute: Attribute) @This() {
        var new_style = self.style;
        new_style.attributes.set(attribute);

        return StyledContent{
            .content = self.content,
            .style = new_style,
        };
    }

    /// Unsets the given attribute of the content.
    pub fn unsetAttribute(self: @This(), attribute: Attribute) @This() {
        var new_style = self.style;
        new_style.attributes.unset(attribute);

        return StyledContent{
            .content = self.content,
            .style = new_style,
        };
    }
};

pub fn new(content: []const u8) StyledContent {
    return StyledContent{
        .content = content,
        .style = ContentStyle{},
    };
}

pub fn printStyled(fd: posix.fd_t, styled_content: StyledContent) !void {
    var reset_bg = false;
    var reset_fg = false;
    var reset = false;

    if (styled_content.style.bg) |bg| {
        try setBackgroundColor(fd, bg);
        reset_bg = true;
    }
    if (styled_content.style.fg) |fg| {
        try setForegroundColor(fd, fg);
        reset_fg = true;
    }
    if (!styled_content.style.attributes.isEmpty()) {
        try setAttributes(fd, styled_content.style.attributes);
        reset = true;
    }

    _ = try posix.write(fd, styled_content.content);

    if (reset) {
        // resetting the colors will also reset the attributes.
        try resetColor(fd);
        return;
    }
    if (reset_bg) {
        try setBackgroundColor(fd, .Reset);
    }
    if (reset_fg) {
        try setForegroundColor(fd, .Reset);
    }
}

pub fn print(fd: posix.fd_t, content: []const u8) !void {
    _ = try posix.write(fd, content);
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

pub fn setColors(fd: posix.fd_t, colors: Colors) !void {
    if (colors.fg) |fg| {
        setForegroundColor(fd, fg);
    }

    if (colors.bg) |bg| {
        setBackgroundColor(fd, bg);
    }
}

pub fn setAttribute(fd: posix.fd_t, attribute: Attribute) !void {
    const handle = ansi.FileDesc.init(fd);
    try ansi.csi(handle, "{}m", .{attribute.sgr()});
}

pub fn setAttributes(fd: posix.fd_t, attributes: ContentAttributes) !void {
    for (Attribute.iter()) |attribute| {
        if (attributes.has(attribute)) {
            try setAttribute(fd, attribute);
        }
    }
}

pub fn setStyle(fd: posix.fd_t, content_style: ContentStyle) !void {
    if (content_style.bg) |bg| {
        try setBackgroundColor(fd, bg);
    }
    if (content_style.fg) |fg| {
        try setForegroundColor(fd, fg);
    }
    if (!content_style.attributes.isEmpty()) {
        try setAttributes(fd, content_style.attributes);
    }
}

pub fn resetColor(fd: posix.fd_t) !void {
    const handle = ansi.FileDesc.init(fd);
    try ansi.csi(handle, "0m", .{});
}
