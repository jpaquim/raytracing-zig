const AABB = @import("./aabb.zig").AABB;
const h = @import("./hittable.zig");
const Hittable = h.Hittable;
const HitRecord = h.HitRecord;

const Material = @import("./material.zig").Material;
const Ray = @import("./ray.zig").Ray;

const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

pub const XyRect = struct {
    hittable: Hittable,

    mp: *Material,
    x0: f64,
    x1: f64,
    y0: f64,
    y1: f64,
    k: f64,

    pub fn init(x0: f64, x1: f64, y0: f64, y1: f64, k: f64, mat: *Material) XyRect {
        return .{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .x0 = x0,
            .x1 = x1,
            .y0 = y0,
            .y1 = y1,
            .k = k,
            .mp = mat,
        };
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(XyRect, "hittable", hittable);
        const t = (self.k - r.origin().z()) / r.direction().z();
        if (t < t_min or t > t_max)
            return false;
        const x = r.origin().x() + t * r.direction().x();
        const y = r.origin().y() + t * r.direction().y();
        if (x < self.x0 or x > self.x1 or y < self.y0 or y > self.y1)
            return false;
        rec.u = (x - self.x0) / (self.x1 - self.x0);
        rec.v = (y - self.y0) / (self.y1 - self.y0);
        rec.t = t;
        const outward_normal = Vec3.init(0, 0, 1);
        rec.setFaceNormal(r, outward_normal);
        rec.mat_ptr = self.mp;
        rec.p = r.at(t);
        return true;
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        _ = time0;
        _ = time1;
        const self = @fieldParentPtr(XyRect, "hittable", hittable);
        output_box.* = AABB.init(
            Point3.init(self.x0, self.y0, self.k - 0.0001),
            Point3.init(self.x1, self.y1, self.k + 0.0001),
        );
        return true;
    }
};

pub const XzRect = struct {
    hittable: Hittable,

    mp: *Material,
    x0: f64,
    x1: f64,
    z0: f64,
    z1: f64,
    k: f64,

    pub fn init(x0: f64, x1: f64, z0: f64, z1: f64, k: f64, mat: *Material) XzRect {
        return .{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .x0 = x0,
            .x1 = x1,
            .z0 = z0,
            .z1 = z1,
            .k = k,
            .mp = mat,
        };
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(XzRect, "hittable", hittable);
        const t = (self.k - r.origin().y()) / r.direction().y();
        if (t < t_min or t > t_max)
            return false;
        const x = r.origin().x() + t * r.direction().x();
        const z = r.origin().z() + t * r.direction().z();
        if (x < self.x0 or x > self.x1 or z < self.z0 or z > self.z1)
            return false;
        rec.u = (x - self.x0) / (self.x1 - self.x0);
        rec.v = (z - self.z0) / (self.z1 - self.z0);
        rec.t = t;
        const outward_normal = Vec3.init(0, 1, 0);
        rec.setFaceNormal(r, outward_normal);
        rec.mat_ptr = self.mp;
        rec.p = r.at(t);
        return true;
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        _ = time0;
        _ = time1;
        const self = @fieldParentPtr(XzRect, "hittable", hittable);
        output_box.* = AABB.init(
            Point3.init(self.x0, self.k - 0.0001, self.z0),
            Point3.init(self.x1, self.k + 0.0001, self.z1),
        );
        return true;
    }
};

pub const YzRect = struct {
    hittable: Hittable,

    mp: *Material,
    y0: f64,
    y1: f64,
    z0: f64,
    z1: f64,
    k: f64,

    pub fn init(y0: f64, y1: f64, z0: f64, z1: f64, k: f64, mat: *Material) YzRect {
        return .{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .y0 = y0,
            .y1 = y1,
            .z0 = z0,
            .z1 = z1,
            .k = k,
            .mp = mat,
        };
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(YzRect, "hittable", hittable);
        const t = (self.k - r.origin().x()) / r.direction().x();
        if (t < t_min or t > t_max)
            return false;
        const y = r.origin().y() + t * r.direction().y();
        const z = r.origin().z() + t * r.direction().z();
        if (y < self.y0 or y > self.y1 or z < self.z0 or z > self.z1)
            return false;
        rec.u = (y - self.y0) / (self.y1 - self.y0);
        rec.v = (z - self.z0) / (self.z1 - self.z0);
        rec.t = t;
        const outward_normal = Vec3.init(1, 0, 0);
        rec.setFaceNormal(r, outward_normal);
        rec.mat_ptr = self.mp;
        rec.p = r.at(t);
        return true;
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        _ = time0;
        _ = time1;
        const self = @fieldParentPtr(YzRect, "hittable", hittable);
        output_box.* = AABB.init(
            Point3.init(self.k - 0.0001, self.y0, self.z0),
            Point3.init(self.k + 0.0001, self.y1, self.z1),
        );
        return true;
    }
};
