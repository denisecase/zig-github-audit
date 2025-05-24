const std = @import("std");

pub fn main() !void {

    std.debug.print("Hello, Zig on Windows!\n", .{});

    // Create the CSV file
    var file = try std.fs.cwd().createFile("repos.csv", .{});
    defer file.close();

    // Write CSV header
    try file.writer().writeAll("name\n");

    // Write 3 dummy repo names
    try file.writer().writeAll("denisecase/repo1\n");
    try file.writer().writeAll("denisecase/repo2\n");
    try file.writer().writeAll("denisecase/repo3\n");

    std.debug.print("Wrote repos.csv with 3 hardcoded entries.\n", .{});
}
