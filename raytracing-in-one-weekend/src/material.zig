const hittable = @import("./hittable.zig");
const Hittable = hittable.Hittable;
const HitRecord = hittable.HitRecord;
const Ray = @import("./ray.zig").Ray;
const vec3 = @import("./vec3.zig");
const Color = vec3.Color;
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;
const unitVector = vec3.unitVector;
const randomInUnitSphere = vec3.randomInUnitSphere;
const randomUnitVector = vec3.randomUnitVector;
const reflect = vec3.reflect;

pub const Material = struct {
    scatterFn: fn (self: *const Material, r_in: Ray, rec: HitRecord, attenuation: *Color, scattered: *Ray) bool,

    pub fn scatter(self: *const Material, r_in: Ray, rec: HitRecord, attenuation: *Color, scattered: *Ray) bool {
        return self.scatterFn(self, r_in, rec, attenuation, scattered);
    }
};

pub const Lambertian = struct {
    material: Material,

    albedo: Color,

    pub fn init(a: Color) Lambertian {
        return .{
            .material = .{ .scatterFn = scatter },
            .albedo = a,
        };
    }

    pub fn scatter(material: *const Material, r_in: Ray, rec: HitRecord, attenuation: *Color, scattered: *Ray) bool {
        _ = r_in;
        const self = @fieldParentPtr(Lambertian, "material", material);
        var scatter_direction = rec.normal.add(randomUnitVector());
        if (scatter_direction.nearZero())
            scatter_direction = rec.normal;

        scattered.* = Ray.init(rec.p, scatter_direction);
        attenuation.* = self.albedo;
        return true;
    }
};

pub const Metal = struct {
    material: Material,

    albedo: Color,
    fuzz: f64,

    pub fn init(a: Color, f: f64) Metal {
        return .{
            .material = .{ .scatterFn = scatter },
            .albedo = a,
            .fuzz = if (f < 1) f else 1,
        };
    }

    pub fn scatter(material: *const Material, r_in: Ray, rec: HitRecord, attenuation: *Color, scattered: *Ray) bool {
        const self = @fieldParentPtr(Metal, "material", material);
        const reflected = reflect(unitVector(r_in.direction()), rec.normal);
        scattered.* = Ray.init(rec.p, reflected.add(randomInUnitSphere().multScalar(self.fuzz)));
        attenuation.* = self.albedo;
        return dot(scattered.direction(), rec.normal) > 0;
    }
};
