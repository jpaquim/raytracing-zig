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
        const u = p.x() - @floor(p.x());
        const v = p.y() - @floor(p.y());
        const w = p.z() - @floor(p.z());

        const i = @floatToInt(i32, @floor(p.x()));
        const j = @floatToInt(i32, @floor(p.y()));
        const k = @floatToInt(i32, @floor(p.z()));
        var c: [2][2][2]f64 = undefined;

        var di: usize = 0;
        while (di < 2) : (di += 1) {
            var dj: usize = 0;
            while (dj < 2) : (dj += 1) {
                var dk: usize = 0;
                while (dk < 2) : (dk += 1) {
                    c[di][dj][dk] = self.ranfloat[@intCast(usize, self.perm_x[(@intCast(usize, i) + di) & 255] ^ self.perm_y[(@intCast(usize, j) + dj) & 255] ^ self.perm_z[(@intCast(usize, k) + dk) & 255])];
                }
            }
        }

        return trilinearInterp(c, u, v, w);
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

    fn trilinearInterp(c: [2][2][2]f64, u: f64, v: f64, w: f64) f64 {
        var accum: f64 = 0.0;

        var i: usize = 0;
        while (i < 2) : (i += 1) {
            var j: usize = 0;
            while (j < 2) : (j += 1) {
                var k: usize = 0;
                while (k < 2) : (k += 1) {
                    const fi = @intToFloat(f64, i);
                    const fj = @intToFloat(f64, j);
                    const fk = @intToFloat(f64, k);
                    accum += (fi * u + (1 - fi) * (1 - u)) * (fj * v + (1 - fj) * (1 - v)) * (fk * w + (1 - fk) * (1 - w)) * c[i][j][k];
                }
            }
        }

        return accum;
    }
};
