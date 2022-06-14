const std = @import("std");

pub const infinity = std.math.f64_max;
pub const pi = std.math.pi;

pub fn degreesToRadians(degrees: f64) f64 {
    return degrees * pi / 180.0;
}

pub fn randomDouble() f64 {
    const State = struct {
        var seed: u64 = 0;
        var prng: std.rand.DefaultPrng = undefined;
        var rand: std.rand.Random = undefined;

        fn init() void {
            std.os.getrandom(std.mem.asBytes(&seed)) catch std.process.exit(1);
            prng = std.rand.DefaultPrng.init(seed);
            rand = prng.random();
        }
    };
    if (State.seed == 0) State.init();

    return State.rand.float(f64);
}

pub fn randomDouble2(min: f64, max: f64) f64 {
    return min + (max - min) * randomDouble();
}

pub fn clamp(x: f64, min: f64, max: f64) f64 {
    if (x < min) return min;
    if (x > max) return max;
    return x;
}
