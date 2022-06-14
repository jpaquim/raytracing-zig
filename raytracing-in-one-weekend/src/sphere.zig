const std = @import("std");
const sqrt = std.math.sqrt;

const h = @import("./hittable.zig");
const Hittable = h.Hittable;
const HitRecord = h.HitRecord;
const Ray = @import("./ray.zig").Ray;

const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;

pub const Sphere = struct {
    hittable: Hittable,

    center: Point3,
    radius: f64,

    pub fn init(cen: Point3, r: f64) Sphere {
        return .{
            .hittable = .{ .hitFn = hit },
            .center = cen,
            .radius = r,
        };
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(Sphere, "hittable", hittable);

        const oc = r.origin().sub(self.center);
        const a = r.direction().lengthSquared();
        const half_b = dot(oc, r.direction());
        const c = oc.lengthSquared() - self.radius * self.radius;

        const discriminant = half_b * half_b - a * c;

        if (discriminant < 0)
            return false;
        const sqrtd = sqrt(discriminant);

        var root = (-half_b - sqrtd) / a;
        if (root < t_min or t_max < root) {
            root = (-half_b + sqrtd) / a;
            if (root < t_min or t_max < root)
                return false;
        }

        rec.t = root;
        rec.p = r.at(rec.t);
        rec.normal = rec.p.sub(self.center).divScalar(self.radius);
        const outward_normal = rec.p.sub(self.center).divScalar(self.radius);
        rec.setFaceNormal(r, outward_normal);

        return true;
    }
};
