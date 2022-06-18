const std = @import("std");
const sqrt = std.math.sqrt;

const rtweekend = @import("./rtweekend.zig");
const pi = rtweekend.pi;
const randomDouble = rtweekend.randomDouble;

const vec3 = @import("./vec3.zig");
const Vec3 = vec3.Vec3;
const randomUnitVector = vec3.randomUnitVector;

fn randomCosineDirection() Vec3 {
    const r1 = randomDouble();
    const r2 = randomDouble();
    const z = sqrt(1 - r2);

    const phi = 2 * pi * r1;
    const x = @cos(phi) * 2 * sqrt(r2);
    const y = @sin(phi) * 2 * sqrt(r2);

    return Vec3.init(x, y, z);
}

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const N = 1000000;
    var sum: f64 = 0.0;
    var i: usize = 0;
    while (i < N) : (i += 1) {
        const v = randomCosineDirection();
        sum += v.z() * v.z() * v.z() / (v.z() / pi);
    }
    try stdout.print("Pi/2     = {:.12}\n", .{pi / 2.0});
    try stdout.print("Estimate = {:.12}\n", .{sum / N});
}
