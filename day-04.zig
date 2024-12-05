const std = @import("std");

const Grid = struct {
  values: std.ArrayList(u8),
  columnCount: usize,

  fn deinit(self: * const Grid) void {
    self.values.deinit();
  }

  pub fn at(self: Grid, x: i64, y: i64) u8 {
    if (x < 0) { return 0; }
    if (y < 0) { return 0; }
    if (x >= self.columnCount) { return 0; }
    if (y >= self.values.items.len / self.columnCount) { return 0; }
    return (
      self.values.items.ptr[
          @as(usize, @intCast(y)) * self.columnCount
        + @as(usize, @intCast(x))
      ]
    );
  }
};

fn parseInput(allocator: std.mem.Allocator) !Grid {
  const contents = @embedFile("input-04");
  var values = std.ArrayList(u8).init(allocator);
  var contentIterator = std.mem.split(u8, contents, "\n");
  var columnCount: usize = 0;
  while (contentIterator.next()) |line| {
    if (line.len == 0) {
      continue;
    }
    try values.appendSlice(line);
    if (columnCount == 0) {
      columnCount = line.len;
    }
  }
  return Grid { .values = values, .columnCount = columnCount, };
}

const Direction = struct {
  x: i64,
  y: i64,
};

pub fn walkGridDirection(
  grid: Grid, x: i64, y: i64, direction: Direction, idx: i64
) u8 {
  const value = (
    grid.at(@as(i64, x) + direction.x*idx, @as(i64, y) + direction.y*idx)
  );
  return value;
}

pub fn walkGridPoint(grid: Grid, x: i64, y: i64, cmp: [] const u8) !u64 {
  var count : u64 = 0;
  for (0..3) |itx| {
  for (0..3) |ity| {
    const direction = Direction {
      .x = @as(i64, @intCast(itx)) - 1,
      .y = @as(i64, @intCast(ity)) - 1,
    };
    if (direction.x == 0 and direction.y == 0) { continue; }
    var hasMatch = true;
    for (0..,cmp) |idx, char| {
      const idxRel = @as(i64, @intCast(idx));
      if (walkGridDirection(grid, x, y, direction, idxRel) != char) {
        hasMatch = false;
        break;
      }
    }
    count += @intFromBool(hasMatch);
  }}

  return count;
}

pub fn walkGrid(grid: Grid, cmp: [] const u8) !u64 {
  var count : u64 = 0;
  for (0..grid.values.items.len) |it| {
    const x = @as(i64, @intCast(it % grid.columnCount));
    const y = @as(i64, @intCast(it / grid.columnCount));
    count += try walkGridPoint(grid, x, y, cmp);
  }
  return count;
}

const DirectionChar = struct {
  direction: Direction,
  char: u8,
};

pub fn walkCloverMAS(grid: Grid) !u64 {
  var count : u64 = 0;
  const MS : [2] [2] u8 = .{
    .{ 'M', 'S', },
    .{ 'S', 'M', },
  };
  for (0..2) |masFB1| {
  for (0..2) |masFB2| {
    const directions: [5] DirectionChar = [_] DirectionChar {
      .{ .direction = .{ .x = -1, .y = -1, }, .char = MS[masFB1][0], },
      .{ .direction = .{ .x =  1, .y =  1, }, .char = MS[masFB1][1], },

      .{ .direction = .{ .x = -1, .y =  1, }, .char = MS[masFB2][1], },
      .{ .direction = .{ .x =  1, .y = -1, }, .char = MS[masFB2][0], },

      .{ .direction = .{ .x =  0, .y =  0, }, .char = 'A', },
    };
    for (0..grid.values.items.len) |it| {
      const x = @as(i64, @intCast(it % grid.columnCount));
      const y = @as(i64, @intCast(it / grid.columnCount));

      var hasMatch = true;
      for (directions) |direction| {
        if (
          walkGridDirection(grid, x, y, direction.direction, 1) != direction.char
        ) {
          hasMatch = false;
          break;
        }
      }
      count += @intFromBool(hasMatch);
    }
  }}
  return count;
}

pub fn main() !void {
  var allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer _ = allocator.deinit();

  const input = try parseInput(allocator.allocator());
  defer input.deinit();

  // part 1
  const cmp = "XMAS";
  const count = try walkGrid(input, cmp);
  std.debug.print("Count: {}\n", .{ count });

  // part 2
  const countCloverMAS = try walkCloverMAS(input);
  std.debug.print("Count CloverMAS: {}\n", .{ countCloverMAS });
}
