const std = @import("std");
const Allocator = std.mem.Allocator;

const Perlin = @import("./perlin.zig").Perlin;

const rtweekend = @import("./rtweekend.zig");
const clamp = rtweekend.clamp;
const makePtr = rtweekend.makePtr;

const vec3 = @import("./vec3.zig");
const Color = vec3.Color;
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

const stb = @cImport({
    @cDefine("STBI_ONLY_JPEG", "");
    @cInclude("stb_image.h");
});

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

    pub fn initColor(allocator: Allocator, c1: Color, c2: Color) !CheckerTexture {
        const t1 = try makePtr(allocator, SolidColor, .{c1});
        const t2 = try makePtr(allocator, SolidColor, .{c2});
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
    scale: f64,

    pub fn init(allocator: Allocator, sc: f64) !NoiseTexture {
        return NoiseTexture{
            .texture = .{ .valueFn = value },
            .noise = try Perlin.init(allocator),
            .scale = sc,
        };
    }

    pub fn deinit(self: *NoiseTexture, allocator: Allocator) void {
        self.noise.deinit(allocator);
    }

    pub fn value(texture: *const Texture, u: f64, v: f64, p: Point3) Color {
        _ = u;
        _ = v;
        const self = @fieldParentPtr(NoiseTexture, "texture", texture);
        return Color.init(1, 1, 1).multScalar(0.5 * (1 + @sin(self.scale * p.z() + 10 * self.noise.turb(p, null))));
        // return Color.init(1, 1, 1).multScalar(self.noise.turb(p.multScalar(self.scale), null));
        // return Color.init(1, 1, 1).multScalar(0.5 * (1 + self.noise.noise(p.multScalar(self.scale))));
    }
};

pub const ImageTexture = struct {
    const bytes_per_pixel = 3;

    texture: Texture,

    data: ?[]u8 = null,
    width: usize = 0,
    height: usize = 0,
    bytes_per_scanline: usize = 0,

    pub fn init(allocator: Allocator, filename: []const u8) !ImageTexture {
        var self = ImageTexture{ .texture = .{ .valueFn = value } };

        var filename_c = try allocator.dupeZ(u8, filename);
        defer allocator.free(filename_c);

        var components_per_pixel: c_int = bytes_per_pixel;
        var w: c_int = 0;
        var h: c_int = 0;
        const data = stb.stbi_load(filename_c.ptr, &w, &h, &components_per_pixel, components_per_pixel);

        if (data == null) {
            std.io.getStdErr().writer().print("ERROR: Could not load texture image file '{s}'", .{filename}) catch std.process.exit(1);
            self.width = 0;
            self.height = 0;
        } else {
            self.data = data[0 .. self.width * self.height * @intCast(usize, components_per_pixel)];
            self.width = @intCast(usize, w);
            self.height = @intCast(usize, h);
        }

        self.bytes_per_scanline = bytes_per_pixel * self.width;

        return self;
    }

    pub fn deinit(self: *ImageTexture) void {
        std.heap.c_allocator.free(self.data);
    }

    pub fn value(texture: *const Texture, u: f64, v: f64, p: Point3) Color {
        _ = p;
        const self = @fieldParentPtr(ImageTexture, "texture", texture);
        if (self.data == null)
            return Color.init(0, 1, 1);
        const u_c = clamp(u, 0.0, 1.0);
        const v_c = 1.0 - clamp(v, 0.0, 1.0);

        var i = @floatToInt(usize, u_c * @intToFloat(f64, self.width));
        var j = @floatToInt(usize, v_c * @intToFloat(f64, self.height));

        if (i >= self.width) i = self.width - 1;
        if (j >= self.height) i = self.height - 1;

        const color_scale = 1.0 / 255.0;
        const pixel = @ptrCast([*]u8, self.data.?) + j * self.bytes_per_scanline + i * bytes_per_pixel;

        return Color.init(color_scale * @intToFloat(f64, pixel[0]), color_scale * @intToFloat(f64, pixel[1]), color_scale * @intToFloat(f64, pixel[2]));
    }
};
