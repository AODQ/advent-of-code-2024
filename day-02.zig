const std = @import("std");

pub fn parseInput(allocator : std.mem.Allocator) !std.ArrayList(i64) {
  const contents = @embedFile("input-02");
  var values = std.ArrayList(i64).init(allocator);
  var contentIterator = std.mem.split(u8, contents, "\n");
  while (contentIterator.next()) |line| {
    var lineIterator = std.mem.split(u8, line, " ");
    while (lineIterator.next()) |word| {
      if (word.len == 0) continue;
      try values.append(try std.fmt.parseInt(i64, word, 10));
    }
    try values.append(-1);
  }
  return values;
}

pub fn helperSolve(slice : [] const i64) !bool {
  var temp : [128] i64 = undefined;
  // clobber this allocation with -1 (invalid), 0 (dsc) or 1 (asc)
  for (1..,slice) |i, v| {
    if (i >= slice.len) break;
    const diff = v - slice.ptr[i];
    const diffAbs = @abs(diff);
    temp[i-1] = (
      if (diffAbs == 0 or diffAbs > 3) -1 else @intFromBool(diff > 0)
    );
  }
  var isSameSign : bool = true;
  for (1..,slice) |i, _| {
    if (1+i >= slice.len) break;
    if (temp[i] != temp[i-1] or temp[i-1] == -1 or temp[i] == -1) {
      isSameSign = false;
      break;
    }
  }
  return isSameSign;
}

pub fn part1(valuesAllocation : * const std.ArrayList(i64)) !void {
  var valuesIterator = std.mem.splitScalar(i64, valuesAllocation.items, -1);
  // in pseudo-code D:
  // for v in values:
  //   (v, v[1..$]).zip
  //     .filter(|x, y| => (0<abs(x-y)<4) ?: 0)
  //     .filter(|x, y| => sign(x)==sign(y) && x!=0 && y!=0)
  //     .count
  var sum : usize = 0;
  while (valuesIterator.next()) |values| {
    if (values.len == 0) continue;
    sum += @intFromBool(try helperSolve(values, -1));
  }
  std.debug.print("sum: {}\n", .{sum});
}

pub fn part2(valuesAllocation : * const std.ArrayList(i64)) !void {
  var valuesIterator = std.mem.splitScalar(i64, valuesAllocation.items, -1);
  // pretty ugly but just permute every removed index
  var sum : usize = 0;
  var temp : [128] i64 = undefined;
  while (valuesIterator.next()) |values| {
    if (values.len == 0) continue;
    // no need to check original array since it shouldn't break by removing 1
    // use temp array to create a copy of the original array without 1 element
    for (0..,values) |ignoreIdx, _| {
      var tempIdx : usize = 0;
      for (0..,values) |vIdx, _| {
        if (vIdx == ignoreIdx) continue;
        temp[tempIdx] = values.ptr[vIdx];
        tempIdx += 1;
      }
      // try with this permutation
      if (try helperSolve(temp[0..tempIdx])) {
        sum += 1;
        break;
      }
    }
  }
  std.debug.print("sum: {}\n", .{sum});
}

pub fn main() !void {
  var gpa = std.heap.GeneralPurposeAllocator(.{}){};
  defer _ = gpa.deinit();

  // make a single 1D array with -1 scalars to split into 2D 'range'
  const valuesAllocation = try parseInput(gpa.allocator());
  defer valuesAllocation.deinit();

  try part1(&valuesAllocation);
  try part2(&valuesAllocation);
}
