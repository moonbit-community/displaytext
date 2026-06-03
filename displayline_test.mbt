// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0>. This file may not be
// copied, modified, or distributed except according to those terms.

///|
fn display_unit_summary(line : @displayline.DisplayLine) -> String {
  let parts : Array[String] = []
  for unit in line.units() {
    parts.push(
      "\{unit.text()}:w\{unit.width()}:c\{unit.display_start().column()}-\{unit.display_end().column()}",
    )
  }
  parts.join("|")
}

///|
test "display line exposes display units" {
  let line = @displayline.display_line("a你好b")
  inspect(line.width(), content="6")
  inspect(
    display_unit_summary(line),
    content="a:w1:c0-1|你:w2:c1-3|好:w2:c3-5|b:w1:c5-6",
  )
}

///|
test "display line exposes unit textual boundaries" {
  let line = @displayline.display_line("a你好b")
  let units = line.units()
  inspect(
    line.view(units[0].textual_start(), units[0].textual_end()),
    content="a",
  )
  inspect(
    line.view(units[1].textual_start(), units[1].textual_end()),
    content="你",
  )
}

///|
test "display line maps textual and display positions" {
  let line = @displayline.display_line("a你好b")
  let after_a = line.next(line.start()).unwrap()
  let after_ni = line.next(after_a).unwrap()
  let after_hao = line.next(after_ni).unwrap()
  inspect(line.view(after_a, after_hao), content="你好")
  inspect(line.display_position(after_ni).column(), content="3")
  let inside_ni = @displayline.DisplayPosition::new(column=2)
  inspect(
    line.view(line.start(), line.textual_position_at_or_before(inside_ni)),
    content="a",
  )
  inspect(
    line.view(line.start(), line.textual_position_at_or_after(inside_ni)),
    content="a你",
  )
}

///|
test "display line handles boundary positions" {
  let line = @displayline.display_line("a你好b")
  let start = line.start()
  let end = line.end()
  inspect(line.display_position(start).column(), content="0")
  inspect(line.next(end) is None, content="true")
  inspect(line.prev(start) is None, content="true")
  let before_end = line.prev(end).unwrap()
  inspect(line.view(before_end, end), content="b")
  inspect(
    line.textual_position_at_or_after(
      @displayline.DisplayPosition::new(column=0),
    ) ==
    start,
    content="true",
  )
  inspect(
    line.textual_position_at_or_after(
      @displayline.DisplayPosition::new(column=99),
    ) ==
    end,
    content="true",
  )
  inspect(line.view(end, start), content="")
}

///|
test "display line keeps emoji zwj as one unit" {
  let line = @displayline.display_line("x👨‍👩‍👧‍👦y")
  inspect(line.width(), content="4")
  inspect(
    display_unit_summary(line),
    content="x:w1:c0-1|👨‍👩‍👧‍👦:w2:c1-3|y:w1:c3-4",
  )
}

///|
test "display line merges non additive grapheme runs" {
  let line = @displayline.display_line("\u{644}\u{627}")
  inspect(line.width(), content="1")
  inspect(display_unit_summary(line), content="لا:w1:c0-1")
  assert_true(line.next(line.start()).unwrap() == line.end())
}

///|
test "display line truncates by display units" {
  let line = @displayline.display_line("a你好b")
  inspect(line.truncate(4), content="a你…")
  inspect(line.truncate(1), content="…")
  inspect(line.truncate(0), content="")
  inspect(line.truncate(-1), content="")
  inspect(line.truncate(6), content="a你好b")
  inspect(line.truncate(4, suffix=""), content="a你")
  inspect(line.truncate(1, suffix="你好"), content="")
}
