const builtin = @import("builtin");
const std = @import("std");

pub const Entry = struct { []const u8, u16, u16 };
const Slot = struct { name: []const u8, next: u16 };

const CONFIG = @import("config.zig").CONFIG;
const ENTRY_TIMES: [CONFIG.len]u16 = blk: {
	var result: [CONFIG.len]u16 = undefined;
	for (CONFIG, 0..) |entry, i|
		result[i] = entry.@"1" * @divFloor(MAX_PERIOD, entry.@"2");
	break :blk result;
};
const MAX_PERIOD: @FieldType(Entry, "2") = blk: {
	var result = 0;
	for (CONFIG) |entry| result = @max(result, entry.@"2");
	break :blk result;
};
const MAX_TASKS: u8 = blk: {
	var total: f32 = 0;
	for (ENTRY_TIMES) |time| total += time;
	break :blk @intFromFloat(@ceil(
		total /
		@as(f32, @floatFromInt(MAX_PERIOD))
	));
};
const Buffer = [MAX_PERIOD][MAX_TASKS]?[]const u8;

const FMT_BLACK = "\x1b[30m";
const FMT_NORMAL = "\x1b[39m";

pub fn main() void {
	const out = comptime std.io.getStdOut().writer();
	const buf: Buffer = comptime get_buffer();

	const days_since_epoch: u64 = @abs(@divFloor(std.time.timestamp(), std.time.s_per_day));
	const todays_period_i = days_since_epoch % MAX_PERIOD;

	out.print(
		FMT_BLACK ++ "Day {d}/{d}\n" ++ FMT_NORMAL,
		.{todays_period_i, MAX_PERIOD}
	) catch {};
	for (buf[todays_period_i]) |name| {
		if (name == null) break;
		out.print("{s}\n", .{name.?}) catch {};
	}
}

fn get_buffer() Buffer {
	var result: Buffer = .{ .{ null } ** MAX_TASKS } ** MAX_PERIOD;
	for (CONFIG, 0..) |entry, i| {
		const total_times = ENTRY_TIMES[i];
		const step = @divFloor(MAX_PERIOD, total_times);

		inline for (0..total_times) |time| put_entry(&result, entry.@"0", time * step);
	}
	return result;
}

inline fn put_entry(buf: *Buffer, name: []const u8, target_day: u16) void {
	for (0..MAX_TASKS) |task| {
		if (buf[target_day][task] == null) continue;
		buf[target_day][task] = name;
		return;
	}
	
	var min_day: u16 = target_day;
	var free_task: u16 = MAX_TASKS - 1;
	for (0..target_day) |day| {
		for (0..MAX_TASKS) |task| {
			if (buf[day][task] != null or task >= free_task) continue;
			min_day = day;
			free_task = task;
			break;
		}
	}
	buf[min_day][free_task] = name;
}
