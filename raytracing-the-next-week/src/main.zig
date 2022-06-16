const std = @import("std");
const Allocator = std.mem.Allocator;

const aarect = @import("./aarect.zig");
const XyRect = aarect.XyRect;
const XzRect = aarect.XzRect;
const YzRect = aarect.YzRect;

const Box = @import("./box.zig").Box;

const BvhNode = @import("./bvh.zig").BvhNode;

const Camera = @import("./camera.zig").Camera;
const writeColor = @import("./color.zig").writeColor;

const hittable = @import("./hittable.zig");
const Hittable = hittable.Hittable;
const HitRecord = hittable.HitRecord;

const HittableList = @import("./hittable_list.zig").HittableList;
const material = @import("./material.zig");
const Dielectric = material.Dielectric;
const DiffuseLight = material.DiffuseLight;
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
const ImageTexture = texture.ImageTexture;
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

fn rayColor(r: Ray, background: Color, world: Hittable, depth: usize) Color {
    var rec: HitRecord = undefined;

    if (depth <= 0)
        return Color.init(0, 0, 0);

    if (!world.hit(r, 0.001, infinity, &rec))
        return background;

    var scattered: Ray = undefined;
    var attenuation: Color = undefined;
    const emitted = rec.mat_ptr.emitted(rec.u, rec.v, rec.p);

    if (!rec.mat_ptr.scatter(r, rec, &attenuation, &scattered))
        return emitted;

    return emitted.add(attenuation.mult(rayColor(scattered, background, world, depth - 1)));
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

fn earth(allocator: Allocator) !HittableList {
    var earth_texture = try allocator.create(ImageTexture);
    earth_texture.* = try ImageTexture.init(allocator, "earthmap.jpg");
    var earth_surface = try allocator.create(Lambertian);
    earth_surface.* = Lambertian.init(&earth_texture.texture);
    var globe = try allocator.create(Sphere);
    globe.* = Sphere.init(Point3.init(0, 0, 0), 2, &earth_surface.material);
    return HittableList.initHittable(allocator, &globe.hittable);
}

fn simpleLight(allocator: Allocator) !HittableList {
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

    var difflight = try allocator.create(DiffuseLight);
    difflight.* = try DiffuseLight.initColor(allocator, Color.init(4, 4, 4));
    var r = try allocator.create(XyRect);
    r.* = XyRect.init(3, 5, 1, 3, -2, &difflight.material);
    try objects.add(&r.hittable);

    return objects;
}

fn cornellBox(allocator: Allocator) !HittableList {
    var objects = HittableList.init(allocator);

    var red = try allocator.create(Lambertian);
    red.* = try Lambertian.initColor(allocator, Color.init(0.65, 0.05, 0.05));
    var white = try allocator.create(Lambertian);
    white.* = try Lambertian.initColor(allocator, Color.init(0.73, 0.73, 0.73));
    var green = try allocator.create(Lambertian);
    green.* = try Lambertian.initColor(allocator, Color.init(0.12, 0.45, 0.15));
    var light = try allocator.create(DiffuseLight);
    light.* = try DiffuseLight.initColor(allocator, Color.init(15, 15, 15));
    {
        var r = try allocator.create(YzRect);
        r.* = YzRect.init(0, 555, 0, 555, 555, &green.material);
        try objects.add(&r.hittable);
    }
    {
        var r = try allocator.create(YzRect);
        r.* = YzRect.init(0, 555, 0, 555, 0, &red.material);
        try objects.add(&r.hittable);
    }
    {
        var r = try allocator.create(XzRect);
        r.* = XzRect.init(213, 343, 227, 332, 554, &light.material);
        try objects.add(&r.hittable);
    }
    {
        var r = try allocator.create(XzRect);
        r.* = XzRect.init(0, 555, 0, 555, 0, &white.material);
        try objects.add(&r.hittable);
    }
    {
        var r = try allocator.create(XzRect);
        r.* = XzRect.init(0, 555, 0, 555, 555, &white.material);
        try objects.add(&r.hittable);
    }
    {
        var r = try allocator.create(XyRect);
        r.* = XyRect.init(0, 555, 0, 555, 555, &white.material);
        try objects.add(&r.hittable);
    }

    {
        var b = try allocator.create(Box);
        b.* = try Box.init(allocator, Point3.init(130, 0, 65), Point3.init(295, 165, 230), &white.material);
        try objects.add(&b.hittable);
    }
    {
        var b = try allocator.create(Box);
        b.* = try Box.init(allocator, Point3.init(265, 0, 295), Point3.init(430, 330, 460), &white.material);
        try objects.add(&b.hittable);
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

    var aspect_ratio: f64 = 16.0 / 9.0;
    var image_width: usize = 400;
    var samples_per_pixel: usize = 100;
    const max_depth = 50;

    var world: HittableList = undefined;
    var lookfrom: Point3 = undefined;
    var lookat: Point3 = undefined;
    var vfov: f64 = 40.0;
    var aperture: f64 = 0.1;
    var background = Color.init(0, 0, 0);

    switch (6) {
        1 => {
            world = try randomScene(allocator);
            background = Color.init(0.7, 0.8, 1.0);
            lookfrom = Point3.init(13, 2, 3);
            lookat = Point3.init(0, 0, 0);
            vfov = 20.0;
            aperture = 0.1;
        },
        2 => {
            world = try twoSpheres(allocator);
            background = Color.init(0.7, 0.8, 1.0);
            lookfrom = Point3.init(13, 2, 3);
            lookat = Point3.init(0, 0, 0);
            vfov = 20.0;
        },
        3 => {
            world = try twoPerlinSpheres(allocator);
            background = Color.init(0.7, 0.8, 1.0);
            lookfrom = Point3.init(13, 2, 3);
            lookat = Point3.init(0, 0, 0);
            vfov = 20.0;
        },
        4 => {
            world = try earth(allocator);
            background = Color.init(0.7, 0.8, 1.0);
            lookfrom = Point3.init(13, 2, 3);
            lookat = Point3.init(0, 0, 0);
            vfov = 20.0;
        },
        5 => {
            world = try simpleLight(allocator);
            samples_per_pixel = 400;
            background = Color.init(0, 0, 0);
            lookfrom = Point3.init(26, 3, 6);
            lookat = Point3.init(0, 2, 0);
            vfov = 20.0;
        },
        6 => {
            world = try cornellBox(allocator);
            aspect_ratio = 1.0;
            image_width = 600;
            samples_per_pixel = 200;
            background = Color.init(0, 0, 0);
            lookfrom = Point3.init(278, 278, -800);
            lookat = Point3.init(278, 278, 0);
            vfov = 40.0;
        },
        else => unreachable,
    }

    const vup = Vec3.init(0, 1, 0);
    const dist_to_focus = 10.0;
    const image_height = @floatToInt(usize, @intToFloat(f64, image_width) / aspect_ratio);

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
                const u = (@intToFloat(f64, i) + randomDouble()) / (@intToFloat(f64, image_width) - 1);
                const v = (@intToFloat(f64, j) + randomDouble()) / (@intToFloat(f64, image_height) - 1);
                const r = cam.getRay(u, v);
                pixel_color.addMut(rayColor(r, background, world.hittable, max_depth));
            }
            try writeColor(stdout, pixel_color, samples_per_pixel);
        }
    }

    try stderr.writeAll("\nDone.\n");
}
