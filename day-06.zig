const std = @import("std");

const guardPrintChars = "^>v<";

const Grid = struct {
  tiles: std.ArrayList(u1),
  width: usize,
  guard : Guard,

  fn init(allocator: std.mem.Allocator) Grid {
    return Grid {
      .tiles = std.ArrayList(u1).init(allocator),
      .width = 0,
      .guard = Guard.init(allocator),
    };
  }

  fn deinit(self: * Grid) void {
    self.tiles.deinit();
    self.guard.deinit();
  }

  fn printGrid(self: * const Grid) void {
    for (0..,self.tiles.items) |tileIdx, tile| {
      if (tileIdx % self.width == 0) {
        std.debug.print("\n", .{});
      }
      if (
            self.guard.ori.x == tileIdx % self.width
        and self.guard.ori.y == tileIdx / self.width
      ) {
        std.debug.print("{c}", .{guardPrintChars[self.guard.direction]});
        continue;
      }
      if (tile == 1) {
        std.debug.print("#", .{});
        continue;
      }

      // see if its in guard path
      const mask = self.guard.visitedOrigins.items[tileIdx];
      if (mask.count() > 2) {
        std.debug.print("+", .{});
        continue;
      }
      if (mask.count() == 2) {
        if (mask.isSet(0) and mask.isSet(2)) {
          std.debug.print("|", .{});
          continue;
        }
        if (mask.isSet(1) and mask.isSet(3)) {
          std.debug.print("-", .{});
          continue;
        }
        std.debug.print("+", .{});
        continue;
      }
      if (mask.isSet(0) or mask.isSet(2)) {
        std.debug.print("|", .{});
        continue;
      }
      if (mask.isSet(1) or mask.isSet(3)) {
        std.debug.print("-", .{});
        continue;
      }
      std.debug.print(".", .{});
    }
    std.debug.print("\n", .{});
  }
};

const i64v2 = struct {
  x: i64,
  y: i64,
};

const Guard = struct {
  direction : u2,
  ori : i64v2,

  // stores directions to find circular behavior
  visitedOrigins : std.ArrayList(std.bit_set.StaticBitSet(4)),

  pub fn init(allocator: std.mem.Allocator) Guard {
    return Guard {
      .direction = 0,
      .ori = .{.x=0,.y=0,},
      .visitedOrigins = (
        std.ArrayList(std.bit_set.StaticBitSet(4)).init(allocator)
      ),
    };
  }

  pub fn deinit(self: * Guard) void {
    self.visitedOrigins.deinit();
  }

  fn rotate(self: * Guard) void {
    const nextDirection = @addWithOverflow(self.direction, 1);
    if (nextDirection.@"1" == 1) { // overflow
      self.direction = 0;
      return;
    }
    self.direction = @as(u2, nextDirection.@"0");
  }

  fn move(self: Guard) i64v2 {
    var ori = self.ori;

    switch (guardPrintChars[self.direction]) {
      '^' => ori.y -= 1,
      '>' => ori.x += 1,
      'v' => ori.y += 1,
      '<' => ori.x -= 1,
      else => unreachable,
    }
    return ori;
  }

  const ForwardResult = enum { Invalid, Valid, Out, };

  fn forward(self: * Guard, grid : * Grid) ForwardResult {
    const ori = self.move();
    if (
         ori.x < 0
      or ori.y < 0
      or ori.x >= grid.width
      or ori.y >= grid.tiles.items.len / grid.width
    ) {
      return .Out;
    }
    const index = (
        @as(usize, @intCast(ori.x))
      + @as(usize, @intCast(ori.y)) * grid.width
    );

    // check we haven't visited this origin in this direction before
    if (self.visitedOrigins.items[index].isSet(self.direction)) {
      return .Invalid;
    }

    if (grid.tiles.items[index] == 1) {
      self.rotate();
      const oriIndex = (
          @as(usize, @intCast(self.ori.x))
        + @as(usize, @intCast(self.ori.y)) * grid.width
      );
      self.visitedOrigins.items[oriIndex].setValue(self.direction, true);
    } else {
      self.ori = ori;
      self.visitedOrigins.items[index].setValue(self.direction, true);
    }
    return .Valid;
  }

  fn marchUntilExit(self: * Guard, grid : * Grid) usize {
    self.visitedOrigins.resize(grid.tiles.items.len) catch {};
    for (0..self.visitedOrigins.items.len) |idx| {
      self.visitedOrigins.items[idx] = std.bit_set.StaticBitSet(4).initEmpty();
    }
    while (true) {
      const result = self.forward(grid);
      if (result == .Out) { break; }
      if (result == .Invalid) {
        // grid.printGrid();
        // _ = std.io.getStdOut().reader().readByte() catch {};
        return 0;
      }
    }

    // calculate steps from visited origins
    var steps : usize = 0;
    for (self.visitedOrigins.items) |visited| {
      if (visited.count() > 0) steps += 1;
    }
    return steps;
  }
};

fn parseInput(allocator : std.mem.Allocator) !Grid {
  const contents = @embedFile("input-06");
  var contentIterator = std.mem.split(u8, contents, "\n");

  var grid = Grid.init(allocator);

  while (contentIterator.next()) |line| {
    if (line.len == 0) { break; }
    grid.width = line.len;
    for (line) |c| {
      if      (c == '#') { try grid.tiles.append(1); }
      else if (c == '.') { try grid.tiles.append(0); }
      else if (c == '^') {
        grid.guard.ori = .{
          .x = @as(i64, @intCast(grid.tiles.items.len % grid.width)),
          .y = @as(i64, @intCast(grid.tiles.items.len / grid.width)),
        };
        try grid.tiles.append(0);
      }
    }
  }

  return grid;
}

pub fn main() !void {
  var allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer _ = allocator.deinit();
  var grid = try parseInput(allocator.allocator());
  defer grid.deinit();

  const originalGuard = grid.guard;

  std.debug.print(
    "march until exit: {}\n",
    .{grid.guard.marchUntilExit(&grid)}
  );

  var count : usize = 0;
  for (0..grid.tiles.items.len) |idx| {
    grid.guard.ori = originalGuard.ori;
    grid.guard.direction = originalGuard.direction;

    const guardIndex = (
        @as(usize, @intCast(grid.guard.ori.x))
      + @as(usize, @intCast(grid.guard.ori.y)) * grid.width
    );

    if (guardIndex == idx) { continue; }

    if (grid.tiles.items[grid.tiles.items.len-idx-1] == 1) { continue; }
    grid.tiles.items[grid.tiles.items.len-idx-1] = 1;

    const steps = grid.guard.marchUntilExit(&grid);
    if (steps == 0) {
      count += 1;
    }

    grid.tiles.items[grid.tiles.items.len-idx-1] = 0;
  }

  std.debug.print("count: {}\n", .{count});
}
