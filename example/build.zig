const std = @import("std");

fn makeQtLazyPath(b: *std.Build) !std.Build.LazyPath {
    const dep = b.dependency("qt", .{});
    const generated = try b.allocator.create(std.Build.GeneratedFile);
    generated.* = std.Build.GeneratedFile{
        .step = &dep.builder.install_tls.step,
        .path = dep.builder.install_path,
    };
    return .{
        .generated = .{
            .file = generated,
        },
    };
}

pub fn build(b: *std.Build) !void {
    const qt_install_dir = makeQtLazyPath(b);

    const target = b.standardTargetOptions(.{});
    const opt = b.standardOptimizeOption(.{});

    const rcc_bin = qt_install_dir.path(b, "libexec/rcc");
    const rcc = std.Build.Step.Run.create(b, b.fmt("run rcc", .{}));
    rcc.addFileArg(rcc_bin);
    rcc.addArg("-o");
    const resources_cpp = rcc.addOutputFileArg("resources.cpp");
    rcc.addFileArg(b.path("cpp/resources.qrc"));

    const moc_bin = qt_install_dir.path(b, "libexec/moc");
    const moc = std.Build.Step.Run.create(b, b.fmt("run moc", .{}));
    moc.addFileArg(moc_bin);
    moc.addArg("-o");
    const app_moc_cpp = moc.addOutputFileArg("app.moc.cpp");
    moc.addFileArg(b.path("cpp/app.h"));

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
        .file = b.path("cpp/gui.cpp"),
    });

    exe.addLibraryPath(qt_install_dir.path(b, "lib"));
    exe.linkSystemLibrary("Qt6Core");
    exe.linkSystemLibrary("Qt6Gui");
    exe.linkSystemLibrary("Qt6Qml");
    exe.linkLibCpp();
    exe.addIncludePath(qt_install_dir.path(b, "include"));
    exe.addIncludePath(b.path("cpp"));

    b.installArtifact(exe);
}
