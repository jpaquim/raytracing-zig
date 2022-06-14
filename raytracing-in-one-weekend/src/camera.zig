const std = @import("std");

const Ray = @import("./ray.zig").Ray;
const degreesToRadians = @import("./rtweekend.zig").degreesToRadians;
const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const cross = vec3.cross;
const unitVector = vec3.unitVector;

pub const Camera = struct {
    origin: Point3,
    lower_left_corner: Point3,
    horizontal: Vec3,
    vertical: Vec3,

    pub fn init(
        lookfrom: Point3,
        lookat: Point3,
        vup: Vec3,
        vfov: f64,
        aspect_ratio: f64,
    ) Camera {
        const theta = degreesToRadians(vfov);
        const h = @tan(theta / 2);
        const viewport_height = 2.0 * h;
        const viewport_width = aspect_ratio * viewport_height;

        const w = unitVector(lookfrom.sub(lookat));
        const u = unitVector(cross(vup, w));
        const v = cross(w, u);

        const origin = lookfrom;
        const horizontal = u.multScalar(viewport_width);
        const vertical = v.multScalar(viewport_height);
        return .{
            .origin = origin,
            .horizontal = horizontal,
            .vertical = vertical,
            .lower_left_corner = origin
                .sub(horizontal.divScalar(2))
                .sub(vertical.divScalar(2))
                .sub(w),
        };
    }

    pub fn getRay(self: Camera, s: f64, t: f64) Ray {
        return Ray.init(
            self.origin,
            self.lower_left_corner
                .add(self.horizontal.multScalar(s))
                .add(self.vertical.multScalar(t))
                .sub(self.origin),
        );
    }
};
