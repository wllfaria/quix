const attributes = @import("attributes.zig");
const Attribute = attributes.Attribute;
const colors = @import("colors.zig");
const Color = colors.Color;
const style = @import("style.zig");
const ContentStyle = style.ContentStyle;

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
