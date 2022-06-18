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
// const Dielectric = material.Dielectric;
const DiffuseLight = material.DiffuseLight;
const Lambertian = material.Lambertian;
const Material = material.Material;
// const Metal = material.Metal;
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

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    // const allocator = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const aspect_ratio = 1.0;
    const image_width = 600;
    const image_height = @floatToInt(usize, @intToFloat(f64, image_width) / aspect_ratio);
    const samples_per_pixel = 100;
    const max_depth = 50;

    const world = try cornellBox(allocator);

    const background = Color.init(0, 0, 0);

    const lookfrom = Point3.init(278, 278, -800);
    const lookat = Point3.init(278, 278, 0);
    const vup = Vec3.init(0, 1, 0);
    const dist_to_focus = 10.0;
    const aperture = 0.0;
    const vfov = 40.0;
    const time0 = 0.0;
    const time1 = 1.0;

    const cam = Camera.init(lookfrom, lookat, vup, vfov, aspect_ratio, aperture, dist_to_focus, time0, time1);

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
