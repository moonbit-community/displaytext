// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0>. This file may not be
// copied, modified, or distributed except according to those terms.

///|
/// A legal boundary in a `DisplayText`.
///
/// Values are produced by `DisplayText` methods. They are intentionally opaque
/// so callers cannot accidentally point into the middle of a display unit.
struct TextualPosition(Int) derive(Eq)

///|
/// A display-column position in a single `DisplayText`.
struct DisplayPosition(Int) derive(Eq)

///|
/// Build a single-line display position. Negative columns are clamped to zero.
pub fn DisplayPosition::new(column~ : Int) -> DisplayPosition {
  DisplayPosition(column.max(0))
}

///|
/// The zero-based terminal display column.
pub fn DisplayPosition::column(self : DisplayPosition) -> Int {
  self.0
}

///|
/// A terminal display unit with stable textual and display boundaries.
///
/// Textual boundaries are legal positions in the original line. Display
/// boundaries are terminal display columns. Both ranges are half-open:
/// `[start, end)`.
///
/// For example, `split_lines("a你好b")[0]` has these units:
///
/// ```text
/// textual:   0     1      2      3     4
///            | "a" | "你" | "好" | "b" |
/// display:   0     1      3      5     6
/// ```
///
/// A ZWJ emoji sequence is one unit even when it is made from several emoji
/// joined together. For `split_lines("x👨‍👩‍👧‍👦y")[0]`:
///
/// ```text
/// textual:   0     1      2     3
///            | "x" | "👨‍👩‍👧‍👦" | "y" |
/// display:   0     1      3     4
/// ```
///
/// A zero-width unit has the same display start and end. For
/// `split_lines("a\u{200B}b")[0]`:
///
/// ```text
/// textual:    0     1            2     3
///             | "a" | "\u{200B}" | "b" |
/// display:    0     1            1     2
/// ```
priv struct DisplayUnit {
  text : StringView
  width : Int
  textual_end : TextualPosition
  display_end : DisplayPosition
}

///|
fn DisplayUnit::text(self : DisplayUnit) -> StringView {
  self.text
}

///|
fn DisplayUnit::width(self : DisplayUnit) -> Int {
  self.width
}

///|
fn DisplayUnit::textual_end(self : DisplayUnit) -> TextualPosition {
  self.textual_end
}

///|
fn DisplayUnit::display_end(self : DisplayUnit) -> DisplayPosition {
  self.display_end
}

///|
/// A single text run parsed into terminal display units.
struct DisplayText {
  text : String
  units : Array[DisplayUnit]
  width : Int
  cjk : Bool
}

///|
fn make_display_unit(
  text : StringView,
  width : Int,
  textual_index : Int,
  display_column : Int,
) -> DisplayUnit {
  {
    text,
    width,
    textual_end: TextualPosition(textual_index + 1),
    display_end: DisplayPosition(display_column + width),
  }
}

///|
fn flush_pending_unit(
  units : Array[DisplayUnit],
  source : String,
  start : Int,
  end : Int,
  width : Int,
  display_column : Int,
) -> Int {
  units.push(
    make_display_unit(
      source.view(start_offset=start, end_offset=end),
      width,
      units.length(),
      display_column,
    ),
  )
  display_column + width
}

///|
fn single_unit_line(source : String, width : Int, cjk : Bool) -> DisplayText {
  if source.length() == 0 {
    { text: source, units: [], width, cjk }
  } else {
    {
      text: source,
      units: [make_display_unit(source.view(), width, 0, 0)],
      width,
      cjk,
    }
  }
}

///|
fn display_units_for(source : String, cjk : Bool) -> Array[DisplayUnit] {
  let units : Array[DisplayUnit] = []
  let mut display_column = 0
  let mut pending_start = 0
  let mut pending_end = 0
  let mut pending_width = 0
  let mut has_pending = false
  for grapheme in @grapheme.grapheme_iter(source) {
    let grapheme_width = @unicodewidth.str_width(grapheme, cjk~)
    if !has_pending {
      pending_start = grapheme.start_offset()
      pending_end = grapheme.start_offset() + grapheme.length()
      pending_width = grapheme_width
      has_pending = true
    } else {
      let next_end = grapheme.start_offset() + grapheme.length()
      let combined_width = @unicodewidth.str_width(
        source.view(start_offset=pending_start, end_offset=next_end),
        cjk~,
      )
      if combined_width == pending_width + grapheme_width {
        display_column = flush_pending_unit(
          units, source, pending_start, pending_end, pending_width, display_column,
        )
        pending_start = grapheme.start_offset()
        pending_end = next_end
        pending_width = grapheme_width
      } else {
        pending_end = next_end
        pending_width = combined_width
      }
    }
  }
  if has_pending {
    ignore(
      flush_pending_unit(
        units, source, pending_start, pending_end, pending_width, display_column,
      ),
    )
  }
  units
}

///|
fn make_display_text(source : String, cjk : Bool) -> DisplayText {
  let width = @unicodewidth.str_width(source, cjk~)
  let units = display_units_for(source, cjk)
  let mut unit_width = 0
  for unit in units {
    unit_width += unit.width()
  }
  if unit_width == width {
    { text: source, units, width, cjk }
  } else {
    single_unit_line(source, width, cjk)
  }
}

///|
/// Parse `text` as one terminal display text run.
///
/// This constructor does not split hard line breaks. If `text` contains `\n`,
/// `\r\n`, or `\r`, they remain part of this single `DisplayText`. Use
/// `split_lines` when the input may contain multiple hard lines.
pub fn DisplayText::new(text : String, cjk? : Bool = false) -> DisplayText {
  make_display_text(text, cjk)
}

///|
/// Split `text` into hard-line display text runs.
///
/// Hard line breaks (`\n`, `\r\n`, and `\r`) are not included in the returned
/// lines. Empty lines are preserved, including the trailing empty line after a
/// final line break. Each returned `DisplayText` exposes safe textual
/// boundaries and display columns for TUI editing, truncation, and hit testing.
pub fn split_lines(
  text : StringView,
  cjk? : Bool = false,
) -> Array[DisplayText] {
  let source = text.to_owned()
  let lines : Array[DisplayText] = []
  let mut current = StringBuilder()
  for grapheme in @grapheme.grapheme_iter(source) {
    let g = grapheme.to_owned()
    if g == "\n" || g == "\r\n" || g == "\r" {
      lines.push(DisplayText::new(current.to_string(), cjk~))
      current = StringBuilder()
    } else {
      current.write_string(g)
    }
  }
  lines.push(DisplayText::new(current.to_string(), cjk~))
  lines
}

///|
/// Total display width of this text run in terminal cells.
pub fn DisplayText::width(self : DisplayText) -> Int {
  self.width
}

///|
/// The first legal textual boundary in this text run.
pub fn DisplayText::start(self : DisplayText) -> TextualPosition {
  ignore(self)
  TextualPosition(0)
}

///|
/// The final legal textual boundary in this text run.
pub fn DisplayText::end(self : DisplayText) -> TextualPosition {
  TextualPosition(self.units.length())
}

///|
fn DisplayText::position_index(
  self : DisplayText,
  position : TextualPosition,
) -> Int {
  position.0.clamp(min=0, max=self.units.length())
}

///|
/// The next legal textual boundary after `position`, if any.
pub fn DisplayText::next(
  self : DisplayText,
  position : TextualPosition,
) -> TextualPosition? {
  let index = self.position_index(position)
  if index >= self.units.length() {
    None
  } else {
    Some(TextualPosition(index + 1))
  }
}

///|
/// The previous legal textual boundary before `position`, if any.
pub fn DisplayText::prev(
  self : DisplayText,
  position : TextualPosition,
) -> TextualPosition? {
  let index = self.position_index(position)
  if index <= 0 {
    None
  } else {
    Some(TextualPosition(index - 1))
  }
}

///|
/// Convert a legal textual boundary to its display-column position.
pub fn DisplayText::display_position(
  self : DisplayText,
  position : TextualPosition,
) -> DisplayPosition {
  let index = self.position_index(position)
  if index == 0 {
    DisplayPosition(0)
  } else {
    self.units[index - 1].display_end()
  }
}

///|
/// Return the nearest legal textual boundary at or before `position`.
pub fn DisplayText::textual_position_at_or_before(
  self : DisplayText,
  position : DisplayPosition,
) -> TextualPosition {
  let column = position.column().clamp(min=0, max=self.width)
  let mut result = self.start()
  for unit in self.units {
    if unit.display_end().column() <= column {
      result = unit.textual_end()
    } else {
      return result
    }
  }
  result
}

///|
/// Return the nearest legal textual boundary at or after `position`.
pub fn DisplayText::textual_position_at_or_after(
  self : DisplayText,
  position : DisplayPosition,
) -> TextualPosition {
  let column = position.column().clamp(min=0, max=self.width)
  if column <= 0 {
    return self.start()
  }
  for unit in self.units {
    if unit.display_end().column() >= column {
      return unit.textual_end()
    }
  }
  self.end()
}

///|
/// View between two legal textual boundaries.
pub fn DisplayText::view(
  self : DisplayText,
  start : TextualPosition,
  end : TextualPosition,
) -> StringView {
  let start = self.position_index(start)
  let end = self.position_index(end)
  let start_offset = if start >= self.units.length() {
    self.text.length()
  } else {
    self.units[start].text().start_offset()
  }
  let end_offset = if end <= start {
    start_offset
  } else {
    let end_text = self.units[end - 1].text()
    end_text.start_offset() + end_text.length()
  }
  self.text.view(start_offset~, end_offset~)
}

///|
/// Truncate this text run to `width` display cells, appending `suffix` when
/// content is dropped.
pub fn DisplayText::truncate(
  self : DisplayText,
  width : Int,
  suffix? : StringView = "…",
) -> String {
  guard width > 0 else { return "" }
  guard self.width > width else { return self.text }
  let suffix_width = @unicodewidth.str_width(suffix, cjk=self.cjk)
  guard suffix_width <= width else { return "" }
  let content_width = width - suffix_width
  let builder = StringBuilder()
  let mut used = 0
  for unit in self.units {
    if used + unit.width() > content_width {
      break
    }
    builder.write_stringview(unit.text())
    used += unit.width()
  }
  builder.write_stringview(suffix)
  builder.to_string()
}
