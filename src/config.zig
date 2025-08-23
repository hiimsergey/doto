const builtin = @import("builtin");
const std = @import("std");

const constants = @import("constants.zig");

const Allocator = std.mem.Allocator;
const File = std.fs.File;

/// Returns a file handle to the config file.
pub inline fn load(allocator: Allocator) !File {
	return switch (builtin.os.tag) {
		.linux, .macos, .freebsd, .openbsd, .netbsd => try load_unix_config(allocator),
		.windows => @panic("TODO"),
		else => @compileError("This program does not support your operating system! :(")
	};
}

fn load_unix_config(allocator: Allocator) !File {
	if (std.process.getEnvVarOwned(allocator, constants.ENVVAR)) |result|
	return try std.fs.createFileAbsolute(result, .{ .truncate = false, .read = true });

	const path = blk: {
		if (std.process.getEnvVarOwned(allocator, "XDG_CONFIG_HOME")) |result|
		break :blk result;

		const home = try std.process.getEnvVarOwned(allocator, "HOME");
		defer allocator.free(home);
		break :blk try std.mem.concat(allocator, u8, .{ home, "/.config" });
	};
	defer allocator.free(path);

	const dir = try std.fs.openDirAbsolute(path, .{});
	defer dir.close();

	return try dir.createFile(constants.CONFIG_BASENAME, .{ .truncate = false, .read = true });
}
