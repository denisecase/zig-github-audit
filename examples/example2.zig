// example2.zig - framing the code

const std = @import("std");

const input_file = "input.txt";
const output_file = "output2.csv";

pub fn main() !void {

    std.debug.print("Starting main\n", .{});

    // Define GitHub username for API call it could fail so use try
    const username = try getUsername(input_file);

    // Define GitHub API URL template with username placeholder
    const url_template = "https://api.github.com/users/{s}/repos?per_page=30";

    // Use page allocator for dynamic memory allocations & defer cleanup
    const allocator = std.heap.page_allocator;

    const url = try std.fmt.allocPrint(allocator, url_template, .{username});
    defer allocator.free(url);

    std.debug.print("URL: {s}\n", .{url});

    // Declare and defer cleanup of stdout buffer
    var stdout = std.ArrayListUnmanaged(u8){};
    defer stdout.deinit(allocator);

    // Initialize a child process that runs curl with the proper headers and URL
    var child = std.process.Child.init(&[_][]const u8{
        "curl", "-s", "-H", "User-Agent: zig-client", url,
    }, allocator);

    // Pipe output of curl for reading
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    // Start the curl process
    try child.spawn();
    std.debug.print("Child process spawned\n", .{});

    var stderr = std.ArrayListUnmanaged(u8){};
    defer stderr.deinit(allocator);

    // collect output up to 1MB
    try child.collectOutput(allocator, &stdout, &stderr, 1_000_000);
    const exit_status = try child.wait();

    if (exit_status != .Exited or exit_status.Exited != 0) {
        std.debug.print("curl exited with non-zero status\n", .{});
        return error.CurlFailed;
    }

    // After process completes, print stderr if not empty
    if (stderr.items.len > 0) {
        std.debug.print("stderr from curl:\n{s}\n", .{stderr.items});
    }

     // Parse the JSON response from GitHub into a dynamic structure
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, stdout.items, .{});
    defer parsed.deinit();

    std.debug.print("Parsed JSON response\n", .{});

    const repos = parsed.value.array;

    // Check if the parsed JSON is an array
    if (repos.items.len == 0) {
        std.debug.print("No repositories found for user {s}\n", .{username});
        return;
    }
    else {
        std.debug.print("Found {} repositories for user {s}\n", .{repos.items.len, username});
    }

    var file = try std.fs.cwd().createFile(output_file, .{});
    defer file.close();

    // Write CSV header
    try file.writer().writeAll("name\n");

    var repo_count: usize = 0;

    // Loop over each repository object in the JSON array
    for (repos.items) |repo| {

        // Get the "full_name" field (e.g., user/repo), skip if missing
        const name_val = repo.object.get("full_name") orelse continue;
        
        // Skip if it's not a string
        if (name_val != .string) continue;

        // Extract the actual string value
        const name = name_val.string;

        // Print the repo name to debug output
        std.debug.print("- {s}\n", .{name});

        // Write to CSV file
        try file.writer().print("{s}\n", .{name});

        repo_count += 1;
    }

    std.debug.print("Wrote {s} with {} repositories.\n", .{output_file, repos.items.len});
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
