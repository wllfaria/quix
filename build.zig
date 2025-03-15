const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/main.zig");

    const quix_winapi = b.dependency("quix_winapi", .{
        .target = target,
        .optimize = optimize,
    });

    const quix_mod = b.addModule("quix", .{
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
    });
    quix_mod.addImport("quix_winapi", quix_winapi.module("quix_winapi"));

    const lib_unit_tests = b.addTest(.{
        .root_module = quix_mod,
        .target = target,
        .optimize = optimize,
    });

    setupExamples(b, quix_mod, target, optimize);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

const Examples = enum {
    read_event,
};

fn setupExamples(
    b: *std.Build,
    quix_mod: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const example_step = b.step("example", "Run example");

    const example_opt = b.option(
        Examples,
        "example",
        "Example to show (default: read_event)",
    ) orelse .read_event;

    const example_name = b.fmt("examples/{s}.zig", .{@tagName(example_opt)});
    const example_mod = b.addModule("example", .{
        .root_source_file = b.path(example_name),
        .target = target,
        .optimize = optimize,
    });

    const example = b.addExecutable(.{
        .name = "example",
        .root_module = example_mod,
    });

    example_mod.addImport("quix", quix_mod);

    const example_run = b.addRunArtifact(example);
    example_step.dependOn(&example_run.step);
}
