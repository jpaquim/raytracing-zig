const std = @import("std");
const sqrt = std.math.sqrt;

const rtweekend = @import("./rtweekend.zig");
const pi = rtweekend.pi;
const randomDouble = rtweekend.randomDouble;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const N = 1000000;
    var sum: f64 = 0.0;
    var i: usize = 0;
    while (i < N) : (i += 1) {
        // const r1 = randomDouble();
        const r2 = randomDouble();
        // const x = @cos(2 * pi * r1) * 2 * sqrt(r2 * (1 - r2));
        // const y = @sin(2 * pi * r1) * 2 * sqrt(r2 * (1 - r2));
        const z = 1 - r2;
        sum += z * z * z / (1 / (2 * pi));
    }
    try stdout.print("Pi/2     = {:.12}\n", .{pi / 2.0});
    try stdout.print("Estimate = {:.12}\n", .{sum / N});
}
