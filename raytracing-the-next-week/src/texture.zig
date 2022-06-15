const std = @import("std");
const Allocator = std.mem.Allocator;

const Perlin = @import("./perlin.zig").Perlin;

const vec3 = @import("./vec3.zig");
const Color = vec3.Color;
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

pub const Texture = struct {
    valueFn: fn (self: *const Texture, u: f64, v: f64, p: Point3) Color,

    pub fn value(self: *const Texture, u: f64, v: f64, p: Point3) Color {
        return self.valueFn(self, u, v, p);
    }
};

pub const SolidColor = struct {
    texture: Texture,

    color_value: Color,

    pub fn init(c: Color) SolidColor {
        return .{
            .texture = .{ .valueFn = value },
            .color_value = c,
        };
    }

    pub fn initRGB(red: f64, green: f64, blue: f64) SolidColor {
        return SolidColor.init(Color.init(red, green, blue));
    }

    pub fn value(texture: *const Texture, u: f64, v: f64, p: Point3) Color {
        _ = u;
        _ = v;
        _ = p;
        const self = @fieldParentPtr(SolidColor, "texture", texture);
        return self.color_value;
    }
};

pub const CheckerTexture = struct {
    texture: Texture,

    odd: *Texture,
    even: *Texture,

    pub fn init(even: *Texture, odd: *Texture) CheckerTexture {
        return .{
            .texture = .{ .valueFn = value },
            .even = even,
            .odd = odd,
        };
    }

    pub fn initColors(allocator: Allocator, c1: Color, c2: Color) !CheckerTexture {
        var t1 = try allocator.create(SolidColor);
        t1.* = SolidColor.init(c1);
        var t2 = try allocator.create(SolidColor);
        t2.* = SolidColor.init(c2);
        return CheckerTexture.init(&t1.texture, &t2.texture);
    }

    pub fn value(texture: *const Texture, u: f64, v: f64, p: Point3) Color {
        const self = @fieldParentPtr(CheckerTexture, "texture", texture);
        const sines = @sin(10 * p.x()) * @sin(10 * p.y()) * @sin(10 * p.z());
        if (sines < 0) {
            return self.odd.value(u, v, p);
        } else return self.even.value(u, v, p);
    }
};

pub const NoiseTexture = struct {
    texture: Texture,

    noise: Perlin,

    pub fn init(allocator: Allocator) !NoiseTexture {
        return NoiseTexture{
            .texture = .{ .valueFn = value },
            .noise = try Perlin.init(allocator),
        };
    }

    pub fn deinit(self: *NoiseTexture, allocator: Allocator) void {
        self.noise.deinit(allocator);
    }

    pub fn value(texture: *const Texture, u: f64, v: f64, p: Point3) Color {
        _ = u;
        _ = v;
        const self = @fieldParentPtr(NoiseTexture, "texture", texture);
        return Color.init(1, 1, 1).multScalar(self.noise.noise(p));
    }
};
