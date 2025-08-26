const builtin = @import("builtin");
const std = @import("std");

pub const Entry = struct { []const u8, u16, u16 };

const CONFIG = @import("config.zig").CONFIG;
const ENTRY_TIMES: [CONFIG.len]u16 = blk: {
	var result: [CONFIG.len]u16 = undefined;
	for (CONFIG, 0..) |entry, i|
		result[i] = entry.@"1" * @divFloor(PERIOD, entry.@"2");
	break :blk result;
};
const PERIOD: @FieldType(Entry, "2") = blk: {
	var result = 0;
	for (CONFIG) |entry| result = @max(result, entry.@"2");
	break :blk result;
};
const MAX_TASKS: u8 = blk: {
	var total: f32 = 0;
	for (ENTRY_TIMES) |time| total += time;
	break :blk @intFromFloat(@ceil(
		total /
		@as(f32, @floatFromInt(PERIOD))
	));
};
const Buffer = [PERIOD][MAX_TASKS]?[]const u8;

const FMT_BLACK = "\x1b[30m";
const FMT_YELLOW= "\x1b[33m";
const FMT_BLUE = "\x1b[34m";
const FMT_NORMAL = "\x1b[39m";

pub fn main() void {
	const out = std.io.getStdOut().writer();
	const buf: Buffer = comptime get_buffer();

	if (builtin.mode == .Debug) {
		out.print(FMT_YELLOW ++ "Given tasks:\n.{{\n", .{}) catch {};
		for (CONFIG) |day| out.print("    .{{ {s}, {d}, {d} }},\n", day) catch {};
		out.print(
			"}}\n" ++ FMT_BLUE ++ "Making buffer for {d} days of {d} tasks\n",
			.{ PERIOD, MAX_TASKS }
		) catch {};

		var total_times: u16 = 0;
		for (ENTRY_TIMES, 0..) |day, i| {
			out.print("{d:>2} times of {s}\n", .{day, CONFIG[i].@"0"}) catch {};
			total_times += day;
		}
		out.print("=> {d} times in total\n\n" ++ FMT_NORMAL, .{total_times}) catch {};
	}
	
	//const days_since_epoch: u64 = @abs(@divFloor(std.time.timestamp(), std.time.s_per_day));
	//const todays_period_i = days_since_epoch % MAX_PERIOD;

	for (0..14) |todays_period_i| {
	out.print(
		FMT_BLACK ++ "Day {d}/{d}\n" ++ FMT_NORMAL,
		.{todays_period_i + 1, PERIOD}
	) catch {};
	for (buf[todays_period_i]) |name| {
		if (name == null) break;
		out.print("{s}\n", .{name.?}) catch {};
	}
	}
}

fn get_buffer() Buffer {
	var result: Buffer = .{ .{ null } ** MAX_TASKS } ** PERIOD;
	for (CONFIG, 0..) |entry, i| {
		const total_times = ENTRY_TIMES[i];
		const step = @divFloor(PERIOD, total_times);
		inline for (0..total_times) |time| put_entry(&result, entry.@"0", time * step);
	}
	return result;
}

inline fn put_entry(buf: *Buffer, entry: []const u8, target_day: u16) void {
	// First, try target_day directly
	for (0..MAX_TASKS) |task| {
		if (buf[target_day][task] == null) {
			buf[target_day][task] = entry;
			return;
		}
	}

	// Otherwise, search earlier days
	var best_day: u16 = 0;
	var best_task_count: u16 = MAX_TASKS + 1; // sentinel
	for (0..target_day) |day| {
		var count: u16 = 0;
		for (0..MAX_TASKS) |task| {
			if (buf[day][task] != null) count += 1;
		}
		if (count < best_task_count) {
			best_task_count = count;
			best_day = day;
		}
	}

	// Now place into the first free slot of that best day
	for (0..MAX_TASKS) |task| {
		if (buf[best_day][task] == null) {
			buf[best_day][task] = entry;
			return;
		}
	}
}

inline fn put_entry_mine(buf: *Buffer, entry: []const u8, target_day: u16) void {
	for (0..MAX_TASKS) |task| {
		if (buf[target_day][task] != null) continue;
		buf[target_day][task] = entry;
		return;
	}
	
	var best_day: u16 = null;
	var min_task_nr: u16 = MAX_TASKS;
	for (0..PERIOD) |day| {
		if (day == target_day) continue;
		for (0..MAX_TASKS) |task| {
			if (buf[day][task] != null or task > min_task_nr) continue;
			best_day = day;
			min_task_nr = task;
			break;
		}
	}
	buf[best_day][min_task_nr] = entry;
}
