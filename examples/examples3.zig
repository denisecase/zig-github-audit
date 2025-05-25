// src/main.zig
// This Zig program fetches GitHub repositories for a given user
// and writes repo names to a CSV file. It uses the `curl` command-line tool
// to make HTTP requests and the Zig standard library for JSON parsing and file I/O.

const std = @import("std");
const max_per_page = 100;
const input_file = "input.txt";
const output_file = "repos.csv";

pub fn main() !void {
    std.debug.print("Starting main\n", .{});

    // Define GitHub username for API call it could fail so use try
    const username = try getUsername(input_file);
    std.debug.print("Starting fetch for user: {s}\n", .{username});

    var page: usize = 1;
    var total_count: usize = 0;
    var allocator = std.heap.page_allocator;

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

// Fetches repositories for a given GitHub username and page number
// using the GitHub API.
// Returns a JSON object containing the repository data.
fn fetchReposPage(
    username: []const u8,
    page: usize,
    allocator_ptr: *std.mem.Allocator,
) !std.json.Parsed(std.json.Value) {

    // Construct the URL for the GitHub API request
    // using the username, max_per_page, and page number
    // The URL is formatted to include the username, max_per_page, and page number
    // The `try` keyword is used to handle any errors that may occur during the URL formatting
    // The `std.fmt.allocPrint` function is used to create a formatted string
    // The `defer` keyword is used to ensure that the allocated memory for the URL is freed
    // after the function returns
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

// getUsername reads a username from a file
// and returns it as a UTF-8 string slice.
fn getUsername(path: []const u8) ![]const u8 {
    const allocator = std.heap.page_allocator;
    std.debug.print("Reading username from file: {s}\n", .{path});

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    // Read entire file into buffer
    const stat = try file.stat();
    const size = stat.size;
    var buffer = try allocator.alloc(u8, size);
    defer allocator.free(buffer);

    _ = try file.readAll(buffer);

    // Trim trailing \r or \n
    var end = buffer.len;
    while (end > 0 and (buffer[end - 1] == '\r' or buffer[end - 1] == '\n')) {
        end -= 1;
    }

    const slice = buffer[0..end];

    // Validate
    if (!std.unicode.utf8ValidateSlice(slice)) {
        return error.InvalidUtf8Input;
    }

    // Make a separate owned copy
    const username = try allocator.alloc(u8, slice.len);
    @memcpy(username, slice);

    std.debug.print("Using username from file: {s}\n", .{username});
    return username;
}
