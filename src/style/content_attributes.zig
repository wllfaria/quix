const Attribute = @import("attributes.zig").Attribute;

/// Represents every attribute a text can have at any time.
///
/// Check Attribute enum for a description of what each attribute does
/// individually
pub const ContentAttributes = packed struct {
    bold: bool = false,
    dim: bool = false,
    italic: bool = false,
    underlined: bool = false,
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
    _pad: u9 = 0,

    /// Returns a bitset representation of the attributes
    pub fn bytes(self: @This()) u32 {
        return @bitCast(self);
    }

    /// Sets the attribute.
    /// If it's already set, this does nothing.
    pub fn set(self: *@This(), attribute: Attribute) void {
        switch (attribute) {
            .Reset => self.* = ContentAttributes{},
            .Bold => self.bold = true,
            .Dim => self.dim = true,
            .Italic => self.italic = true,
            .Underlined => self.underlined = true,
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

    /// Unsets the attribute.
    /// If it's not set, this changes nothing.
    pub fn unset(self: *@This(), attribute: Attribute) void {
        switch (attribute) {
            .Reset => self.* = ContentAttributes{},
            .Bold => self.bold = false,
            .Dim => self.dim = false,
            .Italic => self.italic = false,
            .Underlined => self.underlined = false,
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

    /// Returns whether the attribute is set.
    pub fn has(self: *const @This(), attribute: Attribute) bool {
        // we shift 1 more to the left as Reset will be 0b1.
        return (self.bytes() << 1) & attribute.bytes() != 0;
    }

    /// Returns whether there is no attribute set.
    pub fn isEmpty(self: *const @This()) bool {
        return self.bytes() == 0;
    }
};
