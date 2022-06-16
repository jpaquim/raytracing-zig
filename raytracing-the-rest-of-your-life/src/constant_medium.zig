const std = @import("std");
const Allocator = std.mem.Allocator;

const AABB = @import("./aabb.zig").AABB;
const h = @import("./hittable.zig");
const Hittable = h.Hittable;
const HitRecord = h.HitRecord;

const material = @import("./material.zig");
const Isotropic = material.Isotropic;
const Material = material.Material;
const Ray = @import("./ray.zig").Ray;

const rtweekend = @import("./rtweekend.zig");
const infinity = rtweekend.infinity;
const makePtr = rtweekend.makePtr;
const makePtrColor = rtweekend.makePtrColor;
const randomDouble = rtweekend.randomDouble;

const texture = @import("./texture.zig");
const Texture = texture.Texture;

const vec3 = @import("./vec3.zig");
const Color = vec3.Color;
const Vec3 = vec3.Vec3;

pub const ConstantMedium = struct {
    hittable: Hittable,

    boundary: *Hittable,
    phase_function: *Material,
    neg_inv_density: f64,

    pub fn init(allocator: Allocator, b: *Hittable, d: f64, a: *Texture) !ConstantMedium {
        const phase_function = try makePtr(allocator, Isotropic, .{a});
        return ConstantMedium{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .boundary = b,
            .neg_inv_density = -1 / d,
            .phase_function = &phase_function.material,
        };
    }

    pub fn initColor(allocator: Allocator, b: *Hittable, d: f64, c: Color) !ConstantMedium {
        const phase_function = try makePtrColor(allocator, Isotropic, .{ allocator, c });
        return ConstantMedium{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .boundary = b,
            .neg_inv_density = -1 / d,
            .phase_function = &phase_function.material,
        };
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(ConstantMedium, "hittable", hittable);
        const enable_debug = false;
        const debugging = enable_debug and randomDouble() < 0.00001;
        const stderr = std.io.getStdErr().writer();

        var rec1: HitRecord = undefined;
        var rec2: HitRecord = undefined;

        if (!self.boundary.hit(r, -infinity, infinity, &rec1))
            return false;

        if (!self.boundary.hit(r, rec1.t + 0.0001, infinity, &rec2))
            return false;

        if (debugging) stderr.print("\nt_min={}, t_max={}\n", .{ rec1.t, rec2.t }) catch unreachable;

        if (rec1.t < t_min) rec1.t = t_min;
        if (rec2.t > t_max) rec2.t = t_max;

        if (rec1.t >= rec2.t)
            return false;

        if (rec1.t < 0)
            rec1.t = 0;

        const ray_length = r.direction().length();
        const distance_inside_boundary = (rec2.t - rec1.t) * ray_length;
        const hit_distance = self.neg_inv_density * std.math.ln(randomDouble());

        if (hit_distance > distance_inside_boundary)
            return false;

        rec.t = rec1.t + hit_distance / ray_length;
        rec.p = r.at(rec.t);

        if (debugging) stderr.print("hit_distance = {}\nrec.t = {}\nrec.p = {}\n", .{ hit_distance, rec.t, rec.p }) catch unreachable;

        rec.normal = Vec3.init(1, 0, 0);
        rec.front_face = true;
        rec.mat_ptr = self.phase_function;

        return true;
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        const self = @fieldParentPtr(ConstantMedium, "hittable", hittable);
        return self.boundary.boundingBox(time0, time1, output_box);
    }
};
