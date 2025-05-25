// src/main.zig
// This Zig program fetches GitHub repositories for a given user
// and writes repo names to a CSV file.

const std = @import("std");
const max_per_page = 100;
const output_file = "repos.csv";

pub fn main() !void {
    std.debug.print("Starting main\n", .{});
    var allocator = std.heap.page_allocator;

    var args = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args.deinit();

    _ = args.next(); 

    const username = args.next() orelse {
        const stderr = std.io.getStdErr().writer();
        try stderr.print(
            \\ERROR: Missing GitHub username. 
            \\Usage: zig build run -- <github-username>
            \\Example: zig build run -- denisecase
            \\Please try again. 
            \\
        , .{});
        return;
    };

    std.debug.print("Starting fetch for user: {s}\n", .{username});

    var page: usize = 1;
    var total_count: usize = 0;

    var file = try std.fs.cwd().createFile(output_file, .{});
    defer file.close();
    try file.writer().writeAll("name\n");

    while (true) {
        const repos = try fetchReposPage(username, page, &allocator);
        defer repos.deinit();

        const count = try writeRepoNamesToCSV(file.writer(), repos.value.array.items);
        std.debug.print("Page {d}. {d} repos written\n", .{ page, count });

        total_count += count;
        if (repos.value.array.items.len < max_per_page) break;

        page += 1;
    }

    std.debug.print("Wrote {d} total repositories to {s}\n", .{ total_count, output_file });
}

fn fetchReposPage(
    username: []const u8,
    page: usize,
    allocator_ptr: *std.mem.Allocator,
) !std.json.Parsed(std.json.Value) {

    const url = try std.fmt.allocPrint(allocator_ptr.*, "https://api.github.com/users/{s}/repos?per_page={d}&page={d}", .{ username, max_per_page, page });
    const allocator = allocator_ptr.*;
    defer allocator.free(url);

    std.debug.print("Fetching page {d}: {s}\n", .{ page, url });

    var stdout = std.ArrayListUnmanaged(u8){};
    defer stdout.deinit(allocator);
    var stderr = std.ArrayListUnmanaged(u8){};
    defer stderr.deinit(allocator);

    var child = std.process.Child.init(&[_][]const u8{
        "curl", "-s", "-H", "User-Agent: zig-client", url,
    }, allocator);

    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();
    try child.collectOutput(allocator, &stdout, &stderr, 1_000_000);
    _ = try child.wait();

    if (stderr.items.len > 0) {
        std.debug.print("stderr (page {d}):\n{s}\n", .{ page, stderr.items });
    }

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, stdout.items, .{});
    return parsed;
}

fn writeRepoNamesToCSV(
    writer: anytype,
    repos: []const std.json.Value,
) !usize {
    var count: usize = 0;

    for (repos) |repo| {
        const name_val = repo.object.get("full_name") orelse continue;
        if (name_val != .string) continue;

        const name = name_val.string;
        try writer.print("{s}\n", .{name});
        std.debug.print("- {s}\n", .{name});
        count += 1;
    }

    return count;
}

