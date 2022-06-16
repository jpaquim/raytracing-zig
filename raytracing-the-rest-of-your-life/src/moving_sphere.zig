const std = @import("std");
const sqrt = std.math.sqrt;

const aabb = @import("./aabb.zig");
const AABB = aabb.AABB;
const surroundingBox = aabb.surroundingBox;

const h = @import("./hittable.zig");
const Hittable = h.Hittable;
const HitRecord = h.HitRecord;

const Material = @import("./material.zig").Material;
const Ray = @import("./ray.zig").Ray;

const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;

pub const MovingSphere = struct {
    hittable: Hittable,

    center0: Point3,
    center1: Point3,
    time0: f64,
    time1: f64,
    radius: f64,
    mat_ptr: *Material,

    pub fn init(cen0: Point3, cen1: Point3, time0: f64, time1: f64, r: f64, m: *Material) MovingSphere {
        return .{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .center0 = cen0,
            .center1 = cen1,
            .time0 = time0,
            .time1 = time1,
            .radius = r,
            .mat_ptr = m,
        };
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(MovingSphere, "hittable", hittable);

        const oc = r.origin().sub(self.center(r.time()));
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
        rec.normal = rec.p.sub(self.center(r.time())).divScalar(self.radius);
        const outward_normal = rec.p.sub(self.center(r.time())).divScalar(self.radius);
        rec.setFaceNormal(r, outward_normal);
        rec.mat_ptr = self.mat_ptr;

        return true;
    }

    pub fn center(self: MovingSphere, time: f64) Point3 {
        return self.center0
            .add(self.center1.sub(self.center0).multScalar((time - self.time0) / (self.time1 - self.time0)));
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        const self = @fieldParentPtr(MovingSphere, "hittable", hittable);
        const box0 = AABB.init(
            self.center(time0).sub(Vec3.init(self.radius, self.radius, self.radius)),
            self.center(time0).add(Vec3.init(self.radius, self.radius, self.radius)),
        );
        const box1 = AABB.init(
            self.center(time1).sub(Vec3.init(self.radius, self.radius, self.radius)),
            self.center(time1).add(Vec3.init(self.radius, self.radius, self.radius)),
        );
        output_box.* = surroundingBox(box0, box1);
        return true;
    }
};
