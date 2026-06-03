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
