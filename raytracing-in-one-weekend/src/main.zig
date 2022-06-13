const std = @import("std");
const writeColor = @import("./color.zig").writeColor;
const Color = @import("./vec3.zig").Color;

pub fn main() anyerror!void {
    const image_width = 256;
    const image_height = 256;

    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    var j: usize = image_height;
    while (j > 0) {
        j -= 1;
        try stderr.print("\rScanlines remaining: {}", .{j});
        var i: usize = 0;
        while (i < image_width) : (i += 1) {
            const pixel_color = Color.init(
                @intToFloat(f64, i) / (image_width - 1),
                @intToFloat(f64, j) / (image_height - 1),
                0.25,
            );
            try writeColor(stdout, pixel_color);
        }
    }

    try stderr.writeAll("\nDone.\n");
}
