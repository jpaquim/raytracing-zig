const std = @import("std");

const randomDouble = @import("./rtweekend.zig").randomDouble;
const randomDouble2 = @import("./rtweekend.zig").randomDouble2;

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const sqrt_N = 10000;
    var inside_circle: usize = 0;
    var inside_circle_stratified: usize = 0;
    var i: usize = 0;
    while (i < sqrt_N) : (i += 1) {
        var j: usize = 0;
        while (j < sqrt_N) : (j += 1) {
            var x = randomDouble2(-1, 1);
            var y = randomDouble2(-1, 1);
            if (x * x + y * y < 1)
                inside_circle += 1;
            x = 2 * ((@intToFloat(f64, i) + randomDouble()) / sqrt_N) - 1;
            y = 2 * ((@intToFloat(f64, j) + randomDouble()) / sqrt_N) - 1;
            if (x * x + y * y < 1)
                inside_circle_stratified += 1;
        }
    }

    const N = @intToFloat(f64, sqrt_N) * sqrt_N;
    try stdout.print("Regular    Estimate of PI = {:.12}\n", .{4 * @intToFloat(f64, inside_circle) / N});
    try stdout.print("Stratified Estimate of PI = {:.12}\n", .{4 * @intToFloat(f64, inside_circle_stratified) / N});
    // try stdout.print("Regular    Estimate of PI = {:.12}\n", .{4 * @intToFloat(f64, inside_circle) / @intToFloat(f64, (sqrt_N * sqrt_N))});
    // try stdout.print("Stratified Estimate of PI = {:.12}\n", .{4 * @intToFloat(f64, inside_circle_stratified) / @intToFloat(f64, (sqrt_N * sqrt_N))});
}
