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
const ConstantMedium = @import("./constant_medium.zig").ConstantMedium;

const hittable = @import("./hittable.zig");
const Hittable = hittable.Hittable;
const HitRecord = hittable.HitRecord;
const RotateY = hittable.RotateY;
const Translate = hittable.Translate;

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
const makePtr = rtweekend.makePtr;
const makePtrColor = rtweekend.makePtrColor;
const makePtrErr = rtweekend.makePtrErr;
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

    try objects.add(&(try makePtr(allocator, Sphere, .{ Point3.init(0, -10, 0), 10, &(try makePtr(allocator, Lambertian, .{&checker.texture})).material })).hittable);
    try objects.add(&(try makePtr(allocator, Sphere, .{ Point3.init(0, 10, 0), 10, &(try makePtr(allocator, Lambertian, .{&checker.texture})).material })).hittable);

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
    const earth_texture = try makePtrErr(allocator, ImageTexture, .{ allocator, "earthmap.jpg" });
    const earth_surface = try makePtr(allocator, Lambertian, .{&earth_texture.texture});
    const globe = try makePtr(allocator, Sphere, .{ Point3.init(0, 0, 0), 2, &earth_surface.material });
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

    const red = try makePtrColor(allocator, Lambertian, .{ allocator, Color.init(0.65, 0.05, 0.05) });
    const white = try makePtrColor(allocator, Lambertian, .{ allocator, Color.init(0.73, 0.73, 0.73) });
    const green = try makePtrColor(allocator, Lambertian, .{ allocator, Color.init(0.12, 0.45, 0.15) });
    const light = try makePtrColor(allocator, DiffuseLight, .{ allocator, Color.init(15, 15, 15) });

    try objects.add(&(try makePtr(allocator, YzRect, .{ 0, 555, 0, 555, 555, &green.material })).hittable);
    try objects.add(&(try makePtr(allocator, YzRect, .{ 0, 555, 0, 555, 0, &red.material })).hittable);
    try objects.add(&(try makePtr(allocator, XzRect, .{ 213, 343, 227, 332, 554, &light.material })).hittable);
    try objects.add(&(try makePtr(allocator, XzRect, .{ 0, 555, 0, 555, 0, &white.material })).hittable);
    try objects.add(&(try makePtr(allocator, XzRect, .{ 0, 555, 0, 555, 555, &white.material })).hittable);
    try objects.add(&(try makePtr(allocator, XyRect, .{ 0, 555, 0, 555, 555, &white.material })).hittable);

    {
        const box = try makePtrErr(allocator, Box, .{ allocator, Point3.init(0, 0, 0), Point3.init(165, 330, 165), &white.material });
        const rotate_y = try makePtr(allocator, RotateY, .{ &box.hittable, 15 });
        const translate = try makePtr(allocator, Translate, .{ &rotate_y.hittable, Vec3.init(265, 0, 295) });
        try objects.add(&translate.hittable);
    }
    {
        const box = try makePtrErr(allocator, Box, .{ allocator, Point3.init(0, 0, 0), Point3.init(165, 165, 165), &white.material });
        const rotate_y = try makePtr(allocator, RotateY, .{ &box.hittable, -18 });
        const translate = try makePtr(allocator, Translate, .{ &rotate_y.hittable, Vec3.init(130, 0, 65) });
        try objects.add(&translate.hittable);
    }

    return objects;
}

fn cornellSmoke(allocator: Allocator) !HittableList {
    var objects = HittableList.init(allocator);

    const red = try makePtrColor(allocator, Lambertian, .{ allocator, Color.init(0.65, 0.05, 0.05) });
    const white = try makePtrColor(allocator, Lambertian, .{ allocator, Color.init(0.73, 0.73, 0.73) });
    const green = try makePtrColor(allocator, Lambertian, .{ allocator, Color.init(0.12, 0.45, 0.15) });
    const light = try makePtrColor(allocator, DiffuseLight, .{ allocator, Color.init(7, 7, 7) });

    try objects.add(&(try makePtr(allocator, YzRect, .{ 0, 555, 0, 555, 555, &green.material })).hittable);
    try objects.add(&(try makePtr(allocator, YzRect, .{ 0, 555, 0, 555, 0, &red.material })).hittable);
    try objects.add(&(try makePtr(allocator, XzRect, .{ 113, 443, 127, 432, 554, &light.material })).hittable);
    try objects.add(&(try makePtr(allocator, XzRect, .{ 0, 555, 0, 555, 0, &white.material })).hittable);
    try objects.add(&(try makePtr(allocator, XzRect, .{ 0, 555, 0, 555, 555, &white.material })).hittable);
    try objects.add(&(try makePtr(allocator, XyRect, .{ 0, 555, 0, 555, 555, &white.material })).hittable);

    const box1 = blk: {
        const box = try makePtrErr(allocator, Box, .{ allocator, Point3.init(0, 0, 0), Point3.init(165, 330, 165), &white.material });
        const rotate_y = try makePtr(allocator, RotateY, .{ &box.hittable, 15 });
        const translate = try makePtr(allocator, Translate, .{ &rotate_y.hittable, Vec3.init(265, 0, 295) });
        break :blk &translate.hittable;
    };
    const box2 = blk: {
        const box = try makePtrErr(allocator, Box, .{ allocator, Point3.init(0, 0, 0), Point3.init(165, 165, 165), &white.material });
        const rotate_y = try makePtr(allocator, RotateY, .{ &box.hittable, -18 });
        const translate = try makePtr(allocator, Translate, .{ &rotate_y.hittable, Vec3.init(130, 0, 65) });
        break :blk &translate.hittable;
    };

    try objects.add(&(try makePtrColor(allocator, ConstantMedium, .{ allocator, box1, 0.01, Color.init(0, 0, 0) })).hittable);
    try objects.add(&(try makePtrColor(allocator, ConstantMedium, .{ allocator, box2, 0.01, Color.init(1, 1, 1) })).hittable);

    return objects;
}

fn finalScene(allocator: Allocator) !HittableList {
    var boxes = HittableList.init(allocator);
    const ground = try makePtrColor(allocator, Lambertian, .{ allocator, Color.init(0.48, 0.83, 0.53) });

    const boxes_per_side = 20;
    var i: usize = 0;
    while (i < boxes_per_side) : (i += 1) {
        var j: usize = 0;
        while (j < boxes_per_side) : (j += 1) {
            const w = 100.0;
            const x0 = -1000.0 + @intToFloat(f64, i) * w;
            const z0 = -1000.0 + @intToFloat(f64, j) * w;
            const y0 = 0.0;
            const x1 = x0 + w;
            const y1 = randomDouble2(1, 101);
            const z1 = z0 + w;

            try boxes.add(&(try makePtrErr(allocator, Box, .{ allocator, Point3.init(x0, y0, z0), Point3.init(x1, y1, z1), &ground.material })).hittable);
        }
    }

    var objects = HittableList.init(allocator);

    try objects.add(&(try makePtrErr(allocator, BvhNode, .{ allocator, boxes, 0, 1 })).hittable);

    const light = try makePtrColor(allocator, DiffuseLight, .{ allocator, Color.init(7, 7, 7) });
    try objects.add(&(try makePtr(allocator, XzRect, .{ 123, 423, 147, 412, 554, &light.material })).hittable);

    const center1 = Point3.init(400, 400, 200);
    const center2 = center1.add(Vec3.init(30, 0, 0));
    const moving_sphere_material = try makePtrColor(allocator, Lambertian, .{ allocator, Color.init(0.7, 0.3, 0.1) });
    try objects.add(&(try makePtr(allocator, MovingSphere, .{ center1, center2, 0, 1, 50, &moving_sphere_material.material })).hittable);

    try objects.add(&(try makePtr(allocator, Sphere, .{ Point3.init(260, 150, 45), 50, &(try makePtr(allocator, Dielectric, .{1.5})).material })).hittable);
    try objects.add(&(try makePtr(allocator, Sphere, .{ Point3.init(0, 150, 145), 50, &(try makePtr(allocator, Metal, .{ Color.init(0.8, 0.8, 0.9), 1.0 })).material })).hittable);

    var boundary = try makePtr(allocator, Sphere, .{ Point3.init(360, 150, 145), 70, &(try makePtr(allocator, Dielectric, .{1.5})).material });
    try objects.add(&boundary.hittable);
    try objects.add(&(try makePtrColor(allocator, ConstantMedium, .{ allocator, &boundary.hittable, 0.2, Color.init(0.2, 0.4, 0.9) })).hittable);
    boundary = try makePtr(allocator, Sphere, .{ Point3.init(0, 0, 0), 5000, &(try makePtr(allocator, Dielectric, .{1.5})).material });
    try objects.add(&(try makePtrColor(allocator, ConstantMedium, .{ allocator, &boundary.hittable, 0.0001, Color.init(1, 1, 1) })).hittable);

    const emat = try makePtr(allocator, Lambertian, .{&(try makePtrErr(allocator, ImageTexture, .{ allocator, "earthmap.jpg" })).texture});
    try objects.add(&(try makePtr(allocator, Sphere, .{ Point3.init(400, 200, 400), 100, &emat.material })).hittable);

    const pertext = try makePtrErr(allocator, NoiseTexture, .{ allocator, 4 });
    try objects.add(&(try makePtr(allocator, Sphere, .{ Point3.init(220, 280, 300), 80, &(try makePtr(allocator, Lambertian, .{&pertext.texture})).material })).hittable);

    var boxes2 = HittableList.init(allocator);
    const white = try makePtrColor(allocator, Lambertian, .{ allocator, Color.init(0.73, 0.73, 0.73) });
    const ns = 1000;
    var j: usize = 0;
    while (j < ns) : (j += 1) {
        try boxes2.add(&(try makePtr(allocator, Sphere, .{ Point3.random2(0, 165), 10, &white.material })).hittable);
    }

    const bvh = try makePtrErr(allocator, BvhNode, .{ allocator, boxes2, 0, 1 });
    const rotate_y = try makePtr(allocator, RotateY, .{ &bvh.hittable, 15 });
    const translate = try makePtr(allocator, Translate, .{ &rotate_y.hittable, Vec3.init(-100, 270, 395) });
    try objects.add(&translate.hittable);

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

    switch (8) {
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
        7 => {
            world = try cornellSmoke(allocator);
            aspect_ratio = 1.0;
            image_width = 600;
            samples_per_pixel = 200;
            background = Color.init(0, 0, 0);
            lookfrom = Point3.init(278, 278, -800);
            lookat = Point3.init(278, 278, 0);
            vfov = 40.0;
        },
        8 => {
            world = try finalScene(allocator);
            aspect_ratio = 1.0;
            image_width = 600;
            samples_per_pixel = 10000;
            background = Color.init(0, 0, 0);
            lookfrom = Point3.init(478, 278, -600);
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
