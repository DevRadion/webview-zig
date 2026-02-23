const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const webview = b.dependency("webview", .{});

    const webviewRaw = b.addTranslateC(.{
        .root_source_file = webview.path("core/include/webview/webview.h"),
        .optimize = optimize,
        .target = target,
    }).createModule();

    _ = b.addModule("webview", .{
        .root_source_file = b.path("src/webview.zig"),
        //.dependencies = &[_]std.Build.ModuleDependency{},
    }).addImport("webviewRaw", webviewRaw);

    // const objectFile = b.addObject(.{
    //     .name = "webviewObject",
    //     .optimize = optimize,
    //     .target = target,
    // });
    // objectFile.defineCMacro("WEBVIEW_STATIC", null);
    // objectFile.linkLibCpp();
    // switch(target.os_tag orelse @import("builtin").os.tag) {
    //     .windows => {
    //         objectFile.addCSourceFile(.{ .file = b.path("external/webview/webview.cc") .flags = &.{"-std=c++14"}});
    //         objectFile.addIncludePath(std.build.LazyPath.relative("external/WebView2/"));
    //         objectFile.linkSystemLibrary("ole32");
    //         objectFile.linkSystemLibrary("shlwapi");
    //         objectFile.linkSystemLibrary("version");
    //         objectFile.linkSystemLibrary("advapi32");
    //         objectFile.linkSystemLibrary("shell32");
    //         objectFile.linkSystemLibrary("user32");
    //     },
    //     .macos => {
    //         objectFile.addCSourceFile(.{ .file = b.path("external/webview/webview.cc") .flags = &.{"-std=c++11"}});
    //         objectFile.linkFramework("WebKit");
    //     },
    //     else => {
    //         objectFile.addCSourceFile(.{ .file = b.path("external/webview/webview.cc") .flags = &.{"-std=c++11"}});
    //         objectFile.linkSystemLibrary("gtk+-3.0");
    //         objectFile.linkSystemLibrary("webkit2gtk-4.0");
    //     }
    // }
    const staticLib = b.addLibrary(.{
        .name = "webviewStatic",
        .root_module = b.addModule("webviewStatic", .{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
        .linkage = .static,
    });
    staticLib.root_module.addIncludePath(webview.path("core/include/webview/"));
    staticLib.root_module.addCMacro("WEBVIEW_STATIC", "");
    switch (target.query.os_tag orelse @import("builtin").os.tag) {
        .windows => {
            staticLib.root_module.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++14"} });
            staticLib.root_module.addIncludePath(b.path("external/WebView2/"));
            staticLib.root_module.linkSystemLibrary("ole32", .{});
            staticLib.root_module.linkSystemLibrary("shlwapi", .{});
            staticLib.root_module.linkSystemLibrary("version", .{});
            staticLib.root_module.linkSystemLibrary("advapi32", .{});
            staticLib.root_module.linkSystemLibrary("shell32", .{});
            staticLib.root_module.linkSystemLibrary("user32", .{});
        },
        .macos => {
            staticLib.root_module.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            staticLib.root_module.linkFramework("WebKit", .{});
        },
        .freebsd => {
            staticLib.root_module.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            staticLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/cairo/" });
            staticLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/gtk-3.0/" });
            staticLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/glib-2.0/" });
            staticLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/lib/glib-2.0/include/" });
            staticLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/webkitgtk-4.0/" });
            staticLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/pango-1.0/" });
            staticLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/harfbuzz/" });
            staticLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/gdk-pixbuf-2.0/" });
            staticLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/atk-1.0/" });
            staticLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/libsoup-3.0/" });
            staticLib.root_module.linkSystemLibrary("gtk-3", .{});
            staticLib.root_module.linkSystemLibrary("webkit2gtk-4.1", .{});
        },
        else => {
            staticLib.root_module.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            staticLib.root_module.linkSystemLibrary("gtk+-3.0", .{});
            staticLib.root_module.linkSystemLibrary("webkit2gtk-4.1", .{});
        },
    }
    b.installArtifact(staticLib);

    const sharedLib = b.addLibrary(.{
        .name = "webviewShared",
        .root_module = b.addModule("webviewShared", .{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
        .linkage = .dynamic,
    });
    sharedLib.root_module.addIncludePath(webview.path("core/include/webview/"));
    sharedLib.root_module.addCMacro("WEBVIEW_BUILD_SHARED", "");
    switch (target.query.os_tag orelse @import("builtin").os.tag) {
        .windows => {
            sharedLib.root_module.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++14"} });
            sharedLib.root_module.addIncludePath(b.path("external/WebView2/"));
            sharedLib.root_module.linkSystemLibrary("ole32", .{});
            sharedLib.root_module.linkSystemLibrary("shlwapi", .{});
            sharedLib.root_module.linkSystemLibrary("version", .{});
            sharedLib.root_module.linkSystemLibrary("advapi32", .{});
            sharedLib.root_module.linkSystemLibrary("shell32", .{});
            sharedLib.root_module.linkSystemLibrary("user32", .{});
        },
        .macos => {
            sharedLib.root_module.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            sharedLib.root_module.linkFramework("WebKit", .{});
        },
        .freebsd => {
            sharedLib.root_module.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            sharedLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/cairo/" });
            sharedLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/gtk-3.0/" });
            sharedLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/glib-2.0/" });
            sharedLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/lib/glib-2.0/include/" });
            sharedLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/webkitgtk-4.0/" });
            sharedLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/pango-1.0/" });
            sharedLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/harfbuzz/" });
            sharedLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/gdk-pixbuf-2.0/" });
            sharedLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/atk-1.0/" });
            sharedLib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/libsoup-3.0/" });
            sharedLib.root_module.linkSystemLibrary("gtk-3", .{});
            sharedLib.root_module.linkSystemLibrary("webkit2gtk-4.1", .{});
        },
        else => {
            sharedLib.root_module.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            sharedLib.root_module.linkSystemLibrary("gtk+-3.0", .{});
            sharedLib.root_module.linkSystemLibrary("webkit2gtk-4.1", .{});
        },
    }
    b.installArtifact(sharedLib);

    const unit_tests = b.addTest(.{
        .root_module = b.addModule(
            "webviewTest",
            .{
                .root_source_file = b.path("src/test.zig"),
                .target = target,
                .optimize = optimize,
            },
        ),
    });
    unit_tests.root_module.addImport("webviewRaw", webviewRaw);
    unit_tests.root_module.linkLibrary(staticLib);

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
