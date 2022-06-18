const std = @import("std");
const pow = std.math.pow;
const sqrt = std.math.sqrt;

const randomDouble2 = @import("./rtweekend.zig").randomDouble2;

fn pdf(x: f64) f64 {
    return 3 * x * x / 8;
}

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const N = 1;
    var sum: f64 = 0.0;

    var i: usize = 0;
    while (i < N) : (i += 1) {
        const x = pow(f64, randomDouble2(0, 8), 1 / 3);
        sum += x * x / pdf(x);
    }
    try stdout.print("I = {:.12}\n", .{sum / N});
}
