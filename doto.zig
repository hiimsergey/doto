const builtin = @import("builtin");
const std = @import("std");

pub const Entry = struct { []const u8, u16, u16 };

// The program expects an array of `Entry` tuples, for example:
//
// const CONFIG = [_]Entry{
//     .{ "Read a book",   1, 2 },
//     .{ "Clean",         1, 7 },
//     .{ "Learn Italian", 3, 7 },
//     .{ "Code"           2, 4 }
// };
//
// The first tuple item is the name of activity itself. The latter numbers
// are the frequency described as a fraction. In this example, you would want to
// - read every other day
// - clean weekly
// - learn Italian thrice a week
// - code twice every four days
//
// Here, `config.zig` is a git-ignored file featuring my own config. But you
// can also write the array here.
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

const FMT_BLACK  = "\x1b[30m";
const FMT_YELLOW = "\x1b[33m";
const FMT_BLUE   = "\x1b[34m";
const FMT_NORMAL = "\x1b[39m";

const out = std.io.getStdOut().writer();

inline fn println(comptime fmt: []const u8, args: anytype) void {
	out.print(fmt ++ "\n", args) catch {};
}

fn help() void {
	println(
		\\Usage:
		\\    doto       – show today's tasks
		\\    doto list  – show the entire schedule
		, .{}
	);
}

pub fn main() u8 {
	const buf: Buffer = comptime get_buffer();

	var args = std.process.args();
	defer args.deinit();

	_ = args.next(); // Skip executable name
	const arg1 = args.next();
	const arg2 = args.next();

	if (arg2 != null) {
		help();
		return 1;
	}

	if (builtin.mode == .Debug) {
		println(FMT_YELLOW ++ "Given tasks:\n.{{", .{});
		for (CONFIG) |day| println("    .{{ {s}, {d}, {d} }},", day);
		println(
			"}}\n" ++ FMT_BLUE ++ "Making buffer for {d} days of {d} tasks",
			.{ PERIOD, MAX_TASKS }
		);

		var total_times: u16 = 0;
		for (ENTRY_TIMES, 0..) |day, i| {
			println("{d:>2} times of {s}", .{day, CONFIG[i].@"0"});
			total_times += day;
		}
		println("=> {d} times in total\n" ++ FMT_NORMAL, .{total_times});
	}

	const range: struct { from: usize, to: usize } = blk: {
		if (arg1 == null) {
			// Since the UNIX epoch, 1970-01-01, was a Thursday, the first
			// Monday since then came four days later.
			const first_monday = 4 * std.time.s_per_day;
			const s_since_first_monday = std.time.timestamp() - first_monday;
			const d_since_epoch = @divFloor(s_since_first_monday, std.time.s_per_day);

			const todays_period_i: usize = @abs(@mod(d_since_epoch, PERIOD));
			break :blk .{ .from = todays_period_i, .to = todays_period_i + 1 };
		}
		if (!std.mem.eql(u8, arg1.?, "list")) {
			help();
			return 1;
		}
		break :blk .{ .from = 0, .to = PERIOD };
	};

	for (range.from..range.to) |period_i| {
		println(FMT_BLACK ++ "Day {d}/{d}" ++ FMT_NORMAL, .{period_i + 1, PERIOD});
		for (buf[period_i]) |name| {
			if (name == null) break;
			println("{s}", .{name.?});
		}
	}

	return 0;
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

// Tries to put the `entry` the day at index `target_day`. If all slots, of which there
// are `MAX_TASKS`, are full, it finds the day with the lowest number of entries and
// the lowest day index and puts it there. There will always be a free slot for the entry.
inline fn put_entry(buf: *Buffer, entry: []const u8, target_day: u16) void {
	for (0..MAX_TASKS) |task| {
		if (buf[target_day][task] != null) continue;
		buf[target_day][task] = entry;
		return;
	}
	
	var best_day: u16 = PERIOD;
	var min_task_nr: u16 = MAX_TASKS;
	inline for (0..PERIOD) |day| {
		if (day == target_day) continue;
		inline for (0..MAX_TASKS) |task| {
			if (buf[day][task] != null) continue;
			if (task < min_task_nr) {
				best_day = day;
				min_task_nr = task;
			}
			break;
		}
	}

	buf[best_day][min_task_nr] = entry;
}
