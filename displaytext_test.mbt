// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0>. This file may not be
// copied, modified, or distributed except according to those terms.

///|
fn line(text : String) -> @displaytext.DisplayText {
  @displaytext.DisplayText::new(text)
}

///|
fn line_texts(lines : Array[@displaytext.DisplayText]) -> String {
  let parts : Array[String] = []
  for line in lines {
    parts.push(line.text())
  }
  parts.join("|")
}

///|
fn display_unit_summary(line : @displaytext.DisplayText) -> String {
  let parts : Array[String] = []
  let mut start = line.start()
  let mut done = false
  while !done {
    match line.next(start) {
      Some(end) => {
        let display_start = line.display_position(start).column()
        let display_end = line.display_position(end).column()
        parts.push(
          "\{line.view(start, end)}:w\{display_end - display_start}:c\{display_start}-\{display_end}",
        )
        start = end
      }
      None => done = true
    }
  }
  parts.join("|")
}

///|
fn view_at_or_before(line : @displaytext.DisplayText, column : Int) -> String {
  line
  .view(
    line.start(),
    line.textual_position_at_or_before(
      @displaytext.DisplayPosition::new(column~),
    ),
  )
  .to_owned()
}

///|
fn view_at_or_after(line : @displaytext.DisplayText, column : Int) -> String {
  line
  .view(
    line.start(),
    line.textual_position_at_or_after(
      @displaytext.DisplayPosition::new(column~),
    ),
  )
  .to_owned()
}

///|
test "split lines handles hard line breaks" {
  let lines = @displaytext.split_lines("a\r\nb\rc\n")
  inspect(lines.length(), content="4")
  inspect(line_texts(lines), content="a|b|c|")
}

///|
test "split lines preserves empty lines" {
  let empty = @displaytext.split_lines("")
  inspect(empty.length(), content="1")
  inspect(line_texts(empty), content="")
  let lines = @displaytext.split_lines("a\n\nb")
  inspect(lines.length(), content="3")
  inspect(line_texts(lines), content="a||b")
}

///|
test "display line constructor treats input as one line" {
  let line = @displaytext.DisplayText::new("a\nb")
  inspect(line.text(), content="a\nb")
  inspect(@displaytext.split_lines("a\nb").length(), content="2")
}

///|
test "display line exposes display boundaries" {
  let line = line("a你好b")
  inspect(line.width(), content="6")
  inspect(
    display_unit_summary(line),
    content="a:w1:c0-1|你:w2:c1-3|好:w2:c3-5|b:w1:c5-6",
  )
}

///|
test "display line maps textual and display positions" {
  let line = line("a你好b")
  let after_a = line.next(line.start()).unwrap()
  let after_ni = line.next(after_a).unwrap()
  let after_hao = line.next(after_ni).unwrap()
  inspect(line.view(after_a, after_hao), content="你好")
  inspect(line.display_position(after_ni).column(), content="3")
  let inside_ni = @displaytext.DisplayPosition::new(column=2)
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
  let line = line("a你好b")
  inspect(view_at_or_before(line, 1), content="a")
  inspect(view_at_or_after(line, 1), content="a")
  inspect(view_at_or_before(line, 3), content="a你")
  inspect(view_at_or_after(line, 3), content="a你")
  inspect(view_at_or_before(line, 5), content="a你好")
  inspect(view_at_or_after(line, 5), content="a你好")
}

///|
test "display line handles boundary positions" {
  let line = line("a你好b")
  let start = line.start()
  let end = line.end()
  inspect(line.display_position(start).column(), content="0")
  inspect(line.next(end) is None, content="true")
  inspect(line.prev(start) is None, content="true")
  let before_end = line.prev(end).unwrap()
  inspect(line.view(before_end, end), content="b")
  inspect(
    line.textual_position_at_or_after(
      @displaytext.DisplayPosition::new(column=0),
    ) ==
    start,
    content="true",
  )
  inspect(
    line.textual_position_at_or_after(
      @displaytext.DisplayPosition::new(column=99),
    ) ==
    end,
    content="true",
  )
  inspect(line.view(end, start), content="")
}

///|
test "display line handles empty input" {
  let line = line("")
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
test "display line keeps emoji zwj as one boundary" {
  let line = line("x👨‍👩‍👧‍👦y")
  inspect(line.width(), content="4")
  inspect(
    display_unit_summary(line),
    content="x:w1:c0-1|👨‍👩‍👧‍👦:w2:c1-3|y:w1:c3-4",
  )
}

///|
test "display line keeps combining mark with base" {
  let line = line("e\u{301}x")
  let after_accented_e = line.next(line.start()).unwrap()
  inspect(line.width(), content="2")
  inspect(line.view(line.start(), after_accented_e), content="e\u{301}")
  inspect(line.display_position(after_accented_e).column(), content="1")
}

///|
test "display line exposes zero-width boundaries" {
  let line = line("a\u{200B}b")
  let after_a = line.next(line.start()).unwrap()
  let after_zero = line.next(after_a).unwrap()
  inspect(line.width(), content="2")
  inspect(line.view(after_a, after_zero), content="\u{200B}")
  inspect(line.display_position(after_a).column(), content="1")
  inspect(line.display_position(after_zero).column(), content="1")
  inspect(view_at_or_before(line, 1), content="a\u{200B}")
  inspect(view_at_or_after(line, 1), content="a")
}

///|
test "display line handles leading zero-width boundary" {
  let line = line("\u{200B}a")
  let after_zero = line.next(line.start()).unwrap()
  inspect(line.width(), content="1")
  inspect(line.display_position(after_zero).column(), content="0")
  inspect(view_at_or_before(line, 0), content="\u{200B}")
  inspect(view_at_or_after(line, 0), content="")
}

///|
test "display line merges non additive grapheme runs" {
  let line = line("\u{644}\u{627}")
  inspect(line.width(), content="1")
  inspect(display_unit_summary(line), content="لا:w1:c0-1")
  assert_true(line.next(line.start()).unwrap() == line.end())
}

///|
test "display line finds legal prefix by display column" {
  let line = line("ab你好")
  let three = @displaytext.DisplayPosition::new(column=3)
  inspect(
    line.view(line.start(), line.textual_position_at_or_before(three)),
    content="ab",
  )
  inspect(
    line.view(line.start(), line.textual_position_at_or_after(three)),
    content="ab你",
  )
}

///|
test "display line truncates by display units" {
  let line = line("a你好b")
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
  let emoji_line = line("x👨‍👩‍👧‍👦y")
  inspect(emoji_line.truncate(3), content="x…")
  let combining_line = line("e\u{301}xy")
  inspect(combining_line.truncate(2), content="e\u{301}…")
  let zero_width_line = line("a\u{200B}b")
  inspect(zero_width_line.truncate(1, suffix=""), content="a\u{200B}")
}
