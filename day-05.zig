const std = @import("std");

const Input = struct {
  list: std.ArrayList(std.ArrayList(i64)),
  pairs: std.ArrayList(i64),

  pub fn deinit(self: * const Input) void {
    self.pairs.deinit();
    for (self.list.items) |l| {
      l.deinit();
    }
    self.list.deinit();
  }
};

fn parseInput(allocator: std.mem.Allocator) !Input {
  const contents = @embedFile("input-05");
  var contentIterator = std.mem.split(u8, contents, "\n");

  var input = Input {
    .list = std.ArrayList(std.ArrayList(i64)).init(allocator),
    .pairs = std.ArrayList(i64).init(allocator),
  };

  // first grab lists, until find empty newline
  while (contentIterator.next()) |line| {
    if (line.len == 0) {
      break;
    }
    // format is %d|%d , so split on |
    var split = std.mem.split(u8, line, "|");
    try input.pairs.append(try std.fmt.parseInt(i64, split.next().?, 10));
    try input.pairs.append(try std.fmt.parseInt(i64, split.next().?, 10));
  }
  // then grab pairs
  while (contentIterator.next()) |line| {
    if (line.len == 0) {
      break;
    }
    // format is %d,%d,%d repeated , so split on ,
    try input.list.append(std.ArrayList(i64).init(allocator));
    var split = std.mem.split(u8, line, ",");
    while (split.next()) |s| {
      try (
        input
          .list.items.ptr[input.list.items.len - 1]
          .append(try std.fmt.parseInt(i64, s, 10))
      );
    }
  }

  return input;
}

fn isValid(
  list : std.ArrayList(i64),
  pairs : std.ArrayList(i64),
  fixList : bool
) i64 {
  // iterate thru pairs, pair[0] needs to precede pair[1]
  // if there's an element out-of-order then the entire
  // list is not sorted
  var somethingWasFixed : bool = false;
  for (0..(pairs.items.len/2)) |idx| {
    const left = pairs.items[idx*2];
    const right = pairs.items[idx*2 + 1];

    // four cases:
    // 1. both left and right are in the list, in order
    //    - the left gets hit and break out
    // 2. only left is in the list
    //    - break out
    // 3. both left and right are in the list, out of order
    //    - the right gets hit, need to find the left
    // 4. only right is in the list
    //    - the right gets hit, need to find the left

    var hitRightIdx : i64 = -1;
    for (0..,list.items) |listIdx, l| {
      if (l == right) {
        hitRightIdx = @as(i64, @intCast(listIdx));
      } else if (l == left) {
        if (hitRightIdx != -1) {
          if (!fixList) {
            return 0; // out of order
          } else {
            // can fix by swapping
            somethingWasFixed = true;
            const tmp = list.items.ptr[@as(usize, @intCast(hitRightIdx))];
            list.items.ptr[@as(usize, @intCast(hitRightIdx))] = (
              list.items.ptr[listIdx]
            );
            list.items.ptr[listIdx] = tmp;
          }
        }
        break; // anything after this is valid, but only break if not fixing
      }
    }
  }
  // list is correctly sorted, return middle entry
  if (fixList and !somethingWasFixed) {
    return 0;
  }
  return list.items.ptr[(list.items.len-1)/2];
}

pub fn main() !void {
  var allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer _ = allocator.deinit();

  const input = try parseInput(allocator.allocator());
  defer input.deinit();

  var sum : i64 = 0;
  for (input.list.items) |l| {
    sum += isValid(l, input.pairs, false);
  }
  std.debug.print("Sum: {}\n", .{sum});

  sum = 0;
  for (input.list.items) |l| {
    var atleastOnce : bool = false;
    var previousSum : i64 = 0;
    // repeatedly fix the list until it's valid
    // really just have to hope that the input doesn't give
    // us something that can cycle forever
    while (true) {
      const validSum = isValid(l, input.pairs, true);
      if (validSum == 0 and !atleastOnce) {
        break; // nothing was fixed
      }
      if (validSum == 0) {
        // was fixed at least once and now generated a valid list
        sum += previousSum;
        break;
      }
      previousSum = validSum;
      atleastOnce = true;
    }
  }
  std.debug.print("Sum: {}\n", .{sum});
}
