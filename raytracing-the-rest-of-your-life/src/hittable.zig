const std = @import("std");

const AABB = @import("./aabb.zig").AABB;
const Material = @import("./material.zig").Material;
const Ray = @import("./ray.zig").Ray;
const rtweekend = @import("./rtweekend.zig");
const degreesToRadians = rtweekend.degreesToRadians;
const infinity = rtweekend.infinity;

const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;

pub const HitRecord = struct {
    p: Point3,
    normal: Vec3,
    mat_ptr: *Material,
    t: f64,
    u: f64,
    v: f64,

    front_face: bool,

    pub fn setFaceNormal(self: *HitRecord, r: Ray, outward_normal: Vec3) void {
        self.front_face = dot(r.direction(), outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.negate();
    }
};

pub const Hittable = struct {
    hitFn: fn (self: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool,
    boundingBoxFn: fn (self: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool,

    pub fn hit(self: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        return self.hitFn(self, r, t_min, t_max, rec);
    }

    pub fn boundingBox(self: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        return self.boundingBoxFn(self, time0, time1, output_box);
    }
};

pub const Translate = struct {
    hittable: Hittable,

    ptr: *Hittable,
    offset: Vec3,

    pub fn init(p: *Hittable, displacement: Vec3) Translate {
        return .{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .ptr = p,
            .offset = displacement,
        };
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(Translate, "hittable", hittable);
        const moved_r = Ray.init(r.origin().sub(self.offset), r.direction(), r.time());
        if (!self.ptr.hit(moved_r, t_min, t_max, rec))
            return false;

        rec.p.addMut(self.offset);
        rec.setFaceNormal(moved_r, rec.normal);

        return true;
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        const self = @fieldParentPtr(Translate, "hittable", hittable);

        if (!self.ptr.boundingBox(time0, time1, output_box))
            return false;
        output_box.* = AABB.init(
            output_box.min().add(self.offset),
            output_box.max().add(self.offset),
        );

        return true;
    }
};

pub const RotateY = struct {
    hittable: Hittable,

    ptr: *Hittable,
    sin_theta: f64,
    cos_theta: f64,
    hasbox: bool,
    bbox: AABB,

    pub fn init(p: *Hittable, angle: f64) RotateY {
        const radians = degreesToRadians(angle);
        const sin_theta = @sin(radians);
        const cos_theta = @cos(radians);
        var bbox: AABB = undefined;
        const hasbox = p.boundingBox(0, 1, &bbox);

        var min = Point3.init(infinity, infinity, infinity);
        var max = Point3.init(-infinity, -infinity, -infinity);

        var i: usize = 0;
        while (i < 2) : (i += 1) {
            var j: usize = 0;
            while (j < 2) : (j += 1) {
                var k: usize = 0;
                while (k < 2) : (k += 1) {
                    const x = @intToFloat(f64, i) * bbox.max().x() + @intToFloat(f64, 1 - i) * bbox.min().x();
                    const y = @intToFloat(f64, i) * bbox.max().y() + @intToFloat(f64, 1 - i) * bbox.min().y();
                    const z = @intToFloat(f64, i) * bbox.max().z() + @intToFloat(f64, 1 - i) * bbox.min().z();

                    const newx = cos_theta * x + sin_theta * z;
                    const newz = -sin_theta * x + cos_theta * z;

                    const tester = Vec3.init(newx, y, newz);

                    var c: usize = 0;
                    while (c < 3) : (c += 1) {
                        min.atPtr(c).* = std.math.min(min.at(c), tester.at(c));
                        max.atPtr(c).* = std.math.max(max.at(c), tester.at(c));
                    }
                }
            }
        }
        return .{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .ptr = p,
            .sin_theta = sin_theta,
            .cos_theta = cos_theta,
            .hasbox = hasbox,
            .bbox = bbox,
        };
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(RotateY, "hittable", hittable);
        var origin = r.origin();
        var direction = r.direction();

        origin.atPtr(0).* = self.cos_theta * r.origin().at(0) - self.sin_theta * r.origin().at(2);
        origin.atPtr(2).* = self.sin_theta * r.origin().at(0) + self.cos_theta * r.origin().at(2);

        direction.atPtr(0).* = self.cos_theta * r.direction().at(0) - self.sin_theta * r.direction().at(2);
        direction.atPtr(2).* = self.sin_theta * r.direction().at(0) + self.cos_theta * r.direction().at(2);

        const rotated_r = Ray.init(origin, direction, r.time());

        if (!self.ptr.hit(rotated_r, t_min, t_max, rec))
            return false;

        var p = rec.p;
        var normal = rec.normal;

        p.atPtr(0).* = self.cos_theta * rec.p.at(0) + self.sin_theta * rec.p.at(2);
        p.atPtr(2).* = -self.sin_theta * rec.p.at(0) + self.cos_theta * rec.p.at(2);

        normal.atPtr(0).* = self.cos_theta * rec.normal.at(0) + self.sin_theta * rec.normal.at(2);
        normal.atPtr(2).* = -self.sin_theta * rec.normal.at(0) + self.cos_theta * rec.normal.at(2);

        rec.p = p;
        rec.setFaceNormal(rotated_r, normal);

        return true;
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        _ = time0;
        _ = time1;
        const self = @fieldParentPtr(RotateY, "hittable", hittable);
        output_box.* = self.bbox;
        return self.hasbox;
    }
};

pub const FlipFace = struct {
    hittable: Hittable,

    ptr: *Hittable,

    pub fn init(p: *Hittable) FlipFace {
        return .{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .ptr = p,
        };
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(FlipFace, "hittable", hittable);
        if (!self.ptr.hit(r, t_min, t_max, rec))
            return false;

        rec.front_face = !rec.front_face;
        return true;
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        const self = @fieldParentPtr(FlipFace, "hittable", hittable);
        return self.ptr.boundingBox(time0, time1, output_box);
    }
};
