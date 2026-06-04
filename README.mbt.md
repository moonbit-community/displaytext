# displaytext

Grapheme-aware display-cell text boundaries for terminal UIs.

`displaytext` combines Unicode grapheme cluster boundaries with
[`unicodewidth`](https://github.com/moonbit-community/unicodewidth.mbt)
display-width rules. TUI authors can split plain text into hard lines, move
through each line by safe textual positions, map between textual positions and
terminal columns, create zero-copy views, and truncate without cutting through a
display unit.

## Installation

```console
> moon add moonbit-community/displaytext
```

## API

### `DisplayText(s : String, cjk? : Bool = false) -> DisplayText`

Parses `s` as one terminal display text run.

- `s`: text that the caller already wants to measure and navigate as one run
- `cjk`: when `true`, ambiguous-width characters are treated as wide

This constructor does not split hard line breaks. If `s` contains `\n`,
`\r\n`, or `\r`, those characters remain part of the returned `DisplayText`.
Use `split_lines` for arbitrary multiline text.

### `split_lines(s : @string.View, cjk? : Bool = false) -> Array[DisplayText]`

Splits plain text into hard lines and parses each line into terminal display
boundaries.

- `s`: plain text that may contain hard line breaks
- `cjk`: when `true`, ambiguous-width characters are treated as wide

Hard line breaks are `\n`, `\r\n`, and `\r`. They are not included in returned
lines. Empty lines are preserved, including the trailing empty line after a
final line break.

Each returned `DisplayText` exposes:

- total display width with `width()`
- legal textual boundaries with `start()`, `end()`, `next()`, and `prev()`
- conversion from textual boundaries to columns with `display_position()`
- conversion from display columns to textual boundaries with
  `textual_position_at_or_before()` and `textual_position_at_or_after()`
- zero-copy text views with `view()`
- terminal-cell truncation with `truncate()`

## Usage

```mbt check
///|
test {
  let lines = @displaytext.split_lines("a你好b\nnext")
  let line = lines[0]

  // Whole-line display width.
  assert_eq(line.width(), 6)

  // Move by legal textual positions, not UTF-16 code units.
  let after_a = line.next(line.start()).unwrap()
  let after_ni = line.next(after_a).unwrap()
  assert_eq(line.display_position(after_ni).column(), 3)

  // Convert a display column inside a wide character back to text boundaries.
  let middle = @displaytext.DisplayPosition::new(column=2)
  assert_eq(
    line.view(line.start(), line.textual_position_at_or_before(middle)),
    "a",
  )
  assert_eq(
    line.view(line.start(), line.textual_position_at_or_after(middle)),
    "a你",
  )

  // Truncate without cutting through a display unit.
  assert_eq(line.truncate(4), "a你…")
}
```

### Consumer-Owned Wrapping

Soft wrapping is a layout policy owned by the application. A TUI can maintain
its own used display columns and ask a `DisplayText` for the legal textual
boundary that fits the remaining width.

```mbt check
///|
test {
  let line = @displaytext.DisplayText::DisplayText("ab你好")
  let remaining = @displaytext.DisplayPosition::new(column=3)
  let end = line.textual_position_at_or_before(remaining)

  assert_eq(line.view(line.start(), end), "ab")
}
```

## Concepts

`DisplayText` is one run of display-position state. Values created by
`split_lines` never contain `\n`, `\r\n`, or `\r`; values created by
`DisplayText::new` contain exactly the text the caller passed in.

`TextualPosition` is a legal boundary in the original line. Values are produced
by `DisplayText`; callers cannot construct arbitrary positions inside a display
unit.

`DisplayPosition` is a zero-based terminal display column. Construct it with
`DisplayPosition::new(column=...)`; negative columns are clamped to zero.

## Scope

This module provides terminal display-cell boundaries for plain text. It does
not own viewport policy, soft wrapping, rich-text styling, bidi reordering, font
shaping, or pixel measurement.

## Testing

```console
> moon test
```

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for
details.
