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
fn display_range_summary(
  line : @displayline.DisplayLine,
  width : Int,
) -> String {
  let parts : Array[String] = []
  for range in line.wrap(width) {
    parts.push(
      "\{range.view(line)}:w\{range.width()}:c\{line.display_position(range.start()).column()}-\{line.display_position(range.end()).column()}",
    )
  }
  parts.join("|")
}

///|
fn view_at_or_before(line : @displayline.DisplayLine, column : Int) -> String {
  line
  .view(
    line.start(),
    line.textual_position_at_or_before(
      @displayline.DisplayPosition::new(column~),
    ),
  )
  .to_owned()
}

///|
fn view_at_or_after(line : @displayline.DisplayLine, column : Int) -> String {
  line
  .view(
    line.start(),
    line.textual_position_at_or_after(
      @displayline.DisplayPosition::new(column~),
    ),
  )
  .to_owned()
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
test "display line maps exact display boundaries" {
  let line = @displayline.display_line("a你好b")
  inspect(view_at_or_before(line, 1), content="a")
  inspect(view_at_or_after(line, 1), content="a")
  inspect(view_at_or_before(line, 3), content="a你")
  inspect(view_at_or_after(line, 3), content="a你")
  inspect(view_at_or_before(line, 5), content="a你好")
  inspect(view_at_or_after(line, 5), content="a你好")
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
test "display line handles empty input" {
  let line = @displayline.display_line("")
  let start = line.start()
  inspect(line.width(), content="0")
  inspect(line.end() == start, content="true")
  inspect(line.next(start) is None, content="true")
  inspect(line.prev(start) is None, content="true")
  inspect(line.view(start, line.end()), content="")
  inspect(line.truncate(1), content="")
  inspect(line.truncate(0), content="")
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
test "display line keeps combining mark with base" {
  let line = @displayline.display_line("e\u{301}x")
  let after_accented_e = line.next(line.start()).unwrap()
  inspect(line.width(), content="2")
  inspect(line.view(line.start(), after_accented_e), content="e\u{301}")
  inspect(line.display_position(after_accented_e).column(), content="1")
}

///|
test "display line exposes zero-width unit boundaries" {
  let line = @displayline.display_line("a\u{200B}b")
  let units = line.units()
  let after_a = line.next(line.start()).unwrap()
  let after_zero = line.next(after_a).unwrap()
  inspect(line.width(), content="2")
  inspect(units.length(), content="3")
  inspect(units[1].text() == "\u{200B}", content="true")
  inspect(units[1].width(), content="0")
  inspect(units[1].display_start().column(), content="1")
  inspect(units[1].display_end().column(), content="1")
  inspect(line.display_position(after_a).column(), content="1")
  inspect(line.display_position(after_zero).column(), content="1")
  inspect(view_at_or_before(line, 1), content="a\u{200B}")
  inspect(view_at_or_after(line, 1), content="a")
}

///|
test "display line handles leading zero-width unit" {
  let line = @displayline.display_line("\u{200B}a")
  let after_zero = line.next(line.start()).unwrap()
  inspect(line.width(), content="1")
  inspect(line.display_position(after_zero).column(), content="0")
  inspect(view_at_or_before(line, 0), content="\u{200B}")
  inspect(view_at_or_after(line, 0), content="")
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

///|
test "display line truncates without cutting complex units" {
  let emoji_line = @displayline.display_line("x👨‍👩‍👧‍👦y")
  inspect(emoji_line.truncate(3), content="x…")
  let combining_line = @displayline.display_line("e\u{301}xy")
  inspect(combining_line.truncate(2), content="e\u{301}…")
  let zero_width_line = @displayline.display_line("a\u{200B}b")
  inspect(zero_width_line.truncate(1, suffix=""), content="a\u{200B}")
}

///|
test "display line units returns a copy" {
  let line = @displayline.display_line("a你好b")
  let units = line.units()
  units.push(units[0])
  inspect(units.length(), content="5")
  inspect(line.units().length(), content="4")
}

///|
test "display line wraps on display unit boundaries" {
  let line = @displayline.display_line("a你好b")
  inspect(display_range_summary(line, 3), content="a你:w3:c0-3|好b:w3:c3-6")
  inspect(
    display_range_summary(line, 2),
    content="a:w1:c0-1|你:w2:c1-3|好:w2:c3-5|b:w1:c5-6",
  )
}

///|
test "display line wrap handles empty and invalid width" {
  let empty = @displayline.display_line("")
  let ranges = empty.wrap(4)
  inspect(ranges.length(), content="1")
  inspect(ranges[0].view(empty), content="")
  inspect(ranges[0].width(), content="0")
  let line = @displayline.display_line("ab")
  inspect(display_range_summary(line, 0), content="a:w1:c0-1|b:w1:c1-2")
  inspect(display_range_summary(line, -1), content="a:w1:c0-1|b:w1:c1-2")
}

///|
test "display line wrap handles emoji and zero-width units" {
  let emoji = @displayline.display_line("x👨‍👩‍👧‍👦y")
  inspect(
    display_range_summary(emoji, 3),
    content="x👨‍👩‍👧‍👦:w3:c0-3|y:w1:c3-4",
  )
  let zero_width = @displayline.display_line("a\u{200B}b")
  let ranges = zero_width.wrap(1)
  inspect(ranges.length(), content="2")
  inspect(ranges[0].view(zero_width), content="a\u{200B}")
  inspect(ranges[0].width(), content="1")
  inspect(ranges[1].view(zero_width), content="b")
  inspect(ranges[1].width(), content="1")
}

///|
test "display line wrap keeps oversized unit whole" {
  let line = @displayline.display_line("a你b")
  inspect(
    display_range_summary(line, 1),
    content="a:w1:c0-1|你:w2:c1-3|b:w1:c3-4",
  )
}
