const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len == 1) {
        try stdout.print("supply a file\n", .{});
        try stdout.flush();
        return;
    }

    const file = try std.Io.Dir.cwd().readFileAlloc(io, args[1], gpa, .limited(std.math.maxInt(u32)));
    defer gpa.free(file);

    try stdout.print("---\n{s}\n---\n", .{file});
    try stdout.flush();
}
