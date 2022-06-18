const std = @import("std");
const sqrt = std.math.sqrt;

const randomDouble = @import("./rtweekend.zig").randomDouble;
const randomDouble2 = @import("./rtweekend.zig").randomDouble2;

fn pdf(x: f64) f64 {
    return 0.5 * x;
}

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const N = 1000000;
    var sum: f64 = 0.0;

    var i: usize = 0;
    while (i < N) : (i += 1) {
        const x = sqrt(randomDouble2(0, 4));
        sum += x * x / pdf(x);
    }
    try stdout.print("I = {:.12}\n", .{sum / N});
}
