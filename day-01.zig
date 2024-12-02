const std = @import("std");

const day = 1;
pub fn logSolution(part : i64, value : i64) void {
  std.debug.print("Day {} part {} | solution: {}\n", .{day, part, value});
}

pub fn main() !void {
  // i cheat here since input-01 is formatted with newlines
  const contents = @embedFile("input-01");

  // --- part 1
  // from two lists of numbers, find the sum of the absolute difference
  // btwn sorted pairs
  // pseudo code
  // zip(list0.sort, list1.sort).map(|a, b| abs(a - b)).sum()

  // -- split the contents from whitespace
  var lineIterator = std.mem.split(u8, contents, "\n");
  var list0 : [1000] i64 = undefined;
  var list1 : [1000] i64 = undefined;
  const list0Slice = list0[0..];
  const list1Slice = list1[0..];

  // -- collect each number into separate lists to sort
  {
    var it : usize = 0;
    while (lineIterator.peek() != null) {
      const line = lineIterator.next().?;
      if (line.len == 0)
        continue;
      const lineNumber = try std.fmt.parseInt(i64, line, 10);
      if (it % 2 == 0) {
        list0[it / 2] = lineNumber;
      } else {
        list1[it / 2] = lineNumber;
      }
      it += 1;
    }
  }

  // -- sort
  std.mem.sort(i64, list0Slice, {}, comptime std.sort.asc(i64));
  std.mem.sort(i64, list1Slice, {}, comptime std.sort.asc(i64));

  // -- sum
  {
    var sum : i64 = 0;
    for (0.., list0Slice) |i, _| {
      sum += @as(i64, @intCast(@abs(list0[i] - list1[i])));
    }

    logSolution(1, sum);
  }

  // --- part 2
  // need to find numbers repeated from list1 in list0, then multiply it
  // by the number of their occurences
  // pseudo code:
  //   cache = list1.sort.groupBy(it).map(it => it.count)
  //   sum = list0.map(it => it * cache[it]).sum()

  // -- collect into a cached map
  var gpa = std.heap.GeneralPurposeAllocator(.{}){};
  var cacheMap = std.hash_map.AutoHashMap(i64, i64).init(gpa.allocator());
  defer _ = gpa.deinit();
  defer cacheMap.deinit();

  for (list1Slice) |item| {
    const cache = cacheMap.get(item);
    if (cache != null) {
      try cacheMap.put(item, cache.? + 1);
    } else {
      try cacheMap.put(item, 1);
    }
  }

  // -- iterate through list0 and multiply by the count in the cache
  {
    var sum : i64 = 0;
    for (list0Slice) |item| {
      const cache = cacheMap.get(item);
      if (cache != null) {
        sum += item * cache.?;
      }
    }

    logSolution(2, sum);
  }
}
