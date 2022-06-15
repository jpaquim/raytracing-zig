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
