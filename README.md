# libunibreak

[`libunibreak`](https://github.com/adah1972/libunibreak) packaged for the [Zig](https://ziglang.org/) build system.

## Status

Mostly untested:

* Tests are passing on `aarch64-macos`/`x86_64-macos`
* Compatible with Zig `0.14.0` and `0.15.0-dev.1184+c41ac8f19`

## Usage

```zig
const libunibreak_dep = b.dependency("libunibreak", .{
    .target = target,
    .optimize = optimize,
});
exe.linkLibrary(libunibreak_dep.artifact("libunibreak"));
```

## Testing

```sh
zig build test
```

## Examples

> [!IMPORTANT]
> The examples link `iconv` and therefore will **not** run on Windows.

```sh
# builds the examples and copies the test data file
zig build examples
# to run:
cd ./zig-out/bin
./linebreak_test test.txt
./wordbreak_test test.txt
./graphemebreak_test test.txt
```

## Dependencies

`libunibreak` only depends on libc.

The examples require link to the system `iconv` (where available).
