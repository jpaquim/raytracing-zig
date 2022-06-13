const std = @import("std");
const writeColor = @import("./color.zig").writeColor;
const vec3 = @import("./vec3.zig");
const Color = vec3.Color;
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;
const unitVector = vec3.unitVector;
const Ray = @import("./ray.zig").Ray;

fn hitSphere(center: Point3, radius: f64, r: Ray) f64 {
    const oc = r.origin().sub(center);
    const a = dot(r.direction(), r.direction());
    const b = 2.0 * dot(oc, r.direction());
    const c = dot(oc, oc) - radius * radius;
    const discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
        return -1.0;
    } else {
        return (-b - std.math.sqrt(discriminant)) / (2.0 * a);
    }
}

fn rayColor(r: Ray) Color {
    var t = hitSphere(Point3.init(0, 0, -1), 0.5, r);
    if (t > 0.0) {
        const n = unitVector(r.at(t).sub(Vec3.init(0, 0, -1)));
        return Color.init(n.x() + 1, n.y() + 1, n.z() + 1).multScalar(0.5);
    }
    const unit_direction = unitVector(r.direction());
    t = 0.5 * (unit_direction.y() + 1.0);
    return Color.init(1, 1, 1)
        .multScalar(1.0 - t)
        .add(Color.init(0.5, 0.7, 1.0).multScalar(t));
}

pub fn main() anyerror!void {
    const aspect_ratio = 16.0 / 9.0;
    const image_width = 400;
    const image_height = @floatToInt(comptime_int, image_width / aspect_ratio);

    const viewport_height = 2.0;
    const viewport_width = aspect_ratio * viewport_height;
    const focal_length = 1.0;

    const origin = Point3.init(0, 0, 0);
    const horizontal = Vec3.init(viewport_width, 0, 0);
    const vertical = Vec3.init(0, viewport_height, 0);
    const lower_left_corner = origin
        .sub(horizontal.divScalar(2))
        .sub(vertical.divScalar(2))
        .sub(Vec3.init(0, 0, focal_length));

    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    var j: usize = image_height;
    while (j > 0) {
        j -= 1;
        try stderr.print("\rScanlines remaining: {}", .{j});
        var i: usize = 0;
        while (i < image_width) : (i += 1) {
            const u = @intToFloat(f64, i) / (image_width - 1);
            const v = @intToFloat(f64, j) / (image_height - 1);
            const r = Ray.init(
                origin,
                lower_left_corner
                    .add(horizontal.multScalar(u))
                    .add(vertical.multScalar(v))
                    .sub(origin),
            );
            const pixel_color = rayColor(r);
            try writeColor(stdout, pixel_color);
        }
    }

    try stderr.writeAll("\nDone.\n");
}
