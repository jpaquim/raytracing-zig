const std = @import("std");

const randomDouble2 = @import("./rtweekend.zig").randomDouble2;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    var inside_circle: usize = 0;
    var runs: usize = 0;
    while (true) {
        runs += 1;
        const x = randomDouble2(-1, 1);
        const y = randomDouble2(-1, 1);
        if (x * x + y * y < 1)
            inside_circle += 1;

        if (runs % 100000 == 0)
            try stdout.print("Estimate of PI = {:.12}\n", .{4 * @intToFloat(f64, inside_circle) / @intToFloat(f64, runs)});
    }
}
