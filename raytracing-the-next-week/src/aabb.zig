const std = @import("std");
const max = std.math.max;
const min = std.math.min;

const Ray = @import("./ray.zig").Ray;
const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

pub const AABB = struct {
    minimum: Point3,
    maximum: Point3,

    pub fn init(a: Point3, b: Point3) AABB {
        return .{ .minimum = a, .maximum = b };
    }

    pub fn min(self: AABB) Point3 {
        return self.minimum;
    }

    pub fn max(self: AABB) Point3 {
        return self.maximum;
    }

    pub fn hit(self: AABB, r: Ray, t_min_: f64, t_max_: f64) bool {
        var t_min = t_min_;
        var t_max = t_max_;
        var a: usize = 0;
        while (a < 3) : (a += 1) {
            const inv_d = 1.0 / r.direction().at(a);
            var t0 = (self.min().at(a) - r.origin().at(a)) * inv_d;
            var t1 = (self.max().at(a) - r.origin().at(a)) * inv_d;
            if (inv_d < 0.0)
                std.mem.swap(f64, &t0, &t1);
            t_min = if (t0 > t_min) t0 else t_min;
            t_max = if (t1 < t_max) t1 else t_max;

            // const t0 = min(
            //     f64,
            //     (self.minimum.at(a) - r.origin().at(a)) / (r.direction().at(a)),
            //     (self.maximum.at(a) - r.origin().at(a)) / (r.direction().at(a)),
            // );
            // const t1 = max(
            //     f64,
            //     (self.minimum.at(a) - r.origin().at(a)) / (r.direction().at(a)),
            //     (self.maximum.at(a) - r.origin().at(a)) / (r.direction().at(a)),
            // );
            // t_min = max(f64, t0, t_min);
            // t_max = min(f64, t1, t_max);

            if (t_max <= t_min)
                return false;
        }

        return true;
    }
};

pub fn surroundingBox(box0: AABB, box1: AABB) AABB {
    const small = Point3.init(
        min(box0.min().x(), box1.min().x()),
        min(box0.min().y(), box1.min().y()),
        min(box0.min().z(), box1.min().z()),
    );
    const big = Point3.init(
        max(box0.max().x(), box1.max().x()),
        max(box0.max().y(), box1.max().y()),
        max(box0.max().z(), box1.max().z()),
    );

    return AABB.init(small, big);
}
