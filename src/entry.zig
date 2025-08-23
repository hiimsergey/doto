const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const File = std.fs.File;

pub const Entry = struct {
	name: []const u8,
	times: u16,
	perdays: u16
};

/// Reads the config file and represents every line in a dynamic list structure.
/// Expects user to free result.
pub fn read(allocator: Allocator, file: File, err: anytype) !ArrayList(Entry) {
	var result = ArrayList(Entry).init(allocator);
	errdefer result.deinit();

	const stream = std.io.bufferedReader(file.reader()).reader();
	var buf: [1024]u8 = undefined;

	var linenr: usize = 1;
	while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| : (linenr += 1) {
		var it = std.mem.tokenizeScalar(u8, line, ' ');
		var i: usize = 0;
		var words: [3][]const u8 = undefined;

		while (it.next()) |word| {
			if (i >= 3) {
				err.print(
					\\ERROR config line {d}: too many words
					\\ > {s}
					, .{linenr, line}
				) catch {};
				return error.BadConfig;
			}
			words[i] = word;
			i += 1;
		}
		if (i < 3) {
			err.print(
				\\ERROR: config line {d}: too little words
				\\ > {s}
				, .{linenr, line}
			) catch {};
			return error.BadConfig;
		}

		result.append(.{
			.name = words[0],
			.times = try std.fmt.parseInt(u16, words[1], 10),
			.perdays = try std.fmt.parseInt(u16, words[2], 10)
		});
	}

	return result;
}
