const std = @import("std");

pub fn main() anyerror!void {
    const image_width = 256;
    const image_height = 256;

    const stdout = std.io.getStdOut().writer();

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });

    var j: usize = image_height;
    while (j > 0) {
        j -= 1;
        var i: usize = 0;
        while (i < image_width) : (i += 1) {
            const r = @intToFloat(f64, i) / (image_width - 1);
            const g = @intToFloat(f64, j) / (image_height - 1);
            const b = 0.25;

            const ir = @floatToInt(u8, 255.999 * r);
            const ig = @floatToInt(u8, 255.999 * g);
            const ib = @floatToInt(u8, 255.999 * b);

            try stdout.print("{} {} {}\n", .{ ir, ig, ib });
        }
    }
}
