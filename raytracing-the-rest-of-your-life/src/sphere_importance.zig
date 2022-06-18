const std = @import("std");
const pow = std.math.pow;
const sqrt = std.math.sqrt;

const pi = @import("./rtweekend.zig").pi;

const vec3 = @import("./vec3.zig");
const Vec3 = vec3.Vec3;
const randomUnitVector = vec3.randomUnitVector;

fn pdf(p: Vec3) f64 {
    _ = p;
    return 1 / (4 * pi);
}

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const N = 1000000;
    var sum: f64 = 0.0;
    var i: usize = 0;
    while (i < N) : (i += 1) {
        const d = randomUnitVector();
        const cosine_squared = d.z() * d.z();
        sum += cosine_squared / pdf(d);
    }
    try stdout.print("I = {:.12}\n", .{sum / N});
}
