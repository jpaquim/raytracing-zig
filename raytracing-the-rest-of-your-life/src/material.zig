const std = @import("std");
const Allocator = std.mem.Allocator;

const min = std.math.min;
const pow = std.math.pow;
const sqrt = std.math.sqrt;

const hittable = @import("./hittable.zig");
const Hittable = hittable.Hittable;
const HitRecord = hittable.HitRecord;

const randomCosineDirection = @import("./cos_density.zig").randomCosineDirection;
const ONB = @import("./onb.zig").ONB;
const pdf = @import("./pdf.zig");
const CosinePDF = pdf.CosinePDF;
const PDF = pdf.PDF;
const Ray = @import("./ray.zig").Ray;
const rtweekend = @import("./rtweekend.zig");
const makePtr = rtweekend.makePtr;
const pi = rtweekend.pi;
const randomDouble = rtweekend.randomDouble;

const texture = @import("./texture.zig");
const SolidColor = texture.SolidColor;
const Texture = texture.Texture;

const vec3 = @import("./vec3.zig");
const Color = vec3.Color;
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;
const unitVector = vec3.unitVector;
const randomInHemisphere = vec3.randomInHemisphere;
const randomInUnitSphere = vec3.randomInUnitSphere;
const randomUnitVector = vec3.randomUnitVector;
const reflect = vec3.reflect;
const refract = vec3.refract;

pub const ScatterRecord = struct {
    specular_ray: Ray,
    is_specular: bool,
    attenuation: Color,
    pdf_ptr: *PDF,
};

pub const Material = struct {
    emittedFn: fn (self: *const Material, r_in: Ray, rec: HitRecord, u: f64, v: f64, p: Point3) Color = emittedDefault,
    scatterFn: fn (self: *const Material, r_in: Ray, rec: HitRecord, srec: *ScatterRecord) bool = scatterDefault,
    scatteringPdfFn: fn (self: *const Material, r_in: Ray, rec: HitRecord, scattered: Ray) f64 = scatteringPdfDefault,

    pub fn scatter(self: *const Material, r_in: Ray, rec: HitRecord, srec: *ScatterRecord) bool {
        return self.scatterFn(self, r_in, rec, srec);
    }

    pub fn scatterDefault(self: *const Material, r_in: Ray, rec: HitRecord, srec: *ScatterRecord) bool {
        _ = self;
        _ = r_in;
        _ = rec;
        _ = srec;
        return false;
    }

    pub fn scatteringPdf(self: *const Material, r_in: Ray, rec: HitRecord, scattered: Ray) f64 {
        return self.scatteringPdfFn(self, r_in, rec, scattered);
    }

    pub fn scatteringPdfDefault(self: *const Material, r_in: Ray, rec: HitRecord, scattered: Ray) f64 {
        _ = self;
        _ = r_in;
        _ = rec;
        _ = scattered;
        return 0;
    }

    pub fn emitted(self: *const Material, r_in: Ray, rec: HitRecord, u: f64, v: f64, p: Point3) Color {
        return self.emittedFn(self, r_in, rec, u, v, p);
    }

    fn emittedDefault(self: *const Material, r_in: Ray, rec: HitRecord, u: f64, v: f64, p: Point3) Color {
        _ = self;
        _ = r_in;
        _ = rec;
        _ = u;
        _ = v;
        _ = p;
        return Color.init(0, 0, 0);
    }
};

pub const Lambertian = struct {
    material: Material,
    allocator: Allocator,

    albedo: *Texture,

    pub fn init(allocator: Allocator, a: *Texture) Lambertian {
        return .{
            .material = .{ .scatterFn = scatter, .scatteringPdfFn = scatteringPdf },
            .allocator = allocator,
            .albedo = a,
        };
    }

    pub fn initColor(allocator: Allocator, a: Color) !Lambertian {
        return Lambertian.init(allocator, &(try makePtr(allocator, SolidColor, .{a})).texture);
    }

    fn scatter(material: *const Material, r_in: Ray, rec: HitRecord, srec: *ScatterRecord) bool {
        _ = r_in;
        const self = @fieldParentPtr(Lambertian, "material", material);
        srec.is_specular = false;
        srec.attenuation = self.albedo.value(rec.u, rec.v, rec.p);
        srec.pdf_ptr = &(makePtr(self.allocator, CosinePDF, .{rec.normal}) catch std.process.exit(1)).pdf;
        return true;
    }

    fn scatteringPdf(material: *const Material, r_in: Ray, rec: HitRecord, scattered: Ray) f64 {
        _ = material;
        _ = r_in;
        const cosine = dot(rec.normal, unitVector(scattered.direction()));
        return if (cosine < 0) 0 else cosine / pi;
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

    fn scatter(material: *const Material, r_in: Ray, rec: HitRecord, srec: *ScatterRecord) bool {
        const self = @fieldParentPtr(Metal, "material", material);
        const reflected = reflect(unitVector(r_in.direction()), rec.normal);
        srec.specular_ray = Ray.init(rec.p, reflected.add(randomInUnitSphere().multScalar(self.fuzz)), r_in.time());
        srec.attenuation = self.albedo;
        srec.is_specular = true;
        srec.pdf_ptr = @as(*Material, undefined);
        return true;
    }
};

pub const Dielectric = struct {
    material: Material,

    ir: f64,

    pub fn init(index_of_refraction: f64) Dielectric {
        return .{
            .material = .{ .scatterFn = scatter },
            .ir = index_of_refraction,
        };
    }

    fn scatter(material: *const Material, r_in: Ray, rec: HitRecord, srec: *ScatterRecord) bool {
        const self = @fieldParentPtr(Dielectric, "material", material);
        srec.is_specular = true;
        srec.pdf_ptr = @as(*Material, undefined);
        srec.attenuation = Color.init(1, 1, 1);
        const refraction_ratio = if (rec.front_face) 1.0 / self.ir else self.ir;

        const unit_direction = unitVector(r_in.direction());
        const cos_theta = min(dot(unit_direction.negate(), rec.normal), 1.0);
        const sin_theta = sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = refraction_ratio * sin_theta > 1.0;

        const direction = if (cannot_refract or reflectance(cos_theta, refraction_ratio) > randomDouble())
            reflect(unit_direction, rec.normal)
        else
            refract(unit_direction, rec.normal, refraction_ratio);

        srec.specular_ray = Ray.init(rec.p, direction, r_in.time());
        return true;
    }

    fn reflectance(cosine: f64, ref_idx: f64) f64 {
        var r0 = (1 - ref_idx) / (1 + ref_idx);
        r0 = r0 * r0;
        return r0 + (1 - r0) * pow(f64, 1 - cosine, 5);
    }
};

pub const DiffuseLight = struct {
    material: Material,

    emit: *Texture,

    pub fn init(a: *Texture) DiffuseLight {
        return .{
            .material = .{ .scatterFn = scatter, .emittedFn = emitted },
            .emit = a,
        };
    }

    pub fn initColor(allocator: Allocator, c: Color) !DiffuseLight {
        return DiffuseLight.init(&(try makePtr(allocator, SolidColor, .{c})).texture);
    }

    fn scatter(material: *const Material, r_in: Ray, rec: HitRecord, srec: *ScatterRecord) bool {
        _ = material;
        _ = r_in;
        _ = r_in;
        _ = rec;
        _ = srec;
        return false;
    }

    fn emitted(material: *const Material, r_in: Ray, rec: HitRecord, u: f64, v: f64, p: Point3) Color {
        _ = r_in;
        const self = @fieldParentPtr(DiffuseLight, "material", material);
        if (rec.front_face)
            return self.emit.value(u, v, p)
        else
            return Color.init(0, 0, 0);
    }
};

// pub const Isotropic = struct {
//     material: Material,

//     albedo: *Texture,

//     pub fn init(a: *Texture) Isotropic {
//         return .{
//             .material = .{ .scatterFn = scatter },
//             .albedo = a,
//         };
//     }

//     pub fn initColor(allocator: Allocator, c: Color) !Isotropic {
//         return Isotropic.init(&(try makePtr(allocator, SolidColor, .{c})).texture);
//     }

//     fn scatter(material: *const Material, r_in: Ray, rec: HitRecord, attenuation: *Color, scattered: *Ray) bool {
//         const self = @fieldParentPtr(Isotropic, "material", material);
//         scattered.* = Ray.init(rec.p, randomInUnitSphere(), r_in.time());
//         attenuation.* = self.albedo.value(rec.u, rec.v, rec.p);
//         return false;
//     }
// };
