const std = @import("std");
const quix = @import("quix");

pub fn main() !void {
    const handle = std.posix.STDIN_FILENO;

    try quix.terminal.enableRawMode(handle);
    try quix.terminal.enterAlternateScreen(handle);

    try quix.cursor.moveTo(handle, 0, 1);
    const title = quix.style.new(" QUIX ")
        .background(.DarkRed)
        .foreground(.White)
        .bold();
    try quix.style.printStyled(handle, title);

    try quix.cursor.moveTo(handle, 0, 3);

    try quix.style.print(handle, "Press ");
    const quit_char = quix.style.new("`q`").foreground(.Magenta);
    try quix.style.printStyled(handle, quit_char);
    try quix.style.print(handle, " to exit this example.");

    var line: u16 = 5;
    while (true) {
        try quix.cursor.moveTo(handle, 0, line);

        const event = try quix.event.read(handle);
        switch (event) {
            .KeyEvent => |key| {
                if (key.code == 'q') {
                    break;
                }

                if (line > 10) {
                    line = 5;
                    try quix.cursor.moveTo(handle, 0, 5);
                    try quix.terminal.clear(handle, .FromCursorDown);
                }

                try quix.style.print(handle, "code: ");

                const code = quix.style.new(&.{key.code}).foreground(.Yellow);
                try quix.style.printStyled(handle, code);

                try quix.style.print(handle, " kind: ");
                const kind = quix.style.new(key.kind.toString()).foreground(.Yellow);
                try quix.style.printStyled(handle, kind);

                line += 1;
            },
            else => continue,
        }
    }

    try quix.terminal.exitAlternateScreen(handle);
    try quix.terminal.disableRawMode(handle);
}
