const builtin = @import("builtin");
const std = @import("std");

const config = @import("config.zig");
const entry = @import("entry.zig");
const slots = @import("slots.zig");

const AllocatorWrapper = @import("allocator.zig").AllocatorWrapper;
const ArrayList = std.ArrayList;
const Entry = @import("Entry.zig").Entry;

pub fn main() !void {
	const out = std.io.getStdOut().writer();
	const err = std.io.getStdErr().writer();

	var aw = AllocatorWrapper.init();
	defer aw.deinit(err);
	const allocator = aw.allocator();

	var file = try config.load(allocator);
	defer file.close();

	const entries: ArrayList(Entry) = try entry.read(allocator, file, err);
	defer entries.deinit();

	const slots: ArrayList([]const u8) = slots.construct(allocator, &entries, err);
	defer slots.deinit();
}
