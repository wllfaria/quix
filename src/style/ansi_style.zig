const builtin = @import("builtin");

const Attribute = @import("attributes.zig").Attribute;
const Color = @import("colors.zig").Color;
const ContentAttributes = @import("content_attributes.zig").ContentAttributes;
const StyledContent = @import("styled_content.zig").StyledContent;
const Colors = @import("style.zig").Colors;
const ContentStyle = @import("style.zig").ContentStyle;

const os_impl = switch (builtin.os.tag) {
    .linux, .macos => @import("unix.zig"),
    .windows => @import("windows.zig"),
    else => @panic("TODO"),
};

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

    try os_impl.print(styled_content.content);

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
    return os_impl.print(content);
}

pub fn setBackgroundColor(color: Color) !void {
    var buffer: [16]u8 = undefined;
    const color_str = color.asStr(.Background, buffer[0..]);
    try os_impl.printAnsi("{s}m", .{color_str});
}

pub fn setForegroundColor(color: Color) !void {
    var buffer: [16]u8 = undefined;
    const color_str = color.asStr(.Foreground, buffer[0..]);
    try os_impl.printAnsi("{s}m", .{color_str});
}

pub fn setColors(colors: Colors) !void {
    if (colors.fg) |fg| try setForegroundColor(fg);
    if (colors.bg) |bg| try setBackgroundColor(bg);
}

pub fn setAttribute(attribute: Attribute) !void {
    try os_impl.printAnsi("{}m", .{attribute.sgr()});
}

pub fn setAttributes(attributes: ContentAttributes) !void {
    for (Attribute.iter()) |attribute| {
        if (attributes.has(attribute)) {
            try setAttribute(attribute);
        }
    }
}

pub fn setStyle(content_style: ContentStyle) !void {
    if (content_style.bg) |bg| try setBackgroundColor(bg);
    if (content_style.fg) |fg| try setForegroundColor(fg);

    if (!content_style.attributes.isEmpty()) {
        try setAttributes(content_style.attributes);
    }
}

pub fn resetColor() !void {
    try os_impl.printAnsi("0m", .{});
}
