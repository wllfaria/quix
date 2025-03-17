const std = @import("std");
const posix = std.posix;
const builtin = @import("builtin");
const terminal = @import("../terminal/terminal.zig");
const ansi_style = @import("ansi_style.zig");

const Attribute = @import("attributes.zig").Attribute;
const Color = @import("colors.zig").Color;
const ContentAttributes = @import("content_attributes.zig").ContentAttributes;
const StyledContent = @import("styled_content.zig").StyledContent;

const style_impl = switch (builtin.os.tag) {
    .linux, .macos => @import("ansi_style.zig"),
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
    return style_impl.printStyled(styled_content);
}

pub fn print(content: []const u8) !void {
    return style_impl.print(content);
}

pub fn setBackgroundColor(color: Color) !void {
    return style_impl.setBackgroundColor(color);
}

pub fn setForegroundColor(color: Color) !void {
    return style_impl.setForegroundColor(color);
}

pub fn setColors(colors: Colors) !void {
    return style_impl.setColors(colors);
}

pub fn setAttribute(attribute: Attribute) !void {
    return style_impl.setAttribute(attribute);
}

pub fn setAttributes(attributes: ContentAttributes) !void {
    return style_impl.setAttributes(attributes);
}

pub fn setStyle(content_style: ContentStyle) !void {
    return style_impl.setStyle(content_style);
}

pub fn resetColor() !void {
    return style_impl.resetColor();
}

test {
    std.testing.refAllDecls(@This());
}
