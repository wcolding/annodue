const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

// https://gist.github.com/gingerBill/7282ff54744838c52cc80c559f697051

pub fn Handle(comptime T: type) type {
    std.debug.assert(@typeInfo(T) == .Int);
    std.debug.assert(@typeInfo(T).Int.signedness == .unsigned);
    std.debug.assert(@typeInfo(T).Int.bits % 8 == 0);

    return extern struct {
        owner: T = 0,
        generation: T = 0,
        index: T = 0,
    };
}

pub fn SparseIndex(comptime T: type) type {
    std.debug.assert(@typeInfo(T) == .Int);
    std.debug.assert(@typeInfo(T).Int.signedness == .unsigned);
    std.debug.assert(@typeInfo(T).Int.bits % 8 == 0);

    return extern struct {
        owner: T = 0,
        generation: T = 0,
        index_or_next: T = 0,
    };
}

pub fn HandleMap(comptime T: type, comptime I: type) type {
    return struct {
        const Self = @This();
        handles: ArrayList(Handle(I)),
        values: ArrayList(T),
        sparse_indices: ArrayList(SparseIndex(I)),
        next: I,

        pub fn init(allocator: Allocator) Self {
            return .{
                .handles = ArrayList(Handle(I)).init(allocator),
                .values = ArrayList(T).init(allocator),
                .sparse_indices = ArrayList(SparseIndex(I)).init(allocator),
                .next = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            self.clear();
            self.handles.deinit();
            self.values.deinit();
            self.sparse_indices.deinit();
        }

        pub fn clear(self: *Self) void {
            self.handles.clearRetainingCapacity();
            self.values.clearRetainingCapacity();
            self.sparse_indices.clearRetainingCapacity();
            self.next = 0;
        }

        pub fn hasHandle(self: *Self, h: Handle(I)) bool {
            if (h.index < @as(I, @intCast(self.sparse_indices.items.len))) {
                return self.sparse_indices.items[h.index].generation == h.generation and
                    self.sparse_indices.items[h.index].owner == h.owner;
            }
            return false;
        }

        pub fn get(self: *Self, h: Handle(I)) ?*T {
            if (h.index < @as(I, @intCast(self.sparse_indices.items.len))) {
                const entry = self.sparse_indices.items[h.index];
                if (entry.generation == h.generation and entry.owner == h.owner) {
                    return &self.values.items[entry.index_or_next];
                }
            }
            return null;
        }

        pub fn insert(self: *Self, owner: I, value: T) !Handle(I) {
            var handle: Handle(I) = undefined;
            if (self.next < @as(I, @intCast(self.sparse_indices.items.len))) {
                var entry = &self.sparse_indices.items[self.next];
                std.debug.assert(entry.generation < std.math.maxInt(I)); // "Generation sparse indices overflow"

                entry.owner = owner;
                entry.generation += 1;
                handle = .{
                    .owner = entry.owner,
                    .generation = entry.generation,
                    .index = self.next,
                };
                self.next = entry.index_or_next;
                entry.index_or_next = @as(I, @intCast(self.handles.items.len));
                try self.handles.append(handle);
                try self.values.append(value);
            } else {
                std.debug.assert(self.next < std.math.maxInt(I)); // "Index sparse indices overflow"

                handle = Handle(I){
                    .owner = owner,
                    .index = @as(I, @intCast(self.sparse_indices.items.len)),
                };
                try self.sparse_indices.append(.{
                    .owner = owner,
                    .index_or_next = @as(I, @intCast(self.handles.items.len)),
                });
                try self.handles.append(handle);
                try self.values.append(value);
                self.next += 1;
            }
            return handle;
        }

        pub fn remove(self: *Self, h: Handle(I)) ?T {
            if (h.index < @as(I, @intCast(self.sparse_indices.items.len))) {
                var entry = &self.sparse_indices.items[h.index];
                if (entry.generation != h.generation)
                    return null;

                const index = entry.index_or_next;
                entry.generation += 1;
                entry.index_or_next = self.next;
                self.next = h.index;

                _ = self.handles.swapRemove(index);
                const value = self.values.swapRemove(index);
                if (index < @as(I, @intCast(self.handles.items.len)))
                    self.sparse_indices.items[self.handles.items[index].index].index_or_next = index;

                return value;
            }
            return null;
        }

        pub fn removeOwner(self: *Self, o: I) void {
            const n = self.handles.items.len;
            for (0..n) |i| {
                const h = self.handles.items[n - i - 1];
                if (h.owner == o)
                    _ = self.remove(h);
            }
        }
    };
}

test {
    const HM = HandleMap(f32, u16);
    const H = Handle(u16);

    var m = HM.init(std.testing.allocator);
    defer m.deinit();

    var value: f32 = 123.456;

    var h1: H = try m.insert(123, value);
    var h2: H = try m.insert(456, value);
    var h_: H = h1;
    h_.owner = 789;

    try std.testing.expect(m.hasHandle(h1));
    try std.testing.expect(m.hasHandle(h2));
    try std.testing.expect(!m.hasHandle(h_));

    m.removeOwner(456);
    try std.testing.expect(!m.hasHandle(h2));

    var ptr = m.get(h1);
    try std.testing.expect(ptr != null);
    try std.testing.expect(ptr.?.* == value);

    _ = m.remove(h1);
    try std.testing.expect(!m.hasHandle(h1));
}
