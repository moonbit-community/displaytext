// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0>. This file may not be
// copied, modified, or distributed except according to those terms.

///|
/// A half-open range on a `DisplayLine`.
///
/// `start` and `end` are textual boundaries in the original line. `width` is
/// the display-cell width covered by that textual range.
struct DisplayRange {
  start : TextualPosition
  end : TextualPosition
  width : Int
}

///|
/// Textual boundary at the start of this range.
pub fn DisplayRange::start(self : DisplayRange) -> TextualPosition {
  self.start
}

///|
/// Textual boundary at the end of this range.
pub fn DisplayRange::end(self : DisplayRange) -> TextualPosition {
  self.end
}

///|
/// Display width of this range in terminal cells.
pub fn DisplayRange::width(self : DisplayRange) -> Int {
  self.width
}

///|
/// View the original text covered by this range on `line`.
pub fn DisplayRange::view(
  self : DisplayRange,
  line : DisplayLine,
) -> StringView {
  line.view(self.start, self.end)
}
