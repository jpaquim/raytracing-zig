const std = @import("std");

const Ray = @import("./ray.zig").Ray;
const rtweekend = @import("./rtweekend.zig");
const degreesToRadians = rtweekend.degreesToRadians;
const randomDouble2 = rtweekend.randomDouble2;

const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const cross = vec3.cross;
const randomInUnitDisk = vec3.randomInUnitDisk;
const unitVector = vec3.unitVector;

pub const Camera = struct {
    origin: Point3,
    lower_left_corner: Point3,
    horizontal: Vec3,
    vertical: Vec3,
    u: Vec3,
    v: Vec3,
    w: Vec3,
    lens_radius: f64,
    time0: f64,
    time1: f64,

    pub fn init(
        lookfrom: Point3,
        lookat: Point3,
        vup: Vec3,
        vfov: f64,
        aspect_ratio: f64,
        aperture: f64,
        focus_dist: f64,
        time0: ?f64,
        time1: ?f64,
    ) Camera {
        const theta = degreesToRadians(vfov);
        const h = @tan(theta / 2);
        const viewport_height = 2.0 * h;
        const viewport_width = aspect_ratio * viewport_height;

        const w = unitVector(lookfrom.sub(lookat));
        const u = unitVector(cross(vup, w));
        const v = cross(w, u);

        const origin = lookfrom;
        const horizontal = u.multScalar(focus_dist * viewport_width);
        const vertical = v.multScalar(focus_dist * viewport_height);
        return .{
            .origin = origin,
            .horizontal = horizontal,
            .vertical = vertical,
            .lower_left_corner = origin
                .sub(horizontal.divScalar(2))
                .sub(vertical.divScalar(2))
                .sub(w.multScalar(focus_dist)),
            .u = u,
            .v = v,
            .w = w,
            .lens_radius = aperture / 2,
            .time0 = time0 orelse 0.0,
            .time1 = time1 orelse 0.0,
        };
    }

    pub fn getRay(self: Camera, s: f64, t: f64) Ray {
        const rd = randomInUnitDisk().multScalar(self.lens_radius);
        const offset = self.u.multScalar(rd.x()).add(self.v.multScalar(rd.y()));

        return Ray.init(
            self.origin.add(offset),
            self.lower_left_corner
                .add(self.horizontal.multScalar(s))
                .add(self.vertical.multScalar(t))
                .sub(self.origin)
                .sub(offset),
            randomDouble2(self.time0, self.time1),
        );
    }
};
