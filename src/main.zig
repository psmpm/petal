const std = @import("std");
const Tokenizer = @import("Tokenizer.zig");

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

    const file = try std.Io.Dir.cwd().readFileAlloc(io, args[1], gpa, .unlimited);
    defer gpa.free(file);

    var tokenizer: Tokenizer = .{ .buffer = file };
    while (tokenizer.next()) |token| {
        try stdout.print("{} '{s}'\n", .{ token, file[token.loc.start..token.loc.end] });
        try stdout.flush();
    }
}
