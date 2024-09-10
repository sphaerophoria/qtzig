const std = @import("std");
const c = @cImport({
    @cInclude("gui.h");
});

fn incrementThread() void {
    while (true) {
        std.time.sleep(1 * std.time.ns_per_s);
        c.incrementValue();
    }
}

pub fn main() !void {
    _ = try std.Thread.spawn(.{}, incrementThread, .{});
    _ = c.runGui();
}
