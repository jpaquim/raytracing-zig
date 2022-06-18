const vec3 = @import("./vec3.zig");
const Vec3 = vec3.Vec3;
const cross = vec3.cross;
const unitVector = vec3.unitVector;

pub const ONB = struct {
    axis: [3]Vec3 = [_]Vec3{Vec3.init(0, 0, 0)} ** 3,

    pub fn init() ONB {
        return .{};
    }

    pub fn at(self: ONB, index: usize) Vec3 {
        return self.axis[index];
    }

    pub fn u(self: ONB) Vec3 {
        return self.axis[0];
    }

    pub fn v(self: ONB) Vec3 {
        return self.axis[1];
    }

    pub fn w(self: ONB) Vec3 {
        return self.axis[2];
    }

    pub fn local(self: ONB, a: Vec3) Vec3 {
        return self.u().multScalar(a.x()).add(self.v().multScalar(a.y())).add(self.w().multScalar(a.z()));
    }

    pub fn local2(self: ONB, a: f64, b: f64, c: f64) Vec3 {
        return self.u().multScalar(a).add(self.v().multScalar(b)).add(self.w().multScalar(c));
    }

    pub fn buildFromW(self: *ONB, n: Vec3) void {
        self.axis[2] = unitVector(n);
        const a = if (@fabs(self.w().x()) > 0.9) Vec3.init(0, 1, 0) else Vec3.init(1, 0, 0);
        self.axis[1] = unitVector(cross(self.w(), a));
        self.axis[0] = cross(self.w(), self.v());
    }
};
