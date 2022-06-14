const std = @import("std");
const Allocator = std.mem.Allocator;

const aabb = @import("./aabb.zig");
const AABB = aabb.AABB;
const surroundingBox = aabb.surroundingBox;

const h = @import("./hittable.zig");
const Hittable = h.Hittable;
const HitRecord = h.HitRecord;

const Ray = @import("./ray.zig").Ray;

const vec3 = @import("./vec3.zig");
const Point3 = vec3.Point3;
const Vec3 = vec3.Vec3;
const dot = vec3.dot;
const unitVector = vec3.unitVector;

pub const HittableList = struct {
    hittable: Hittable,

    objects: std.ArrayList(*Hittable),

    pub fn init(allocator: Allocator) HittableList {
        return .{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .objects = std.ArrayList(*Hittable).init(allocator),
        };
    }

    pub fn deinit(self: *HittableList) void {
        self.objects.deinit();
    }

    pub fn add(self: *HittableList, object: *Hittable) !void {
        try self.objects.append(object);
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(HittableList, "hittable", hittable);

        var temp_rec: HitRecord = undefined;
        var hit_anything = false;
        var closest_so_far = t_max;

        for (self.objects.items) |object| {
            if (object.hit(r, t_min, closest_so_far, &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec.* = temp_rec;
            }
        }

        return hit_anything;
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        const self = @fieldParentPtr(HittableList, "hittable", hittable);
        if (self.objects.items.len == 0) return false;

        var temp_box: AABB = undefined;
        var first_box = true;

        for (self.objects.items) |object| {
            if (!object.boundingBox(time0, time1, &temp_box)) return false;
            output_box.* = if (first_box) temp_box else surroundingBox(output_box.*, temp_box);
            first_box = false;
        }

        return true;
    }
};
