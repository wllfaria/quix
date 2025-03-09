const std = @import("std");

/// Represents a color in RGB format.
pub const RgbColor = struct {
    r: u8,
    g: u8,
    b: u8,
};

/// Represents terminal colors.
///
/// Almost every terminal have the following base 16 table of colors available
/// (including Windows 7 and 8).
///
/// | Light      | Dark          |
/// | ---------- | ------------- |
/// | `DarkGrey` | `Black`       |
/// | `Red`      | `DarkRed`     |
/// | `Green`    | `DarkGreen`   |
/// | `Yellow`   | `DarkYellow`  |
/// | `Blue`     | `DarkBlue`    |
/// | `Magenta`  | `DarkMagenta` |
/// | `Cyan`     | `DarkCyan`    |
/// | `White`    | `Grey`        |
///
/// most UNIX and Windows 10/11 terminals also support additional colors, as RGB
/// or 256 indexed Ansi values. Check variants below.
pub const Color = union(enum) {
    /// Resets terminal colors.
    Reset,
    /// Black terminal color.
    Black,
    /// Dark grey terminal color.
    DarkGrey,
    /// Bright red terminal color.
    Red,
    /// Dark red terminal color.
    DarkRed,
    /// Bright green terminal color.
    Green,
    /// Dark green terminal color.
    DarkGreen,
    /// Bright yellow terminal color.
    Yellow,
    /// Dark yellow terminal color.
    DarkYellow,
    /// Bright blue terminal color.
    Blue,
    /// Dark blue terminal color.
    DarkBlue,
    /// Bright magenta terminal color.
    Magenta,
    /// Dark magenta terminal color.
    DarkMagenta,
    /// Bright cyan terminal color.
    Cyan,
    /// Dark cyan terminal color.
    DarkCyan,
    /// White terminal color.
    White,
    /// Grey terminal color.
    Grey,
    /// An RGB color. See [RGB color model](https://en.wikipedia.org/wiki/RGB_color_model)
    /// for more info.
    ///
    /// Mostly supported on UNIX and Windows 10/11 terminals.
    Rgb: RgbColor,
    /// An ANSI color, 256 indexed. See [256 colors - cheat sheet](https://jonasjacek.github.io/colors/)
    /// for more info.
    ///
    /// Mostly supported on UNIX and Windows 10/11 terminals.
    AnsiValue: u8,

    /// Formats a `Color` as its ansi string representation.
    /// This function writes the ANSI escape sequence for the given `Color` into
    /// the provided buffer. The buffer must be at least 16 bytes long to
    /// accommodate the longest possible ANSI sequence.
    /// # Examples
    /// - Reset foreground: "39" (2 bytes)
    /// - RGB white foreground: "38;2;255;255;255" (16 bytes)
    pub fn asStr(self: @This(), kind: ColoredSection, buffer: []u8) []const u8 {
        std.debug.assert(buffer.len >= 16);

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

/// Represents which section of the text is being colored.
pub const ColoredSection = enum(u2) {
    Foreground,
    Background,
    Underline,
};
