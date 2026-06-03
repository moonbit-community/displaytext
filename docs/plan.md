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
