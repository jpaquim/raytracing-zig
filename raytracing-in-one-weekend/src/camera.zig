const Ray = @import("./ray.zig").Ray;
const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

pub const Camera = struct {
    origin: Point3,
    lower_left_corner: Point3,
    horizontal: Vec3,
    vertical: Vec3,

    pub fn init() Camera {
        const aspect_ratio = 16.0 / 9.0;
        const viewport_height = 2.0;
        const viewport_width = aspect_ratio * viewport_height;
        const focal_length = 1.0;

        const origin = Point3.init(0, 0, 0);
        const horizontal = Vec3.init(viewport_width, 0, 0);
        const vertical = Vec3.init(0, viewport_height, 0);
        return .{
            .origin = origin,
            .horizontal = horizontal,
            .vertical = vertical,
            .lower_left_corner = origin
                .sub(horizontal.divScalar(2))
                .sub(vertical.divScalar(2))
                .sub(Vec3.init(0, 0, focal_length)),
        };
    }

    pub fn getRay(self: Camera, u: f64, v: f64) Ray {
        return Ray.init(
            self.origin,
            self.lower_left_corner
                .add(self.horizontal.multScalar(u))
                .add(self.vertical.multScalar(v))
                .sub(self.origin),
        );
    }
};
