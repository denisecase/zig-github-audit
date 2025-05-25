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

    b.installArtifact(exe); // installs to zig-out/bin/github_audit(.exe)

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    b.step("run", "Build and run").dependOn(&run_cmd.step);
}
