const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

pub const Ray = struct {
    orig: Point3,
    dir: Vec3,

    pub fn init(orig: Point3, dir: Vec3) Ray {
        return .{ .orig = orig, .dir = dir };
    }

    pub fn origin(self: Ray) Point3 {
        return self.orig;
    }

    pub fn direction(self: Ray) Vec3 {
        return self.dir;
    }

    pub fn at(self: Ray, t: f64) Point3 {
        return self.orig.add(self.dir.multScalar(t));
    }
};
