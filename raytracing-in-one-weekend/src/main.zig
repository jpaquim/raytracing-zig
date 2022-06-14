const std = @import("std");

const writeColor = @import("./color.zig").writeColor;

const hittable = @import("./hittable.zig");
const Hittable = hittable.Hittable;
const HitRecord = hittable.HitRecord;

const HittableList = @import("./hittable_list.zig").HittableList;
const Ray = @import("./ray.zig").Ray;
const Sphere = @import("./sphere.zig").Sphere;
const infinity = @import("./rtweekend.zig").infinity;

const vec3 = @import("./vec3.zig");
const Color = vec3.Color;
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const unitVector = vec3.unitVector;

fn rayColor(r: Ray, world: Hittable) Color {
    var rec: HitRecord = undefined;
    if (world.hit(r, 0, infinity, &rec)) {
        return rec.normal.add(Color.init(1, 1, 1)).multScalar(0.5);
    }
    const unit_direction = unitVector(r.direction());
    const t = 0.5 * (unit_direction.y() + 1.0);
    return Color.init(1, 1, 1)
        .multScalar(1.0 - t)
        .add(Color.init(0.5, 0.7, 1.0).multScalar(t));
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    // const allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const aspect_ratio = 16.0 / 9.0;
    const image_width = 400;
    const image_height = @floatToInt(comptime_int, image_width / aspect_ratio);

    var world = HittableList.init(allocator);

    {
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(0, 0, -1), 0.5);
        try world.add(&s.hittable);
    }
    {
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(0, -100.5, -1), 100);
        try world.add(&s.hittable);
    }

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
            const pixel_color = rayColor(r, world.hittable);
            try writeColor(stdout, pixel_color);
        }
    }

    try stderr.writeAll("\nDone.\n");
}
