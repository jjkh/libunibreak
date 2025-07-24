const std = @import("std");

pub fn build(b: *std.Build) !void {
    const upstream = b.dependency("libunibreak", .{});
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const src_dir = upstream.path("src");
    const tools_dir = upstream.path("tools");

    const lib = b.addLibrary(.{
        .name = "libunibreak",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    lib.addCSourceFiles(.{
        .root = src_dir,
        .files = source_files,
        .flags = &.{ "-W", "-Wall" },
    });
    lib.linker_allow_undefined_version = false;
    for (header_files) |header|
        lib.installHeader(src_dir.path(b, header), header);
    b.installArtifact(lib);

    const examples_step = b.step("examples", "Build example executables");
    for (example_sources) |source_file| {
        const example_exe = b.addExecutable(.{
            .name = source_file[0 .. source_file.len - 2], // remove '.c' extension
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
            }),
        });
        example_exe.linkLibrary(lib);
        example_exe.linkSystemLibrary("iconv");
        example_exe.addCSourceFile(.{ .file = tools_dir.path(b, source_file) });

        const install_example = b.addInstallFileWithDir(example_exe.getEmittedBin(), .bin, example_exe.name);
        examples_step.dependOn(&install_example.step);
    }
    const install_example_file = b.addInstallBinFile(tools_dir.path(b, example_test_file), example_test_file);
    examples_step.dependOn(&install_example_file.step);

    const test_step = b.step("test", "Run tests");
    const test_exe = b.addExecutable(.{
        .name = "libunibreak_test",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    test_exe.linkLibrary(lib);
    test_exe.addCSourceFile(.{ .file = src_dir.path(b, test_source) });

    // run each test (line, word, grapheme) in sequence
    const write_files = b.addWriteFiles();
    var last_step = test_step;
    for (test_types.keys()) |test_arg| {
        const run_cmd = b.addRunArtifact(test_exe);

        // copy required test files
        const test_file = test_types.get(test_arg).?;
        _ = write_files.addCopyFile(src_dir.path(b, test_file), test_file);
        run_cmd.setCwd(write_files.getDirectory());
        run_cmd.addArg(test_arg);

        // move to the next test step
        last_step.dependOn(&run_cmd.step);
        last_step = &run_cmd.step;
    }
}

const header_files: []const []const u8 = &.{
    "unibreakbase.h",
    "unibreakdef.h",
    "linebreak.h",
    "linebreakdef.h",
    "eastasianwidthdef.h",
    "graphemebreak.h",
    "wordbreak.h",
};

const source_files: []const []const u8 = &.{
    "unibreakbase.c",
    "unibreakdef.c",
    "linebreak.c",
    "linebreakdata.c",
    "linebreakdef.c",
    "eastasianwidthdef.c",
    "emojidef.c",
    "graphemebreak.c",
    "wordbreak.c",
};

const test_source: []const u8 = "tests.c";
const test_types: std.StaticStringMap([]const u8) = .initComptime(.{
    .{ "line", "LineBreakTest.txt" },
    .{ "word", "WordBreakTest.txt" },
    .{ "grapheme", "GraphemeBreakTest.txt" },
});

const example_sources: []const []const u8 = &.{
    "linebreak_test.c",
    "wordbreak_test.c",
    "graphemebreak_test.c",
};
const example_test_file: []const u8 = "test.txt";
