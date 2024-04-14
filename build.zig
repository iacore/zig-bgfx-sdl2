const Builder = @import("std").Build;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "game",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const git_sub_cmd = [_][]const u8{ "git", "submodule", "update", "--init", "--recursive" };
    const fetch_subs = b.addSystemCommand(&git_sub_cmd);

    exe.addIncludePath(.{ .path = "src" });

    exe.linkLibC();
    exe.linkSystemLibrary("c++");
    exe.linkSystemLibrary("X11");
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("GL");

    const cxx_options = [_][]const u8{
        "-fno-strict-aliasing",
        "-fno-exceptions",
        "-fno-rtti",
        "-ffast-math",
    };
    // Define to enable some debug prints in BGFX
    //exe.defineCMacro("BGFX_CONFIG_DEBUG=1");

    // bx
    const bx = "submodules/bx/";
    exe.addIncludePath(.{ .path = bx ++ "include/" });
    exe.addIncludePath(.{ .path = bx ++ "3rdparty/" });
    exe.addCSourceFile(.{ .file = .{ .path = bx ++ "src/amalgamated.cpp" }, .flags = &cxx_options });

    // bimg
    const bimg = "submodules/bimg/";
    exe.addIncludePath(.{ .path = bimg ++ "include/" });
    exe.addIncludePath(.{ .path = bimg ++ "3rdparty/" });
    exe.addIncludePath(.{ .path = bimg ++ "3rdparty/astc-codec/" });
    exe.addIncludePath(.{ .path = bimg ++ "3rdparty/astc-codec/include/" });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "src/image.cpp" }, .flags = &cxx_options });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "src/image_gnf.cpp" }, .flags = &cxx_options });
    // FIXME: Glob?
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "3rdparty/astc-codec/src/decoder/astc_file.cc" }, .flags = &cxx_options });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "3rdparty/astc-codec/src/decoder/codec.cc" }, .flags = &cxx_options });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "3rdparty/astc-codec/src/decoder/endpoint_codec.cc" }, .flags = &cxx_options });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "3rdparty/astc-codec/src/decoder/footprint.cc" }, .flags = &cxx_options });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "3rdparty/astc-codec/src/decoder/integer_sequence_codec.cc" }, .flags = &cxx_options });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "3rdparty/astc-codec/src/decoder/intermediate_astc_block.cc" }, .flags = &cxx_options });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "3rdparty/astc-codec/src/decoder/logical_astc_block.cc" }, .flags = &cxx_options });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "3rdparty/astc-codec/src/decoder/partition.cc" }, .flags = &cxx_options });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "3rdparty/astc-codec/src/decoder/physical_astc_block.cc" }, .flags = &cxx_options });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "3rdparty/astc-codec/src/decoder/quantization.cc" }, .flags = &cxx_options });
    exe.addCSourceFile(.{ .file = .{ .path = bimg ++ "3rdparty/astc-codec/src/decoder/weight_infill.cc" }, .flags = &cxx_options });

    // bgfx
    const bgfx = "submodules/bgfx/";
    exe.addIncludePath(.{ .path = bgfx ++ "include/" });
    exe.addIncludePath(.{ .path = bgfx ++ "3rdparty/" });
    exe.addIncludePath(.{ .path = bgfx ++ "3rdparty/dxsdk/include/" });
    exe.addIncludePath(.{ .path = bgfx ++ "3rdparty/khronos/" });
    exe.addIncludePath(.{ .path = bgfx ++ "src/" });
    exe.addCSourceFile(.{ .file = .{ .path = bgfx ++ "src/amalgamated.cpp" }, .flags = &cxx_options });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const fetch_step = b.step("fetch", "Fetch submodules");
    fetch_step.dependOn(&fetch_subs.step);
}
