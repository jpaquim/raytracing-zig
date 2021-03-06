const Material = @import("./material.zig").Material;
const Ray = @import("./ray.zig").Ray;
const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;

pub const HitRecord = struct {
    p: Point3,
    normal: Vec3,
    mat_ptr: *Material,
    t: f64,

    front_face: bool,

    pub fn setFaceNormal(self: *HitRecord, r: Ray, outward_normal: Vec3) void {
        self.front_face = dot(r.direction(), outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.negate();
    }
};

pub const Hittable = struct {
    hitFn: fn (self: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool,

    pub fn hit(self: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        return self.hitFn(self, r, t_min, t_max, rec);
    }
};
