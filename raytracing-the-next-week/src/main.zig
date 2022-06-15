const std = @import("std");
const Allocator = std.mem.Allocator;

const BvhNode = @import("./bvh.zig").BvhNode;

const Camera = @import("./camera.zig").Camera;
const writeColor = @import("./color.zig").writeColor;

const hittable = @import("./hittable.zig");
const Hittable = hittable.Hittable;
const HitRecord = hittable.HitRecord;

const HittableList = @import("./hittable_list.zig").HittableList;
const material = @import("./material.zig");
const Dielectric = material.Dielectric;
const Lambertian = material.Lambertian;
const Material = material.Material;
const Metal = material.Metal;
const MovingSphere = @import("./moving_sphere.zig").MovingSphere;
const Ray = @import("./ray.zig").Ray;
const Sphere = @import("./sphere.zig").Sphere;

const rtweekend = @import("./rtweekend.zig");
const infinity = rtweekend.infinity;
const randomDouble = rtweekend.randomDouble;
const randomDouble2 = rtweekend.randomDouble2;

const texture = @import("./texture.zig");
const CheckerTexture = texture.CheckerTexture;
const NoiseTexture = texture.NoiseTexture;
const SolidColor = texture.SolidColor;

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

fn randomScene(allocator: Allocator) !HittableList {
    var world = HittableList.init(allocator);

    var checker = try allocator.create(CheckerTexture);
    checker.* = try CheckerTexture.initColors(allocator, Color.init(0.2, 0.3, 0.1), Color.init(0.9, 0.9, 0.9));
    var ground_material = try allocator.create(Lambertian);
    ground_material.* = Lambertian.init(&checker.texture);
    {
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(0, -1000, 0), 1000, &ground_material.material);
        try world.add(&s.hittable);
    }

    var a: i32 = -11;
    while (a < 11) : (a += 1) {
        var b: i32 = -11;
        while (b < 11) : (b += 1) {
            const choose_mat = randomDouble();
            const center = Point3.init(@intToFloat(f64, a) + 0.9 * randomDouble(), 0.2, @intToFloat(f64, b) + 0.9 * randomDouble());

            if ((center.sub(Point3.init(4, 0.2, 0)).length() > 0.9)) {
                var sphere_material: *Material = undefined;

                if (choose_mat < 0.8) {
                    const albedo = Color.random().mult(Color.random());
                    var m = try allocator.create(Lambertian);
                    m.* = try Lambertian.initColor(allocator, albedo);
                    sphere_material = &m.material;

                    const center2 = center.add(Vec3.init(0, randomDouble2(0, 0.5), 0));
                    var s = try allocator.create(MovingSphere);
                    s.* = MovingSphere.init(center, center2, 0.0, 1.0, 0.2, sphere_material);
                    try world.add(&s.hittable);
                } else if (choose_mat < 0.95) {
                    const albedo = Color.random2(0.5, 1);
                    const fuzz = randomDouble2(0, 0.5);
                    var m = try allocator.create(Metal);
                    m.* = Metal.init(albedo, fuzz);
                    sphere_material = &m.material;

                    var s = try allocator.create(Sphere);
                    s.* = Sphere.init(center, 0.2, sphere_material);
                    try world.add(&s.hittable);
                } else {
                    var m = try allocator.create(Dielectric);
                    m.* = Dielectric.init(1.5);
                    sphere_material = &m.material;

                    var s = try allocator.create(Sphere);
                    s.* = Sphere.init(center, 0.2, sphere_material);
                    try world.add(&s.hittable);
                }
            }
        }
    }
    {
        var material1 = try allocator.create(Dielectric);
        material1.* = Dielectric.init(1.5);
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(0, 1, 0), 1.0, &material1.material);
        try world.add(&s.hittable);
    }
    {
        var material2 = try allocator.create(Lambertian);
        material2.* = try Lambertian.initColor(allocator, Color.init(0.4, 0.2, 0.1));
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(-4, 1, 0), 1.0, &material2.material);
        try world.add(&s.hittable);
    }
    {
        var material3 = try allocator.create(Metal);
        material3.* = Metal.init(Color.init(0.7, 0.6, 0.5), 0.0);
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(4, 1, 0), 1.0, &material3.material);
        try world.add(&s.hittable);
    }

    return world;
}

fn twoSpheres(allocator: Allocator) !HittableList {
    var objects = HittableList.init(allocator);

    var checker = try allocator.create(CheckerTexture);
    checker.* = try CheckerTexture.initColors(allocator, Color.init(0.2, 0.3, 0.1), Color.init(0.9, 0.9, 0.9));

    {
        var m = try allocator.create(Lambertian);
        m.* = Lambertian.init(&checker.texture);
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(0, -10, 0), 10, &m.material);
        try objects.add(&s.hittable);
    }

    {
        var m = try allocator.create(Lambertian);
        m.* = Lambertian.init(&checker.texture);
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(0, 10, 0), 10, &m.material);
        try objects.add(&s.hittable);
    }

    return objects;
}

fn twoPerlinSpheres(allocator: Allocator) !HittableList {
    var objects = HittableList.init(allocator);

    var pertext = try allocator.create(NoiseTexture);
    pertext.* = try NoiseTexture.init(allocator, 4);
    {
        var m = try allocator.create(Lambertian);
        m.* = Lambertian.init(&pertext.texture);
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(0, -1000, 0), 1000, &m.material);
        try objects.add(&s.hittable);
    }
    {
        var m = try allocator.create(Lambertian);
        m.* = Lambertian.init(&pertext.texture);
        var s = try allocator.create(Sphere);
        s.* = Sphere.init(Point3.init(0, 2, 0), 2, &m.material);
        try objects.add(&s.hittable);
    }

    return objects;
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
    const samples_per_pixel = 100;
    const max_depth = 50;

    var world: HittableList = undefined;
    var lookfrom: Point3 = undefined;
    var lookat: Point3 = undefined;
    var vfov: f64 = 40.0;
    var aperture: f64 = 0.1;

    switch (3) {
        1 => {
            world = try randomScene(allocator);
            lookfrom = Point3.init(13, 2, 3);
            lookat = Point3.init(0, 0, 0);
            vfov = 20.0;
            aperture = 0.1;
        },
        2 => {
            world = try twoSpheres(allocator);
            lookfrom = Point3.init(13, 2, 3);
            lookat = Point3.init(0, 0, 0);
            vfov = 20.0;
        },
        3 => {
            world = try twoPerlinSpheres(allocator);
            lookfrom = Point3.init(13, 2, 3);
            lookat = Point3.init(0, 0, 0);
            vfov = 20.0;
        },
        else => unreachable,
    }

    const vup = Vec3.init(0, 1, 0);
    const dist_to_focus = 10.0;
    const image_height = @floatToInt(comptime_int, image_width / aspect_ratio);

    const cam = Camera.init(lookfrom, lookat, vup, vfov, aspect_ratio, aperture, dist_to_focus, 0.0, 1.0);

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
