const std = @import("std");
const sqrt = std.math.sqrt;

const hittable = @import("./hittable.zig");
const Hittable = hittable.Hittable;
const ONB = @import("./onb.zig").ONB;
const rtweekend = @import("./rtweekend.zig");
const randomDouble = rtweekend.randomDouble;
const pi = rtweekend.pi;
const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;
const unitVector = vec3.unitVector;

pub fn randomCosineDirection() Vec3 {
    const r1 = randomDouble();
    const r2 = randomDouble();
    const z = sqrt(1 - r2);

    const phi = 2 * pi * r1;
    const x = @cos(phi) * 2 * sqrt(r2);
    const y = @sin(phi) * 2 * sqrt(r2);

    return Vec3.init(x, y, z);
}

pub const PDF = struct {
    deinitFn: fn (self: *PDF) void = deinitDefault,
    valueFn: fn (self: *const PDF, direction: Vec3) f64,
    generateFn: fn (self: *const PDF) Vec3,

    pub fn deinit(self: *PDF) void {
        self.deinitFn();
    }

    pub fn deinitDefault(self: *PDF) void {
        _ = self;
    }

    pub fn value(self: *const PDF, direction: Vec3) f64 {
        return self.valueFn(self, direction);
    }

    pub fn generate(self: *const PDF) Vec3 {
        return self.generateFn(self);
    }
};

pub const CosinePDF = struct {
    pdf: PDF,

    uvw: ONB,

    pub fn init(w: Vec3) CosinePDF {
        var self = CosinePDF{
            .pdf = .{ .valueFn = value, .generateFn = generate },
            .uvw = ONB.init(),
        };
        self.uvw.buildFromW(w);
        return self;
    }

    pub fn value(pdf: *const PDF, direction: Vec3) f64 {
        const self = @fieldParentPtr(CosinePDF, "pdf", pdf);
        const cosine = dot(unitVector(direction), self.uvw.w());
        return if (cosine <= 0) 0 else cosine / pi;
    }

    pub fn generate(pdf: *const PDF) Vec3 {
        const self = @fieldParentPtr(CosinePDF, "pdf", pdf);
        return self.uvw.local(randomCosineDirection());
    }
};

pub const HittablePDF = struct {
    pdf: PDF,

    o: Point3,
    ptr: *Hittable,

    pub fn init(p: *Hittable, origin: Point3) HittablePDF {
        return .{
            .pdf = .{ .valueFn = value, .generateFn = generate },
            .ptr = p,
            .o = origin,
        };
    }

    pub fn value(pdf: *const PDF, direction: Vec3) f64 {
        const self = @fieldParentPtr(HittablePDF, "pdf", pdf);
        return self.ptr.pdfValue(self.o, direction);
    }

    pub fn generate(pdf: *const PDF) Vec3 {
        const self = @fieldParentPtr(HittablePDF, "pdf", pdf);
        return self.ptr.random(self.o);
    }
};

pub const MixturePDF = struct {
    pdf: PDF,

    p: [2]*PDF,

    pub fn init(p0: *PDF, p1: *PDF) MixturePDF {
        return .{
            .pdf = .{ .valueFn = value, .generateFn = generate },
            .p = .{ p0, p1 },
        };
    }

    pub fn value(pdf: *const PDF, direction: Vec3) f64 {
        const self = @fieldParentPtr(MixturePDF, "pdf", pdf);
        return 0.5 * self.p[0].value(direction) + 0.5 * self.p[1].value(direction);
    }

    pub fn generate(pdf: *const PDF) Vec3 {
        const self = @fieldParentPtr(MixturePDF, "pdf", pdf);
        if (randomDouble() < 0.5)
            return self.p[0].generate()
        else
            return self.p[1].generate();
    }
};

pub fn randomToSphere(radius: f64, distance_squared: f64) Vec3 {
    const r1 = randomDouble();
    const r2 = randomDouble();
    const z = 1 + r2 * (sqrt(1 - radius * radius / distance_squared) - 1);

    const phi = 2 * pi * r1;
    const x = @cos(phi) * sqrt(1 - z * z);
    const y = @sin(phi) * sqrt(1 - z * z);

    return Vec3.init(x, y, z);
}
