# DisplayLine extraction checkpoint

## Goal

Create `moonbit-community/displayline` as the TUI-facing home for the
grapheme-aware single-line display API extracted from
`moonbit-community/unicodewidth`.

The new module should let TUI authors work with display-cell columns and safe
textual boundaries without depending directly on Unicode grapheme and width
rules.

## Accepted design

`displayline` owns the `DisplayLine` API and depends on:

- `moonbit-community/unicodewidth` for terminal display-cell width rules.
- `kawaz/grapheme` for legal textual boundaries.

`unicodewidth` remains the lower-level width primitive module. It will not
re-export `displayline`, because that would reverse the dependency direction and
create a cycle.

## Target files and surfaces

- `moon.mod`: new module metadata for `moonbit-community/displayline`.
- `moon.pkg`: root package imports for `unicodewidth` and `grapheme`.
- `display_line.mbt`: implementation of `DisplayLine`, `DisplayUnit`,
  `TextualPosition`, and `DisplayPosition`.
- `displayline_test.mbt`: black-box tests for units, position mapping, viewing,
  and truncation.
- `README.mbt.md` and `README.md`: documented usage examples.
- `pkg.generated.mbti`: generated public interface from `moon info`.

## API/interface diff

Public API in this module:

- `pub fn display_line(StringView, cjk? : Bool) -> DisplayLine`
- opaque `DisplayLine`
- opaque `DisplayUnit`
- opaque `TextualPosition`
- opaque `DisplayPosition`
- `DisplayLine::width(Self) -> Int`
- `DisplayLine::units(Self) -> Array[DisplayUnit]`
- `DisplayLine::start(Self) -> TextualPosition`
- `DisplayLine::end(Self) -> TextualPosition`
- `DisplayLine::next(Self, TextualPosition) -> TextualPosition?`
- `DisplayLine::prev(Self, TextualPosition) -> TextualPosition?`
- `DisplayLine::display_position(Self, TextualPosition) -> DisplayPosition`
- `DisplayLine::textual_position_at_or_before(Self, DisplayPosition) -> TextualPosition`
- `DisplayLine::textual_position_at_or_after(Self, DisplayPosition) -> TextualPosition`
- `DisplayLine::view(Self, TextualPosition, TextualPosition) -> StringView`
- `DisplayLine::truncate(Self, Int, suffix? : StringView) -> String`
- `DisplayUnit::text(Self) -> StringView`
- `DisplayUnit::width(Self) -> Int`
- `DisplayUnit::textual_start(Self) -> TextualPosition`
- `DisplayUnit::textual_end(Self) -> TextualPosition`
- `DisplayUnit::display_start(Self) -> DisplayPosition`
- `DisplayUnit::display_end(Self) -> DisplayPosition`
- `DisplayPosition::new(column~ : Int) -> DisplayPosition`
- `DisplayPosition::column(Self) -> Int`

## Open questions

None for the initial extraction. Future performance work can revisit
`DisplayLine::units` returning an array copy versus a custom iterator.

## Next implementation step

Move the existing `DisplayLine` implementation and tests from `unicodewidth`,
then update package metadata and docs for the new module.

## Validation plan

- Run `moon fmt`.
- Run `moon check`.
- Run `moon test`.
- Run `moon info`.
- Review `pkg.generated.mbti`.
- Run `git diff --check`.

## Checkpoint: DisplayRange soft wrap API

### Goal

Move single-line soft wrapping into `displayline` so TUI callers can wrap a
`DisplayLine` without traversing low-level display units.

### Accepted design

Expose `DisplayLine::wrap(width : Int) -> Array[DisplayRange]`.
`DisplayRange` represents a half-open textual range on the original
`DisplayLine`, along with that range's display-cell width.

`width <= 0` is normalized to 1. The returned array always contains at least one
range. Empty lines return one empty range. A display unit wider than the wrap
width is placed in its own range so wrapping never emits an empty range or cuts a
display unit.

### Target files and surfaces

- `display_line.mbt`: add `DisplayRange` and `DisplayLine::wrap`.
- `displayline_test.mbt`: cover wrapping ASCII/CJK, emoji, zero-width units,
  oversized units, empty lines, and invalid widths.
- `README.mbt.md`: document soft wrapping.
- `pkg.generated.mbti`: generated interface update from `moon info`.

### API/interface diff

Expected additions:

- opaque `DisplayRange`
- `DisplayLine::wrap(Self, Int) -> Array[DisplayRange]`
- `DisplayRange::start(Self) -> TextualPosition`
- `DisplayRange::end(Self) -> TextualPosition`
- `DisplayRange::width(Self) -> Int`
- `DisplayRange::view(Self, DisplayLine) -> StringView`

### Open questions

No word-movement API is added. Application-specific word movement can continue
to use `next`, `prev`, and `view`.

### Next implementation step

Implement wrap by scanning existing display units and emitting `DisplayRange`
values at display-cell boundaries.

### Validation plan

- Run `moon fmt`.
- Run `moon check`.
- Run `moon test`.
- Run `moon info`.
- Review `pkg.generated.mbti`.
- Run `git diff --check`.

## Checkpoint: hard-line split and primitive-only API

### Goal

Narrow `displayline` to Unicode-aware hard-line splitting and display-position
primitives. Soft wrapping belongs to consumers such as openseek because they own
viewport, style, and row policy.

### Accepted design

Expose `split_lines(text : StringView, cjk? : Bool) -> Array[DisplayLine]` as
the only public constructor for `DisplayLine`.

`split_lines` accepts arbitrary plain text and splits on hard line breaks:
`\n`, `\r\n`, and `\r`. Line-ending text is not included in returned
`DisplayLine` values. Empty lines are preserved, including the trailing empty
line after a final line break.

Remove public `display_line`, `DisplayLine::wrap`, `DisplayLine::units`, and
`DisplayRange`. Keep `DisplayLine::width`, cursor movement,
display/textual-position conversion, zero-copy `view`, and `truncate`.

Consumers that need soft wrap maintain their own used display columns and use
`textual_position_at_or_before` plus `view` to cut legal prefixes.

### Target files and surfaces

- `display_line.mbt`: add `split_lines`, private single-line construction, and
  remove public `units`/`wrap`.
- `display_range.mbt`: remove the obsolete `DisplayRange` type.
- `displayline_test.mbt`: rewrite tests to use `split_lines` and public
  position/view APIs.
- `README.mbt.md`: document `split_lines` and primitive-only scope.
- `pkg.generated.mbti`: generated public API should remove `display_line`,
  `DisplayLine::wrap`, `DisplayLine::units`, `DisplayRange`, and all
  `DisplayUnit` accessors.
- openseek `displayline-api-trial`: replace `display_line` construction with
  `split_lines`, move soft wrap to composer, and remove direct use of
  `DisplayLine::units`.

### API/interface diff

Expected public API:

- `pub fn split_lines(StringView, cjk? : Bool) -> Array[DisplayLine]`
- opaque `DisplayLine`
- opaque `TextualPosition`
- opaque `DisplayPosition`
- `DisplayLine::width(Self) -> Int`
- `DisplayLine::start(Self) -> TextualPosition`
- `DisplayLine::end(Self) -> TextualPosition`
- `DisplayLine::next(Self, TextualPosition) -> TextualPosition?`
- `DisplayLine::prev(Self, TextualPosition) -> TextualPosition?`
- `DisplayLine::display_position(Self, TextualPosition) -> DisplayPosition`
- `DisplayLine::textual_position_at_or_before(Self, DisplayPosition) -> TextualPosition`
- `DisplayLine::textual_position_at_or_after(Self, DisplayPosition) -> TextualPosition`
- `DisplayLine::view(Self, TextualPosition, TextualPosition) -> StringView`
- `DisplayLine::truncate(Self, Int, suffix? : StringView) -> String`
- `DisplayPosition::new(column~ : Int) -> DisplayPosition`
- `DisplayPosition::column(Self) -> Int`

### Open questions

None for this pass. `tui/doc` rich styled wrapping may still need follow-up
after the plain composer migration is validated.

### Next implementation step

Update `displayline`, run its tests, then migrate openseek against the new API.

### Validation plan

- Run `moon fmt`.
- Run `moon check`.
- Run `moon test`.
- Run `moon info`.
- Review `pkg.generated.mbti`.
- Run `git diff --check`.
- In openseek trial worktree, run `moon check`, targeted native TUI tests,
  `moon info`, and `git diff --check`.

## Checkpoint: explicit single-line constructor

### Goal

Avoid the awkward `split_lines(text)[0]` pattern when callers already know a
piece of text is a single display line, and keep hard-line splitting as a
separate operation.

### Accepted design

Expose `DisplayLine::new(text : String, cjk? : Bool = false) -> DisplayLine`.
The constructor treats the full input string as one display line and is not
aware of `\n`, `\r\n`, or `\r`. `split_lines(text, cjk?)` remains the API for
multiline text and reuses `DisplayLine::new` for each hard-line segment it
emits.

### Target files and surfaces

- `display_line.mbt`: make the single-line constructor public and route
  `split_lines` through it.
- `displayline_test.mbt`: cover that `DisplayLine::new` does not split hard
  newlines.
- `README.mbt.md`: document when to use `DisplayLine::new` versus
  `split_lines`.
- `pkg.generated.mbti`: generated interface should expose `DisplayLine::new`.
- openseek `displayline-api-trial`: replace known-single-line
  `split_lines(...)[0]` call sites with `DisplayLine::new`, including prompt
  prefix values.

### API/interface diff

Expected addition:

- `pub fn DisplayLine::new(String, cjk? : Bool) -> DisplayLine`

No existing public API should be removed in this pass.

### Open questions

None. A future borrowed constructor can be considered separately if
`DisplayLine` stops owning its backing text.

### Next implementation step

Add the constructor in `displayline`, then migrate openseek single-line call
sites and prefix-returning APIs to use `DisplayLine` directly.

### Validation plan

- In displayline, run `moon fmt`, `moon check`, `moon test`, `moon info`, and
  `git diff --check`.
- In openseek trial worktree, run `moon fmt`, `moon check`,
  `moon test --target native tui/internal/text tui/internal/composer tui/internal/render tui`,
  `moon info`, and `git diff --check`.
