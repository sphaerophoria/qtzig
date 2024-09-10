# Qt built with zig

Note that this is not a replacement for the Qt build system, that would be too
much work. Instead we package the Qt build as an installed item by zig's build
system with zig's compiler

This is meant to be used with some c/c++ glue in your own zig projects, see
example for a simple QML window with state modified from zig

## Usage

* Add as a dependency to build.zig.zon
* Depend on the _install_ step of the dependency. This is a little odd, but the
  following snippet seems to work well enough for me for now (unsure if this is
  abusing implementation details)
  ```zig
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
  ```
* Do whatever you want with the qt build
