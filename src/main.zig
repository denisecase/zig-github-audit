// src/main.zig

 // Import the standard library
const std = @import("std");

// Define the entry point of the program
// return an error if something fails
pub fn main() !void {

    std.debug.print("Starting main\n", .{});

     // Use page allocator for dynamic memory allocations
    const allocator = std.heap.page_allocator;

    const username = "denisecase";
    const url = try std.fmt.allocPrint(allocator,
        "https://api.github.com/users/{s}/repos?per_page=30", .{username});
    defer allocator.free(url);

    // Declare and defer cleanup of stdout buffer
    var stdout = std.ArrayListUnmanaged(u8){};
    defer stdout.deinit(allocator);

    // Initialize a child process that runs curl with the proper headers and URL
    var child = std.process.Child.init(&[_][]const u8{
        "curl", "-s", "-H", "User-Agent: zig-client", url,
    }, allocator);

    // Pipe output of curl for reading
    child.stdout_behavior = .Pipe;

    // Ignore any errors printed to stderr
    child.stderr_behavior = .Ignore;

    // Start the curl process
    try child.spawn();

    // Access the stdout stream from the child process
    const stdout_slice = stdout.items;    
    defer allocator.free(stdout_slice);

    // Wait for the process to finish (get exit status)
    _ = try child.wait();

    // alias just to shorten
    const json = std.json;

     // Parse the JSON response from GitHub into a dynamic structure
    const parsed = try json.parseFromSlice(json.Value, allocator, stdout.items, .{});
    
    // Free the memory used by the parsed JSON
    defer parsed.deinit();

    const repos = parsed.value.array;

    const repo_max = @min(repos.items.len, 3);

    var file = try std.fs.cwd().createFile("repos.csv", .{});
    // Ensure the file is closed when we’re done
    defer file.close();

    // Write CSV header
    try file.writer().writeAll("name\n");

    var repo_count: usize = 0;

    // Loop over each repository object in the JSON array
    for (repos.items) |repo| {
        // Stop after 3 entries
        if (repo_count >= repo_max) break;

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

    std.debug.print("Wrote repos.csv with {} repositories.\n", .{repos.items.len});
}
