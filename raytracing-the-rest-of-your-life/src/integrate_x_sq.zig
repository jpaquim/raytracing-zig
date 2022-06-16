const std = @import("std");

const randomDouble = @import("./rtweekend.zig").randomDouble;
const randomDouble2 = @import("./rtweekend.zig").randomDouble2;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const N = 1000000;
    var sum: f64 = 0.0;

    var i: usize = 0;
    while (i < N) : (i += 1) {
        const x = randomDouble2(0, 2);
        sum += x * x;
    }
    try stdout.print("I = {:.12}\n", .{2 * sum / N});
}
