const std = @import("std");

pub const PollTimeout = struct {
    start: std.time.Instant,
    duration: u32,

    pub fn new(duration_ms: u32) @This() {
        return @This(){
            .start = std.time.Instant.now() catch unreachable,
            .duration = duration_ms,
        };
    }

    pub fn leftover(self: @This()) u32 {
        const now = std.time.Instant.now() catch unreachable;
        const elapsed = now.since(self.start) * std.time.ns_per_ms;
        if (elapsed >= self.duration) return 0;
        return self.duration - @as(u32, @intCast(elapsed));
    }
};
