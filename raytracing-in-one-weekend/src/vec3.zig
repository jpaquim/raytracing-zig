const std = @import("std");

pub const Vec3 = struct {
    e: [3]f64 = [_]f64{0} ** 3,

    pub fn init(e0: f64, e1: f64, e2: f64) Vec3 {
        return .{ .e = .{ e0, e1, e2 } };
    }

    pub fn x(self: Vec3) f64 {
        return self.e[0];
    }

    pub fn y(self: Vec3) f64 {
        return self.e[1];
    }

    pub fn z(self: Vec3) f64 {
        return self.e[2];
    }

    pub fn negate(self: Vec3) Vec3 {
        return .{ .e = .{ -self.e[0], -self.e[1], -self.e[2] } };
    }

    pub fn at(self: Vec3, index: usize) f64 {
        return self.e[index];
    }

    pub fn atPtr(self: Vec3, index: usize) *f64 {
        return &self.e[index];
    }

    pub fn addMut(self: *Vec3, v: Vec3) Vec3 {
        self.e[0] += v.e[0];
        self.e[1] += v.e[1];
        self.e[2] += v.e[2];
        return self.*;
    }

    pub fn multScalarMut(self: *Vec3, t: f64) Vec3 {
        self.e[0] *= t;
        self.e[1] *= t;
        self.e[2] *= t;
        return self.*;
    }

    pub fn divScalarMut(self: *Vec3, t: f64) Vec3 {
        return self.multScalarMut(1 / t).*;
    }

    pub fn length(self: Vec3) f64 {
        return std.math.sqrt(self.lengthSquared());
    }

    pub fn lengthSquared(self: Vec3) f64 {
        return self.e[0] * self.e[0] + self.e[1] * self.e[1] + self.e[2] * self.e[2];
    }

    pub fn print(out: std.fs.File.Writer, v: Vec3) !void {
        try out.print("{} {} {}", .{ v.e[0], v.e[1], v.e[2] });
    }

    pub fn add(u: Vec3, v: Vec3) Vec3 {
        return Vec3.init(u.e[0] + v.e[0], u.e[1] + v.e[1], u.e[2] + v.e[2]);
    }

    pub fn sub(u: Vec3, v: Vec3) Vec3 {
        return Vec3.init(u.e[0] - v.e[0], u.e[1] - v.e[1], u.e[2] - v.e[2]);
    }

    pub fn mult(u: Vec3, v: Vec3) Vec3 {
        return Vec3.init(u.e[0] * v.e[0], u.e[1] * v.e[1], u.e[2] * v.e[2]);
    }

    pub fn multScalar(t: f64, u: Vec3) Vec3 {
        return Vec3.init(t * u.e[0], t * u.e[1], t * u.e[2]);
    }

    pub fn multScalar2(v: Vec3, t: f64) Vec3 {
        return multScalar(t, v);
    }

    pub fn divScalar(v: Vec3, t: f64) Vec3 {
        return multScalar(1 / t, v);
    }

    pub fn dot(u: Vec3, v: Vec3) Vec3 {
        return u.e[0] * v.e[0] + u.e[1] * v.e[1] + u.e[2] * v.e[2];
    }

    pub fn cross(u: Vec3, v: Vec3) Vec3 {
        return Vec3.init(
            u.e[1] * v.e[2] - u.e[2] * v.e[1],
            u.e[2] * v.e[0] - u.e[0] * v.e[2],
            u.e[0] * v.e[1] - u.e[1] * v.e[0],
        );
    }

    pub fn unitVector(v: Vec3) Vec3 {
        return v / v.length();
    }
};

pub const Point3 = Vec3;
pub const Color = Vec3;
