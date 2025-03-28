const std = @import("std");
const quix = @import("quix");

pub fn main() !void {
    try quix.terminal.enableRawMode();
    try quix.terminal.enterAlternateScreen();

    try quix.cursor.moveTo(0, 1);
    const title = quix.style.new(" QUIX ")
        .background(.DarkRed)
        .foreground(.White)
        .bold();
    try quix.style.printStyled(title);

    try quix.cursor.moveTo(0, 3);

    try quix.style.print("Press ");
    const quit_char = quix.style.new("`q`").foreground(.Magenta);
    try quix.style.printStyled(quit_char);
    try quix.style.print(" to exit this example.");

    var line: u16 = 5;
    while (true) {
        try quix.cursor.moveTo(0, line);
        try quix.terminal.clear(.CurrentLine);

        const event = try quix.event.read();
        switch (event) {
            .KeyEvent => |key| {
                if (key.code == 'q') break;

                if (line > 10) {
                    line = 5;
                    try quix.cursor.moveTo(0, 5);
                    try quix.terminal.clear(.FromCursorDown);
                }

                try quix.style.print("code: ");

                var key_code: [4]u8 = undefined;
                const key_utf8 = try key.toUtf8(&key_code);
                const code = quix.style.new(key_utf8).foreground(.Yellow);
                try quix.style.printStyled(code);

                try quix.style.print(" kind: ");
                const kind = quix.style.new(key.kind.toString()).foreground(.Yellow);
                try quix.style.printStyled(kind);

                try quix.style.print(" event: ");
                const event_kind = quix.style.new(key.event_kind.toString()).foreground(.Yellow);
                try quix.style.printStyled(event_kind);

                line += 1;
            },
            else => continue,
        }
    }

    try quix.terminal.exitAlternateScreen();
    try quix.terminal.disableRawMode();
}
