const std = @import("std");

const Color = @import("./vec3.zig").Color;

pub fn writeColor(out: std.fs.File.Writer, pixel_color: Color) !void {
    try out.print("{} {} {}\n", .{
        @floatToInt(u8, 255.999 * pixel_color.x()),
        @floatToInt(u8, 255.999 * pixel_color.y()),
        @floatToInt(u8, 255.999 * pixel_color.z()),
    });
}
