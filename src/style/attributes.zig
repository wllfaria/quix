const std = @import("std");

/// Represents an text attribute.
///
/// * Only UNIX and Windows 10 terminals support attributes.
/// * Not all terminals support all attributes.
pub const Attribute = enum(u5) {
    /// All attributes become turned off.
    Reset,
    /// Increases the text intensity.
    Bold,
    /// Decreases the text intensity.
    Dim,
    /// Emphasizes the text.
    Italic,
    /// Underlines the text.
    Underlined,
    /// Makes the text blinking (< 150 times per minute).
    SlowBlink,
    /// Makes the text blinking (>= times 150 per minute).
    RapidBlink,
    /// Swaps background and foreground colors.
    Reverse,
    /// Hides the text (also known as Conceal).
    Hidden,
    /// Crosses the text.
    CrossedOut,
    /// Sets the [Fraktur](https://en.wikipedia.org/wiki/Fraktur) typeface, this
    /// is not widely supported.
    Fraktur,
    /// Turns off Bold attribute. This is inconsistent, prefer using
    /// NormalIntensity.
    NoBold,
    /// Switches text to normal intensity (no bold or italic).
    NormalIntensity,
    /// Turns off the italic attribute.
    NoItalic,
    /// Turns off the underlined attribute.
    NoUnderline,
    /// Turns off the text blinkin (both SlowBlink or RapidBlink).
    NoBlink,
    /// Turns off the reverse attribute.
    NoReverse,
    /// Turns off the hidden attribute.
    NoHidden,
    /// Turns off the crossed out attribute.
    NotCrossedOut,
    /// Makes the text framed.
    Framed,
    /// Makes the text encircled.
    Encircled,
    /// Draws a line at the top of the text.
    Overlined,
    /// Turns off the frame and encircled attributes.
    NotFramedOrEncircled,
    /// Turns off the overlined attribute.
    NotOverlined,

    /// SGR stands for select graphic rendition. Which changes how text should be
    /// rendered on the terminal, read specific notes on each variant to
    /// understand better how they may be applied as some are inconsistent across
    /// terminal emulators. See <https://en.wikipedia.org/wiki/ANSI_escape_code#Select_Graphic_Rendition_parameters>
    pub fn sgr(self: @This()) u8 {
        return switch (self) {
            .Reset => 0,
            .Bold => 1,
            .Dim => 2,
            .Italic => 3,
            .Underlined => 4,
            .SlowBlink => 5,
            .RapidBlink => 6,
            .Reverse => 7,
            .Hidden => 8,
            .CrossedOut => 9,
            .Fraktur => 20,
            .NoBold => 21,
            .NormalIntensity => 22,
            .NoItalic => 23,
            .NoUnderline => 24,
            .NoBlink => 25,
            .NoReverse => 27,
            .NoHidden => 28,
            .NotCrossedOut => 29,
            .Framed => 51,
            .Encircled => 52,
            .Overlined => 53,
            .NotFramedOrEncircled => 54,
            .NotOverlined => 55,
        };
    }

    pub fn iter() []const Attribute {
        return &[_]Attribute{
            .Reset,
            .Bold,
            .Dim,
            .Italic,
            .Underlined,
            .SlowBlink,
            .RapidBlink,
            .Reverse,
            .Hidden,
            .CrossedOut,
            .Fraktur,
            .NoBold,
            .NormalIntensity,
            .NoItalic,
            .NoUnderline,
            .NoBlink,
            .NoReverse,
            .NoHidden,
            .NotCrossedOut,
            .Framed,
            .Encircled,
            .Overlined,
            .NotFramedOrEncircled,
            .NotOverlined,
        };
    }

    /// Returns attributes in a bitset format
    pub fn bytes(self: @This()) u32 {
        const mask: u32 = 1;
        return mask << @intFromEnum(self);
    }
};

test "attributes" {
    const ContentAttributes = @import("content_attributes.zig").ContentAttributes;
    var attributes = ContentAttributes{ .bold = true };
    try std.testing.expect(attributes.has(.Bold));
    attributes.set(.Italic);
    try std.testing.expect(attributes.has(.Italic));
    attributes.unset(.Italic);
    try std.testing.expect(!attributes.has(.Italic));
    attributes.unset(.Bold);
    try std.testing.expect(attributes.isEmpty());
}
