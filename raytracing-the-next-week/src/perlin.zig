const std = @import("std");
const Allocator = std.mem.Allocator;

const rtweekend = @import("./rtweekend.zig");
const randomDouble = rtweekend.randomDouble;
const randomInt = rtweekend.randomInt;

const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;
const unitVector = vec3.unitVector;

pub const Perlin = struct {
    const point_count = 256;

    ranvec: []Vec3,
    perm_x: []i32,
    perm_y: []i32,
    perm_z: []i32,

    pub fn init(allocator: Allocator) !Perlin {
        const ranvec = try allocator.alloc(Vec3, point_count);
        for (ranvec) |*entry| {
            entry.* = unitVector(Vec3.random2(-1, 1));
        }
        return Perlin{
            .ranvec = ranvec,
            .perm_x = try perlinGeneratePerm(allocator),
            .perm_y = try perlinGeneratePerm(allocator),
            .perm_z = try perlinGeneratePerm(allocator),
        };
    }

    pub fn deinit(self: *Perlin, allocator: Allocator) void {
        allocator.free(self.ranvec);
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
        var c: [2][2][2]Vec3 = undefined;

        var di: usize = 0;
        while (di < 2) : (di += 1) {
            var dj: usize = 0;
            while (dj < 2) : (dj += 1) {
                var dk: usize = 0;
                while (dk < 2) : (dk += 1) {
                    c[di][dj][dk] = self.ranvec[@intCast(usize, self.perm_x[(@intCast(usize, i) + di) & 255] ^ self.perm_y[(@intCast(usize, j) + dj) & 255] ^ self.perm_z[(@intCast(usize, k) + dk) & 255])];
                }
            }
        }

        return perlinInterp(c, u, v, w);
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

    fn perlinInterp(c: [2][2][2]Vec3, u: f64, v: f64, w: f64) f64 {
        const uu = u * u * (3 - 2 * u);
        const vv = v * v * (3 - 2 * v);
        const ww = w * w * (3 - 2 * w);
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
                    const weight_v = Vec3.init(u - fi, v - fj, w - fk);
                    accum += (fi * uu + (1 - fi) * (1 - uu)) * (fj * vv + (1 - fj) * (1 - vv)) * (fk * ww + (1 - fk) * (1 - ww)) * dot(c[i][j][k], weight_v);
                }
            }
        }
        return accum;
    }
};
