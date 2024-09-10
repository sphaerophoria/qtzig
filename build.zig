const std = @import("std");

fn buildQtModule(b: *std.Build, dep: []const u8, requires: []const *std.Build.Step) !*std.Build.Step {
    const dep_mod = b.dependency(dep, .{});

    const cmake = b.addSystemCommand(&.{"cmake"});
    const env = cmake.getEnvMap();
    const cc_path = b.path("build/cc.sh").getPath(b);
    const cxx_path = b.path("build/cxx.py").getPath(b);
    try env.put("CC", cc_path);
    try env.put("CXX", cxx_path);

    cmake.addArg("-B");
    const build_dir = cmake.addOutputDirectoryArg("build");
    cmake.addArg("-S");
    cmake.addDirectoryArg(dep_mod.path("."));
    for (requires) |r| {
        cmake.step.dependOn(r);
    }
    cmake.addArgs(&.{ "-G", "Ninja" });

    const install_prefix = b.getInstallPath(.prefix, ".");
    const install_prefix_arg = try std.fmt.allocPrint(b.allocator, "-DCMAKE_INSTALL_PREFIX={s}", .{install_prefix});
    defer b.allocator.free(install_prefix_arg);
    cmake.addArg(install_prefix_arg);

    const make = b.addSystemCommand(&.{ "ninja", "-C" });
    make.addDirectoryArg(build_dir);
    make.step.dependOn(&cmake.step);

    const install = b.addSystemCommand(&.{ "ninja", "-C" });
    install.addDirectoryArg(build_dir);
    install.addArg("install");
    install.step.dependOn(&make.step);

    b.getInstallStep().dependOn(&install.step);
    return &install.step;
}

pub fn build(b: *std.Build) !void {
    const base = try buildQtModule(b, "qtbase", &.{});
    const shader_tools = try buildQtModule(b, "qtshadertools", &.{base});
    const qml = try buildQtModule(b, "qtdeclarative", &.{ base, shader_tools });

    const target = b.standardTargetOptions(.{});
    const opt = b.standardOptimizeOption(.{});

    const rcc_bin = b.getInstallPath(.prefix, "libexec/rcc");
    const rcc = b.addSystemCommand(&.{ rcc_bin, "-o" });
    const resources_cpp = rcc.addOutputFileArg("resources.cpp");
    rcc.addFileArg(b.path("qml_example/resources.qrc"));
    rcc.step.dependOn(base);

    const moc_bin = b.getInstallPath(.prefix, "libexec/moc");
    const moc = b.addSystemCommand(&.{ moc_bin, "-o" });
    const app_moc_cpp = moc.addOutputFileArg("app.moc.cpp");
    moc.addFileArg(b.path("qml_example/app.h"));
    moc.step.dependOn(base);

    const exe = b.addExecutable(.{
        .name = "test",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = opt,
    });

    exe.addCSourceFile(.{
        .file = app_moc_cpp,
    });
    exe.addCSourceFile(.{
        .file = resources_cpp,
    });
    exe.addCSourceFile(.{
        .file = b.path("qml_example/gui.cpp"),
    });
    const lib_dir = b.getInstallPath(.prefix, "lib");
    exe.addLibraryPath(.{ .cwd_relative = lib_dir });
    exe.linkSystemLibrary("Qt6Core");
    exe.linkSystemLibrary("Qt6Gui");
    exe.linkSystemLibrary("Qt6Qml");
    exe.linkLibCpp();
    const include_dir = b.getInstallPath(.prefix, "include");
    exe.addIncludePath(std.Build.LazyPath{ .cwd_relative = include_dir });
    exe.addIncludePath(b.path("qml_example"));
    exe.step.dependOn(qml);

    b.installArtifact(exe);
}
