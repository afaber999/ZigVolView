const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });
    const optimize = b.standardOptimizeOption(.{});
    const zalgebra_dep = b.dependency("zalgebra", .{ .target = target, .optimize = optimize });
    const wasm = b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    wasm.root_module.addImport("zalgebra", zalgebra_dep.module("zalgebra"));
    wasm.addIncludePath(b.path("src"));
    wasm.addCSourceFile(.{
        .file = b.path("src/stb_image.c"),
        //.flags = &.{"-freference-trace"},
        //.c_source_flags = &[_][]const u8{ "-freference-trace" },
    });
    wasm.linkLibC();
    wasm.rdynamic = true;
    wasm.entry = .disabled;
    b.installArtifact(wasm);
}
