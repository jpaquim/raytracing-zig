const std = @import("std");

const randomDouble2 = @import("./rtweekend.zig").randomDouble2;

pub fn main() anyerror!void {
    const N = 1000;
    var inside_circle: usize = 0;
    var i: usize = 0;
    while (i < N) : (i += 1) {
        const x = randomDouble2(-1, 1);
        const y = randomDouble2(-1, 1);
        if (x * x + y * y < 1)
            inside_circle += 1;
    }
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Estimate of PI = {:.12}\n", .{4 * @intToFloat(f64, inside_circle) / N});
}
