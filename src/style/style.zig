const std = @import("std");
const posix = std.posix;
const builtin = @import("builtin");

pub const Attribute = @import("attributes.zig").Attribute;
pub const Color = @import("colors.zig").Color;
pub const ContentAttributes = @import("content_attributes.zig").ContentAttributes;
const StyledContent = @import("styled_content.zig").StyledContent;

const style_impl = switch (builtin.os.tag) {
    .linux, .macos => @import("unix.zig"),
    .windows => @import("windows.zig"),
    else => @panic("TODO"),
};

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

pub fn new(content: []const u8) StyledContent {
    return StyledContent{
        .content = content,
        .style = ContentStyle{},
    };
}

pub fn printStyled(styled_content: StyledContent) !void {
    var reset_bg = false;
    var reset_fg = false;
    var reset = false;

    if (styled_content.style.bg) |bg| {
        try setBackgroundColor(bg);
        reset_bg = true;
    }
    if (styled_content.style.fg) |fg| {
        try setForegroundColor(fg);
        reset_fg = true;
    }
    if (!styled_content.style.attributes.isEmpty()) {
        try setAttributes(styled_content.style.attributes);
        reset = true;
    }

    try style_impl.print(styled_content.content);

    if (reset) {
        // resetting the colors will also reset the attributes.
        try resetColor();
        return;
    }
    if (reset_bg) {
        try setBackgroundColor(.Reset);
    }
    if (reset_fg) {
        try setForegroundColor(.Reset);
    }
}

pub fn print(content: []const u8) !void {
    try style_impl.print(content);
}

pub fn setBackgroundColor(color: Color) !void {
    var buffer: [16]u8 = undefined;
    const color_str = color.asStr(.Background, buffer[0..]);
    try style_impl.printAnsi("{s}m", .{color_str});
}

pub fn setForegroundColor(color: Color) !void {
    var buffer: [16]u8 = undefined;
    const color_str = color.asStr(.Foreground, buffer[0..]);
    try style_impl.printAnsi("{s}m", .{color_str});
}

pub fn setColors(colors: Colors) !void {
    if (colors.fg) |fg| {
        try setForegroundColor(fg);
    }

    if (colors.bg) |bg| {
        try setBackgroundColor(bg);
    }
}

pub fn setAttribute(attribute: Attribute) !void {
    try style_impl.printAnsi("{}m", .{attribute.sgr()});
}

pub fn setAttributes(attributes: ContentAttributes) !void {
    for (Attribute.iter()) |attribute| {
        if (attributes.has(attribute)) {
            try setAttribute(attribute);
        }
    }
}

pub fn setStyle(content_style: ContentStyle) !void {
    if (content_style.bg) |bg| {
        try setBackgroundColor(bg);
    }
    if (content_style.fg) |fg| {
        try setForegroundColor(fg);
    }
    if (!content_style.attributes.isEmpty()) {
        try setAttributes(content_style.attributes);
    }
}

pub fn resetColor() !void {
    try style_impl.printAnsi("0m", .{});
}

test {
    std.testing.refAllDecls(@This());
}
