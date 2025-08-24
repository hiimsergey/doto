const builtin = @import("builtin");
const std = @import("std");

pub const Entry = struct { []const u8, u16, u16 };
const Slot = struct { name: []const u8, next: u16 };

const CONFIG = @import("config.zig").CONFIG;
const ENTRY_TIMES: [CONFIG.len]u16 = blk: {
	var result: [CONFIG.len]u16 = undefined;
	for (CONFIG, 0..) |entry, i|
		result[i] = entry.@"1" * @divFloor(MAX_PERDAYS, entry.@"2");
	break :blk result;
};
const MAX_PERDAYS: @FieldType(Entry, "2") = blk: {
	var result = 0;
	for (CONFIG) |entry| result = @max(result, entry.@"2");
	break :blk result;
};
const MAX_TASKS: u8 = blk: {
	var total = 0;
	for (ENTRY_TIMES) |time| total += time;
	break :blk @intFromFloat(@ceil(
		@as(f32, @floatFromInt(total)) /
		@as(f32, @floatFromInt(MAX_PERDAYS))
	));
};
const Buffer = [MAX_PERDAYS * MAX_TASKS]?[]const u8;

pub fn main() void {
	const out = comptime std.io.getStdOut().writer();
	const err = comptime std.io.getStdErr().writer();

	const buf: Buffer = comptime construct(err);
	_ = buf;

	_ = out;
}

fn construct(err: anytype) Buffer {
	const result = .{ null } ** @typeInfo(Buffer).array.len;

	var cur_slot: u16 = 0;
	for (CONFIG, 0..) |entry, i| {
		const total_times = ENTRY_TIMES[i];
		const step = @divFloor(MAX_PERDAYS, total_times);

		for (0..total_times) |time| {
			_ = time;
		}
		_ = step;
		_ = entry;
	}

	cur_slot += 1;
	_ = err;

	return result;
}
