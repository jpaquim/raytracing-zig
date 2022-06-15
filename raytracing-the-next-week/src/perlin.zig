const std = @import("std");
const Allocator = std.mem.Allocator;

const rtweekend = @import("./rtweekend.zig");
const randomDouble = rtweekend.randomDouble;
const randomInt = rtweekend.randomInt;

const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;

pub const Perlin = struct {
    const point_count = 256;

    ranfloat: []f64,
    perm_x: []i32,
    perm_y: []i32,
    perm_z: []i32,

    pub fn init(allocator: Allocator) !Perlin {
        const ranfloat = try allocator.alloc(f64, point_count);
        for (ranfloat) |*entry| {
            entry.* = randomDouble();
        }
        return Perlin{
            .ranfloat = ranfloat,
            .perm_x = try perlinGeneratePerm(allocator),
            .perm_y = try perlinGeneratePerm(allocator),
            .perm_z = try perlinGeneratePerm(allocator),
        };
    }

    pub fn deinit(self: *Perlin, allocator: Allocator) void {
        allocator.free(self.ranfloat);
        allocator.free(self.perm_x);
        allocator.free(self.perm_y);
        allocator.free(self.perm_z);
    }

    pub fn noise(self: Perlin, p: Point3) f64 {
        const i = @floatToInt(i32, 4 * p.x()) & 255;
        const j = @floatToInt(i32, 4 * p.y()) & 255;
        const k = @floatToInt(i32, 4 * p.z()) & 255;

        return self.ranfloat[@intCast(usize, self.perm_x[@intCast(usize, i)] ^ self.perm_y[@intCast(usize, j)] ^ self.perm_z[@intCast(usize, k)])];
    }

    fn perlinGeneratePerm(allocator: Allocator) ![]i32 {
        const p = try allocator.alloc(i32, point_count);

        for (p) |*point, index| {
            point.* = @intCast(i32, index);
        }

        permute(p, point_count);

        return p;
    }

    fn permute(p: []i32, n: usize) void {
        var i: usize = n;
        while (i > 0) {
            i -= 1;
            const target = randomInt(0, i);
            const tmp = p[i];
            p[i] = p[target];
            p[target] = tmp;
        }
    }
};
