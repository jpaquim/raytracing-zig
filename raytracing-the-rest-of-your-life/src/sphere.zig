const std = @import("std");
const acos = std.math.acos;
const atan2 = std.math.atan2;
const sqrt = std.math.sqrt;

const AABB = @import("./aabb.zig").AABB;
const h = @import("./hittable.zig");
const Hittable = h.Hittable;
const HitRecord = h.HitRecord;

const Material = @import("./material.zig").Material;
const ONB = @import("./onb.zig").ONB;
const randomToSphere = @import("./pdf.zig").randomToSphere;
const Ray = @import("./ray.zig").Ray;
const rtweekend = @import("./rtweekend.zig");
const infinity = rtweekend.infinity;
const pi = rtweekend.pi;

const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;

pub const Sphere = struct {
    hittable: Hittable,

    center: Point3,
    radius: f64,
    mat_ptr: *Material,

    pub fn init(cen: Point3, r: f64, m: *Material) Sphere {
        return .{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox, .pdfValueFn = pdfValue, .randomFn = random },
            .center = cen,
            .radius = r,
            .mat_ptr = m,
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
        getSphereUV(outward_normal, &rec.u, &rec.v);
        rec.mat_ptr = self.mat_ptr;

        return true;
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        _ = time0;
        _ = time1;
        const self = @fieldParentPtr(Sphere, "hittable", hittable);
        output_box.* = AABB.init(
            self.center.sub(Vec3.init(self.radius, self.radius, self.radius)),
            self.center.add(Vec3.init(self.radius, self.radius, self.radius)),
        );
        return true;
    }

    fn pdfValue(hittable: *const Hittable, origin: Point3, v: Vec3) f64 {
        const self = @fieldParentPtr(Sphere, "hittable", hittable);
        var rec: HitRecord = undefined;
        if (!hittable.hit(Ray.init(origin, v, null), 0.001, infinity, &rec))
            return 0;

        const cos_theta_max = sqrt(1 - self.radius * self.radius / self.center.sub(origin).lengthSquared());
        const solid_angle = 2 * pi * (1 - cos_theta_max);

        return 1 / solid_angle;
    }

    fn random(hittable: *const Hittable, origin: Point3) Vec3 {
        const self = @fieldParentPtr(Sphere, "hittable", hittable);
        const direction = self.center.sub(origin);
        const distance_squared = direction.lengthSquared();
        var uvw = ONB.init();
        uvw.buildFromW(direction);
        return uvw.local(randomToSphere(self.radius, distance_squared));
    }

    fn getSphereUV(p: Point3, u: *f64, v: *f64) void {
        const theta = acos(-p.y());
        const phi = atan2(f64, -p.z(), p.x()) + pi;

        u.* = phi / (2 * pi);
        v.* = theta / pi;
    }
};
