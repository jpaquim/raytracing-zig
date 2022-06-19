const std = @import("std");
const sqrt = std.math.sqrt;

const clamp = @import("./rtweekend.zig").clamp;
const Color = @import("./vec3.zig").Color;

pub fn writeColor(out: std.fs.File.Writer, pixel_color: Color, samples_per_pixel: usize) !void {
    var r = pixel_color.x();
    var g = pixel_color.y();
    var b = pixel_color.z();

    if (r != r) r = 0.0;
    if (g != g) g = 0.0;
    if (b != b) b = 0.0;

    const scale = 1.0 / @intToFloat(f64, samples_per_pixel);
    r = sqrt(scale * r);
    g = sqrt(scale * g);
    b = sqrt(scale * b);

    try out.print("{} {} {}\n", .{
        @floatToInt(u8, 256 * clamp(r, 0.0, 0.999)),
        @floatToInt(u8, 256 * clamp(g, 0.0, 0.999)),
        @floatToInt(u8, 256 * clamp(b, 0.0, 0.999)),
    });
}
