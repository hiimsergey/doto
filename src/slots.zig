const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Entry = @import("entry.zig").Entry;

const Slot = struct {
	name: []const u8,
	index: u32
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
}

fn get_max_perdays(entries: *const ArrayList(Entry)) @FieldType(Entry, "perdays") {
	var result = 0;
	for (entries) |entry| result = @max(result, entry.perdays);
	return result;
}
