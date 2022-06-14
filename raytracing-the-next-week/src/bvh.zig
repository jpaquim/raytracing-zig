const std = @import("std");
const Allocator = std.mem.Allocator;

const aabb = @import("./aabb.zig");
const AABB = aabb.AABB;
const surroundingBox = aabb.surroundingBox;

const h = @import("./hittable.zig");
const HitRecord = h.HitRecord;
const Hittable = h.Hittable;
const HittableList = @import("./hittable_list.zig").HittableList;

const Ray = @import("./ray.zig").Ray;

const rtweekend = @import("./rtweekend.zig");
const randomInt = rtweekend.randomInt;

const stderr = std.io.getStdErr().writer();

pub const BvhNode = struct {
    hittable: Hittable,

    left: *Hittable,
    right: *Hittable,
    box: AABB,

    pub fn init(allocator: Allocator, list: HittableList, time0: f64, time1: f64) !BvhNode {
        return init2(allocator, list.objects, 0, list.objects.items.len, time0, time1);
    }

    pub fn init2(
        allocator: Allocator,
        src_objects_: std.ArrayList(*Hittable),
        start: usize,
        end: usize,
        time0: f64,
        time1: f64,
    ) (error{OutOfMemory} || std.os.WriteError)!BvhNode {
        var src_objects = src_objects_;
        var objects = try src_objects.clone();

        const axis = randomInt(0, 2);
        const comparator = if (axis == 0)
            box_x_compare
        else if (axis == 1)
            box_y_compare
        else
            box_z_compare;

        const object_span = end - start;

        var left: *Hittable = undefined;
        var right: *Hittable = undefined;
        if (object_span == 1) {
            left = objects.items[start];
            right = left;
        } else if (object_span == 2) {
            if (comparator({}, objects.items[start], objects.items[start + 1])) {
                left = objects.items[start];
                right = objects.items[start + 1];
            } else {
                left = objects.items[start + 1];
                right = objects.items[start];
            }
        } else {
            if (axis == 0)
                std.sort.sort(*Hittable, objects.items, {}, box_x_compare)
            else if (axis == 1)
                std.sort.sort(*Hittable, objects.items, {}, box_y_compare)
            else
                std.sort.sort(*Hittable, objects.items, {}, box_z_compare);

            const mid = start + object_span / 2;
            var left_node = try allocator.create(BvhNode);
            left_node.* = try BvhNode.init2(allocator, objects, start, mid, time0, time1);
            left = &left_node.hittable;
            var right_node = try allocator.create(BvhNode);
            right_node.* = try BvhNode.init2(allocator, objects, mid, end, time0, time1);
            right = &right_node.hittable;
        }

        var box_left: AABB = undefined;
        var box_right: AABB = undefined;

        if (!left.boundingBox(time0, time1, &box_left) or !right.boundingBox(time0, time1, &box_right))
            try stderr.writeAll("No bounding box in BvhNode constructor.\n");

        const box = surroundingBox(box_left, box_right);

        return BvhNode{
            .hittable = .{ .hitFn = hit, .boundingBoxFn = boundingBox },
            .left = left,
            .right = right,
            .box = box,
        };
    }

    fn hit(hittable: *const Hittable, r: Ray, t_min: f64, t_max: f64, rec: *HitRecord) bool {
        const self = @fieldParentPtr(BvhNode, "hittable", hittable);
        if (!self.box.hit(r, t_min, t_max))
            return false;

        const hit_left = self.left.hit(r, t_min, t_max, rec);
        const hit_right = self.right.hit(r, t_min, if (hit_left) rec.t else t_max, rec);

        return hit_left or hit_right;
    }

    fn boundingBox(hittable: *const Hittable, time0: f64, time1: f64, output_box: *AABB) bool {
        _ = time0;
        _ = time1;
        const self = @fieldParentPtr(BvhNode, "hittable", hittable);
        output_box.* = self.box;
        return true;
    }
};

fn boxCompare(a: *Hittable, b: *Hittable, axis: usize) bool {
    var box_a: AABB = undefined;
    var box_b: AABB = undefined;

    if (!a.boundingBox(0, 0, &box_a) or !b.boundingBox(0, 0, &box_b))
        stderr.writeAll("No bounding box in BvhNode constructor.\n") catch unreachable;

    return box_a.min().e[axis] < box_b.min().e[axis];
}

fn box_x_compare(_: void, a: *Hittable, b: *Hittable) bool {
    return boxCompare(a, b, 0);
}

fn box_y_compare(_: void, a: *Hittable, b: *Hittable) bool {
    return boxCompare(a, b, 1);
}

fn box_z_compare(_: void, a: *Hittable, b: *Hittable) bool {
    return boxCompare(a, b, 2);
}
