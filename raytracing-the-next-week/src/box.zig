const std = @import("std");
const Allocator = std.mem.Allocator;

const AABB = @import("./aabb.zig").AABB;

const aarect = @import("./aarect.zig");
const XyRect = aarect.XyRect;
const XzRect = aarect.XzRect;
const YzRect = aarect.YzRect;

const h = @import("./hittable.zig");
const Hittable = h.Hittable;
const HitRecord = h.HitRecord;
const HittableList = @import("./hittable_list.zig").HittableList;

const Material = @import("./material.zig").Material;
const Ray = @import("./ray.zig").Ray;

const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;

pub const Box = struct {
    hittable: Hittable,

    box_min: Point3,
    box_max: Point3,
    sides: HittableList,

    pub fn init(allocator: Allocator, p0: Point3, p1: Point3, ptr: *Material) !Box {
        var sides = HittableList.init(allocator);

        {
            var r = try allocator.create(XyRect);
            r.* = XyRect.init(p0.x(), p1.x(), p0.y(), p1.y(), p1.z(), ptr);
            try sides.add(&r.hittable);
        }
        {
            var r = try allocator.create(XyRect);
            r.* = XyRect.init(p0.x(), p1.x(), p0.y(), p1.y(), p0.z(), ptr);
            try sides.add(&r.hittable);
        }

        {
            var r = try allocator.create(XzRect);
            r.* = XzRect.init(p0.x(), p1.x(), p0.z(), p1.z(), p1.y(), ptr);
            try sides.add(&r.hittable);
        }
        {
            var r = try allocator.create(XzRect);
            r.* = XzRect.init(p0.x(), p1.x(), p0.z(), p1.z(), p0.y(), ptr);
            try sides.add(&r.hittable);
        }

        {
            var r = try allocator.create(YzRect);
            r.* = YzRect.init(p0.y(), p1.y(), p0.z(), p1.z(), p1.x(), ptr);
            try sides.add(&r.hittable);
        }
        {
            var r = try allocator.create(YzRect);
            r.* = YzRect.init(p0.y(), p1.y(), p0.z(), p1.z(), p0.x(), ptr);
            try sides.add(&r.hittable);
        }

        return Box{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .box_min = p0,
            .box_max = p1,
            .sides = sides,
        };
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(Box, "hittable", hittable);
        return self.sides.hittable.hit(r, t_min, t_max, rec);
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        _ = time0;
        _ = time1;
        const self = @fieldParentPtr(Box, "hittable", hittable);
        output_box.* = AABB.init(self.box_min, self.box_max);
        return true;
    }
};
