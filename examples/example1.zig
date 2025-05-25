// example1.zig - learning syntax

// Define std as import from standard library
const std = @import("std");

// Define const name;
const name = "Zig on Windows";

// Define a constant named output_file
// output_file is a string that will be used as the name of the CSV file
// The file will be created in the current working directory
const output_file = "output1.csv";

// Define a public function named main 
// main is the main entry point for the file logic
// !void means this function returns:
//   - nothing (void), if successful
//   - an error, if something goes wrong
//
// This is Zig's way of expressing that a function may fail
pub fn main() !void {

    // Use std.debug.print() to send message to terminal
    // print takes 2 arguments:
    //   1. A format string
    //   2. A tuple (written as .{ ... }) with values to fill placeholders in the format string
    //
    // .{} is an empty tuple, used when the format string has no placeholders.
    // {s} is a placeholder for a string (short for slice of bytes, like []const u8).
    // You must use {s} or {any} instead of {} for strings in Zig.
    // The `\n` at the end will start a new line.

    std.debug.print("Hello, Zig on Windows!\n", .{});
    std.debug.print("Hello, {s}!\n", .{name});

    // Create CSV file
    // use std fs (file system) cwd() to get current working directory
    // and createFile() function to create a named csv file in this folder.
    // Define a variable named file to hold a reference to file created. 
    var file = try std.fs.cwd().createFile(output_file, .{});

    // Tell it to close the file when done.
    defer file.close();

    // Write CSV header
    try file.writer().writeAll("name\n");

    // Write 3 dummy repo names
    try file.writer().writeAll("github_user/repo1\n");
    try file.writer().writeAll("github_user/repo2\n");
    try file.writer().writeAll("github_user/repo3\n");

    std.debug.print("Wrote {s} with 3 hardcoded entries.\n", .{output_file});
}
