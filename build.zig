// build.zig

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "github_audit",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });

    b.installArtifact(exe);

    // Add the `run` step:
    const run_cmd = b.addRunArtifact(exe);
    b.step("run", "Run the GitHub audit tool").dependOn(&run_cmd.step);
}

