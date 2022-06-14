const std = @import("std");

const Camera = @import("./camera.zig").Camera;
const writeColor = @import("./color.zig").writeColor;

const hittable = @import("./hittable.zig");
const Hittable = hittable.Hittable;
const HitRecord = hittable.HitRecord;

const HittableList = @import("./hittable_list.zig").HittableList;
const material = @import("./material.zig");
const Lambertian = material.Lambertian;
const Metal = material.Metal;
const Ray = @import("./ray.zig").Ray;
const Sphere = @import("./sphere.zig").Sphere;

const rtweekend = @import("./rtweekend.zig");
const infinity = rtweekend.infinity;
const randomDouble = rtweekend.randomDouble;

const vec3 = @import("./vec3.zig");
const Color = vec3.Color;
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const randomInHemisphere = vec3.randomInHemisphere;
const randomInUnitSphere = vec3.randomInUnitSphere;
const randomUnitVector = vec3.randomUnitVector;
const unitVector = vec3.unitVector;

fn rayColor(r: Ray, world: Hittable, depth: usize) Color {
    var rec: HitRecord = undefined;

    if (depth <= 0)
        return Color.init(0, 0, 0);

    if (world.hit(r, 0.001, infinity, &rec)) {
        var scattered: Ray = undefined;
        var attenuation: Color = undefined;
        if (rec.mat_ptr.scatter(r, rec, &attenuation, &scattered))
            return attenuation.mult(rayColor(scattered, world, depth - 1));
        return Color.init(0, 0, 0);
        // const target = rec.p.add(rec.normal).add(randomInUnitSphere());
        // const target = rec.p.add(rec.normal).add(randomUnitVector());
        // const target = rec.p.add(randomInHemisphere(rec.normal));
        // return rayColor(Ray.init(rec.p, target.sub(rec.p)), world, depth - 1).multScalar(0.5);
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
    const samples_per_pixel = 100;
    const max_depth = 50;

    var world = HittableList.init(allocator);

    {
        var m = try allocator.create(Lambertian);
        m.* = Lambertian.init(Color.init(0.8, 0.8, 0.0));
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(0, -100.5, -1), 100.0, &m.material);
        try world.add(&s.hittable);
    }
    {
        var m = try allocator.create(Lambertian);
        m.* = Lambertian.init(Color.init(0.7, 0.3, 0.3));
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(0, 0, -1), 0.5, &m.material);
        try world.add(&s.hittable);
    }
    {
        var m = try allocator.create(Metal);
        m.* = Metal.init(Color.init(0.8, 0.8, 0.8));
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(-1, 0, -1), 0.5, &m.material);
        try world.add(&s.hittable);
    }
    {
        var m = try allocator.create(Metal);
        m.* = Metal.init(Color.init(0.8, 0.6, 0.2));
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(1, 0, -1), 0.5, &m.material);
        try world.add(&s.hittable);
    }

    const cam = Camera.init();

    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    var j: usize = image_height;
    while (j > 0) {
        j -= 1;
        try stderr.print("\rScanlines remaining: {d:3}", .{j});
        var i: usize = 0;
        while (i < image_width) : (i += 1) {
            var pixel_color = Color.init(0, 0, 0);
            var s: usize = 0;
            while (s < samples_per_pixel) : (s += 1) {
                const u = (@intToFloat(f64, i) + randomDouble()) / (image_width - 1);
                const v = (@intToFloat(f64, j) + randomDouble()) / (image_height - 1);
                const r = cam.getRay(u, v);
                pixel_color.addMut(rayColor(r, world.hittable, max_depth));
            }
            try writeColor(stdout, pixel_color, samples_per_pixel);
        }
    }

    try stderr.writeAll("\nDone.\n");
}
