# displayline

Grapheme-aware display-cell line layout for cursor mapping and truncation in
terminal UIs.

`displayline` combines Unicode grapheme cluster boundaries with
[`unicodewidth`](https://github.com/moonbit-community/unicodewidth.mbt)
display-width rules. TUI authors can use it to move through a single logical
line, map between textual positions and terminal columns, create zero-copy
views, and truncate without cutting through a display unit.

## Installation

```console
> moon add moonbit-community/displayline
```

## API

### `display_line(s : @string.View, cjk? : Bool = false) -> DisplayLine`

Parses a single logical line into terminal display units and legal textual
positions.

- `s`: the single-line text to lay out
- `cjk`: when `true`, ambiguous-width characters are treated as wide

The returned `DisplayLine` exposes:

- total display width with `width()`
- legal textual boundaries with `start()`, `end()`, `next()`, and `prev()`
- conversion from textual boundaries to columns with `display_position()`
- conversion from display columns to textual boundaries with
  `textual_position_at_or_before()` and `textual_position_at_or_after()`
- zero-copy text views with `view()`
- terminal-cell truncation with `truncate()`

## Usage

```mbt nocheck
///|
test {
  let line = @displayline.display_line("a你好b")

  // Whole-line display width.
  assert_eq(line.width(), 6)

  // Move by legal textual positions, not UTF-16 code units.
  let after_a = line.next(line.start()).unwrap()
  let after_ni = line.next(after_a).unwrap()
  assert_eq(line.display_position(after_ni).column(), 3)

  // Convert a display column inside a wide character back to text boundaries.
  let middle = @displayline.DisplayPosition::new(column=2)
  assert_eq(
    line
    .view(line.start(), line.textual_position_at_or_before(middle))
    .to_owned(),
    "a",
  )
  assert_eq(
    line
    .view(line.start(), line.textual_position_at_or_after(middle))
    .to_owned(),
    "a你",
  )

  // Truncate without cutting through a display unit.
  assert_eq(line.truncate(4), "a你…")
}
```

## Concepts

`TextualPosition` is a legal boundary in the original line. Values are produced
by `DisplayLine`; callers cannot construct arbitrary positions inside a display
unit.

`DisplayPosition` is a zero-based terminal display column. Construct it with
`DisplayPosition::new(column=...)`; negative columns are clamped to zero.

`DisplayUnit` is the smallest slice this layout will step through or truncate
across. Usually it is one grapheme cluster. When adjacent grapheme clusters form
a non-additive display sequence, they are merged into one unit.

## Scope

This module is for one logical line in terminal display cells. It does not do
paragraph layout, wrapping, bidi reordering, font shaping, or pixel measurement.

## Testing

```console
> moon test
```

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for
details.
