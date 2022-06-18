const std = @import("std");
const sqrt = std.math.sqrt;

const rtweekend = @import("./rtweekend.zig");
const pi = rtweekend.pi;
const randomDouble = rtweekend.randomDouble;

const vec3 = @import("./vec3.zig");
const Vec3 = vec3.Vec3;
const randomUnitVector = vec3.randomUnitVector;

fn pdf(p: Vec3) f64 {
    _ = p;
    return 1 / (4 * pi);
}

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    var i: usize = 0;
    try stdout.print("X,Y,Z\n", .{});
    while (i < 200) : (i += 1) {
        const r1 = randomDouble();
        const r2 = randomDouble();
        const x = @cos(2 * pi * r1) * 2 * sqrt(r2 * (1 - r2));
        const y = @sin(2 * pi * r1) * 2 * sqrt(r2 * (1 - r2));
        const z = 1 - 2 * r2;
        try stdout.print("{},{},{}\n", .{ x, y, z });
    }
}
