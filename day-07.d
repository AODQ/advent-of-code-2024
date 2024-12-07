module day_07;
import std.concurrency : spawn, thisTid, Tid, receiveOnly, send;
import std.algorithm :
  map, reduce, fold, filter, all, any, find, equal, equal, cartesianProduct;
import std.array : array, split, replicate;
import std.conv : to;
import std.file;
import std.regex : matchAll;
import std.stdio : writeln;
import std.range : tee, retro, enumerate, empty, repeat, iota;
import std.typecons : tuple;
import std.bitmanip : BitArray;
import std.parallelism : parallel;
import core.atomic : atomicOp;
import std.math : log10;

struct InputTask {
  ulong expectedOutput;
  ulong[] data;
}

enum Advent1 { add, mul, }
enum Advent2 { add, mul, app, }

ulong opAppend(ulong a, ulong b) pure {
  const numDigits = 1 + cast(ulong)((cast(real)b).log10);
  return a * 10 ^^ numDigits + b;
}

// recursion to eliminate dead branches quickly
ulong adventTaskRecurse(E)(
  const InputTask task,
  const ulong index,
  const ulong sum
) pure {
  if (index == task.data.length) { return sum; }
  static foreach (eIdx; E.min .. E.max+1) {{
    mixin(
        `const newSum = sum `
      ~ ["+", "*", ".opAppend"][eIdx] ~ `(task.data[index]);`
    );
    if (newSum <= task.expectedOutput) {
      const newRecursedSum = adventTaskRecurse!E(task, index+1, newSum);
      if (newRecursedSum == task.expectedOutput) return newRecursedSum;
    }
  }}
  return 0;
}

ulong advent(E)(const(InputTask)[] tasks) {
  shared ulong sum = 0;
  foreach (task; tasks.parallel) { // multi-thread
    ulong value = adventTaskRecurse!E(task, 1, task.data[0]);
    if (value > 0) sum.atomicOp!"+="(task.expectedOutput);
  }
  return sum;
}

auto splitNoEnd(T)(T a, string s) pure { return a.split(s).filter!"!a.empty"; }

void main() {
  import core.memory;
  GC.disable; // disable GC saves ~500us
  const tasks = (
    (cast(string)"input-07".readText)
    .splitNoEnd("\n")
    .map!(a => a.split(":"))
    .map!(
      a => InputTask(a[0].to!ulong, a[1].splitNoEnd(" ").map!"a.to!ulong".array)
    )
    .array
  );

  tasks.advent!Advent1.writeln;
  tasks.advent!Advent2.writeln;
}
