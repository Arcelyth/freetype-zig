const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const library = buildFreeType(b, target, optimize);
    b.installArtifact(library);

    const t: Translator = .init(b.dependency("translate_c", .{}), .{
        .c_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
    });
    t.linkLibrary(library);

    const module = b.addModule("freetype_zig", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{
                .name = "c",
                .module = t.mod,
            },
        },
    });

    // Test
    const test_step = b.step("test", "Run all tests");

    const unit_tests = b.addTest(.{ .name = "tests", .root_module = module });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}

fn cLibrary(b: *std.Build, name: []const u8, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    return b.addLibrary(.{
        .name = name,
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .pic = true,
        }),
    });
}

fn buildFreeType(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const source = b.dependency("freetype", .{});
    const lib = cLibrary(b, "freetype", target, optimize);
    const zlib = buildZlib(b, target, optimize);

    lib.root_module.linkLibrary(zlib);
    lib.root_module.linkLibrary(buildPng(b, target, optimize, zlib));
    const options = b.addWriteFiles().add("freetype-options.h",
        \\#include <freetype/config/ftoption.h>
        \\#define FT_CONFIG_OPTION_SYSTEM_ZLIB
        \\#define FT_CONFIG_OPTION_USE_PNG
    );
    lib.root_module.addIncludePath(options.dirname());
    lib.root_module.addCMacro("FT_CONFIG_OPTIONS_H", "\"freetype-options.h\"");
    lib.root_module.addIncludePath(source.path("include"));
    lib.root_module.addCSourceFiles(.{
        .root = source.path(""),
        .flags = &.{ "-std=c11", "-DFT2_BUILD_LIBRARY" },
        .files = &.{
            "src/autofit/autofit.c", "src/base/ftbase.c",       "src/base/ftbbox.c",
            "src/base/ftbdf.c",      "src/base/ftbitmap.c",     "src/base/ftcid.c",
            "src/base/ftfstype.c",   "src/base/ftgasp.c",       "src/base/ftglyph.c",
            "src/base/ftgxval.c",    "src/base/ftinit.c",       "src/base/ftmm.c",
            "src/base/ftotval.c",    "src/base/ftpatent.c",     "src/base/ftpfr.c",
            "src/base/ftstroke.c",   "src/base/ftsynth.c",      "src/base/fttype1.c",
            "src/base/ftwinfnt.c",   "src/base/ftsystem.c",     "src/base/ftdebug.c",
            "src/bdf/bdf.c",         "src/bzip2/ftbzip2.c",     "src/cache/ftcache.c",
            "src/cff/cff.c",         "src/cid/type1cid.c",      "src/gzip/ftgzip.c",
            "src/lzw/ftlzw.c",       "src/pcf/pcf.c",           "src/pfr/pfr.c",
            "src/psaux/psaux.c",     "src/pshinter/pshinter.c", "src/psnames/psnames.c",
            "src/raster/raster.c",   "src/sdf/sdf.c",           "src/sfnt/sfnt.c",
            "src/smooth/smooth.c",   "src/svg/svg.c",           "src/truetype/truetype.c",
            "src/type1/type1.c",     "src/type42/type42.c",     "src/winfonts/winfnt.c",
        },
    });
    lib.installHeadersDirectory(source.path("include"), "", .{});

    return lib;
}

fn buildZlib(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const source = b.dependency("zlib", .{});
    const lib = cLibrary(b, "z", target, optimize);
    lib.root_module.addIncludePath(source.path(""));
    lib.root_module.addCSourceFiles(.{
        .root = source.path(""),
        .flags = &.{ "-std=c11", "-DHAVE_UNISTD_H" },
        .files = &.{
            "adler32.c", "compress.c", "crc32.c",   "deflate.c", "gzclose.c", "gzlib.c",
            "gzread.c",  "gzwrite.c",  "infback.c", "inffast.c", "inflate.c", "inftrees.c",
            "trees.c",   "uncompr.c",  "zutil.c",
        },
    });
    lib.installHeader(source.path("zlib.h"), "zlib.h");
    lib.installHeader(source.path("zconf.h"), "zconf.h");

    return lib;
}

fn buildPng(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, zlib: *std.Build.Step.Compile) *std.Build.Step.Compile {
    const source = b.dependency("png", .{});
    const lib = cLibrary(b, "png", target, optimize);
    lib.root_module.linkLibrary(zlib);
    lib.root_module.linkSystemLibrary("m", .{ .use_pkg_config = .no });
    lib.root_module.addIncludePath(source.path(""));
    const headers = b.addWriteFiles();
    const config = headers.addCopyFile(source.path("scripts/pnglibconf.h.prebuilt"), "pnglibconf.h");
    lib.root_module.addIncludePath(headers.getDirectory());
    lib.root_module.addCSourceFiles(.{
        .root = source.path(""),
        .flags = &.{
            "-std=c11",              "-DPNG_ARM_NEON_OPT=0", "-DPNG_POWERPC_VSX_OPT=0",
            "-DPNG_INTEL_SSE_OPT=0", "-DPNG_MIPS_MSA_OPT=0", "-DPNG_LOONGARCH_LSX_OPT=0",
        },
        .files = &.{
            "png.c",      "pngerror.c", "pngget.c",   "pngmem.c", "pngpread.c", "pngread.c",
            "pngrio.c",   "pngrtran.c", "pngrutil.c", "pngset.c", "pngtrans.c", "pngwio.c",
            "pngwrite.c", "pngwtran.c", "pngwutil.c",
        },
    });
    lib.installHeader(source.path("png.h"), "png.h");
    lib.installHeader(source.path("pngconf.h"), "pngconf.h");
    lib.installHeader(config, "pnglibconf.h");

    return lib;
}
