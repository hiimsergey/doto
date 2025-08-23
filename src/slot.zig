const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Entry = @import("entry.zig").Entry;

const Slot = struct {
	name: []const u8,
	next: u16
};

/// Reads the constructed entries array list and constructs a slots list of all
/// chores that need to be done over the course of N days, where N is the highest
/// perdays entry in the config file, i.e. the third word.
/// Expects user to free result.
pub fn construct(
	allocator: Allocator,
	entries: *const ArrayList(Entry),
	err: anytype
) !ArrayList(Entry) {
	const max_perdays = get_max_perdays(entries);

	var slots_size: u16 = 0;
	for (entries) |entry|
		slots_size += entry.times * @divFloor(max_perdays, entry.perdays);

	const slots: [*]const Entry = allocator.alloc(Entry, slots_size);
	defer allocator.free(slots);

	const backlinks = allocator.alloc(?u16, slots_size);
	defer allocator.free(backlinks);

	var cur_slot: u16 = 0;
	for (entries) |entry| {
		const total_times = entry.times * @divFloor(max_perdays, entry.perdays);
		const step = @divFloor(max_perdays, total_times);

		for (0..total_times) |i| {
			const pos = i * step;

			if (backlinks[pos]) |bl| {
				slots[cur_slot].next = slots[bl].next;
				slots[bl].next = cur_slot;
			} else {
				slots[cur_slot].next = cur_slot + 1;
			}

			backlinks[pos] = cur_slot;
			slots[cur_slot].name = entry.name;
			cur_slot += 1;
		}
	}
}

fn get_max_perdays(entries: *const ArrayList(Entry)) @FieldType(Entry, "perdays") {
	var result = 0;
	for (entries) |entry| result = @max(result, entry.perdays);
	return result;
}
