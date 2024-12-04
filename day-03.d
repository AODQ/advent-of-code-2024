module day_03;

import std.algorithm : map, reduce, fold;
import std.array : array;
import std.conv : to;
import std.file;
import std.regex : matchAll;
import std.stdio : writeln;
import std.range : tee, retro, enumerate;
import std.typecons : tuple;

void main() {
  const input = (cast(string)readText("input-03"));
  // part 1
  input
    .matchAll(r"mul\((\d+),(\d+)\)")
    .map!"a[1].to!int*a[2].to!int"
    .fold!"a+b"
    .writeln
  ;

  // part 2
  const matches = (
    input
    .matchAll(r"(do\(\)|don\'t\(\))")
    .map!(a => tuple(a[1] == "do()", a.hit.ptr-input.ptr))
    .array
  );

  int doDont(ulong i) {
    foreach (match; matches.retro)
      if (match[1] < i) return match[0] ? 1 : 0;
    return 1;
  }

  input
    .matchAll(r"mul\((\d+),(\d+)\)")
    .map!(a => a[1].to!int * a[2].to!int * doDont(a.hit.ptr-input.ptr))
    .fold!"a+b"
    .writeln
  ;
}
