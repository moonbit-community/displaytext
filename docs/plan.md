# DisplayText extraction checkpoint

## Goal

Create `moonbit-community/displaytext` as the TUI-facing home for the
grapheme-aware single-line display API extracted from
`moonbit-community/unicodewidth`.

The new module should let TUI authors work with display-cell columns and safe
textual boundaries without depending directly on Unicode grapheme and width
rules.

## Accepted design

`displaytext` owns the `DisplayText` API and depends on:

- `moonbit-community/unicodewidth` for terminal display-cell width rules.
- `kawaz/grapheme` for legal textual boundaries.

`unicodewidth` remains the lower-level width primitive module. It will not
re-export `displaytext`, because that would reverse the dependency direction and
create a cycle.

## Target files and surfaces

- `moon.mod`: new module metadata for `moonbit-community/displaytext`.
- `moon.pkg`: root package imports for `unicodewidth` and `grapheme`.
- `display_text.mbt`: implementation of `DisplayText`, `DisplayUnit`,
  `TextualPosition`, and `DisplayPosition`.
- `displaytext_test.mbt`: black-box tests for units, position mapping, viewing,
  and truncation.
- `README.mbt.md` and `README.md`: documented usage examples.
- `pkg.generated.mbti`: generated public interface from `moon info`.

## API/interface diff

Public API in this module:

- `pub fn display_text(StringView, cjk? : Bool) -> DisplayText`
- opaque `DisplayText`
- opaque `DisplayUnit`
- opaque `TextualPosition`
- opaque `DisplayPosition`
- `DisplayText::width(Self) -> Int`
- `DisplayText::units(Self) -> Array[DisplayUnit]`
- `DisplayText::start(Self) -> TextualPosition`
- `DisplayText::end(Self) -> TextualPosition`
- `DisplayText::next(Self, TextualPosition) -> TextualPosition?`
- `DisplayText::prev(Self, TextualPosition) -> TextualPosition?`
- `DisplayText::display_position(Self, TextualPosition) -> DisplayPosition`
- `DisplayText::textual_position_at_or_before(Self, DisplayPosition) -> TextualPosition`
- `DisplayText::textual_position_at_or_after(Self, DisplayPosition) -> TextualPosition`
- `DisplayText::view(Self, TextualPosition, TextualPosition) -> StringView`
- `DisplayText::truncate(Self, Int, suffix? : StringView) -> String`
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
`DisplayText::units` returning an array copy versus a custom iterator.

## Next implementation step

Move the existing `DisplayText` implementation and tests from `unicodewidth`,
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

Move single-line soft wrapping into `displaytext` so TUI callers can wrap a
`DisplayText` without traversing low-level display units.

### Accepted design

Expose `DisplayText::wrap(width : Int) -> Array[DisplayRange]`.
`DisplayRange` represents a half-open textual range on the original
`DisplayText`, along with that range's display-cell width.

`width <= 0` is normalized to 1. The returned array always contains at least one
range. Empty lines return one empty range. A display unit wider than the wrap
width is placed in its own range so wrapping never emits an empty range or cuts a
display unit.

### Target files and surfaces

- `display_text.mbt`: add `DisplayRange` and `DisplayText::wrap`.
- `displaytext_test.mbt`: cover wrapping ASCII/CJK, emoji, zero-width units,
  oversized units, empty lines, and invalid widths.
- `README.mbt.md`: document soft wrapping.
- `pkg.generated.mbti`: generated interface update from `moon info`.

### API/interface diff

Expected additions:

- opaque `DisplayRange`
- `DisplayText::wrap(Self, Int) -> Array[DisplayRange]`
- `DisplayRange::start(Self) -> TextualPosition`
- `DisplayRange::end(Self) -> TextualPosition`
- `DisplayRange::width(Self) -> Int`
- `DisplayRange::view(Self, DisplayText) -> StringView`

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

Narrow `displaytext` to Unicode-aware hard-line splitting and display-position
primitives. Soft wrapping belongs to consumers such as openseek because they own
viewport, style, and row policy.

### Accepted design

Expose `split_lines(text : StringView, cjk? : Bool) -> Array[DisplayText]` as
the only public constructor for `DisplayText`.

`split_lines` accepts arbitrary plain text and splits on hard line breaks:
`\n`, `\r\n`, and `\r`. Line-ending text is not included in returned
`DisplayText` values. Empty lines are preserved, including the trailing empty
line after a final line break.

Remove public `display_text`, `DisplayText::wrap`, `DisplayText::units`, and
`DisplayRange`. Keep `DisplayText::width`, cursor movement,
display/textual-position conversion, zero-copy `view`, and `truncate`.

Consumers that need soft wrap maintain their own used display columns and use
`textual_position_at_or_before` plus `view` to cut legal prefixes.

### Target files and surfaces

- `display_text.mbt`: add `split_lines`, private single-line construction, and
  remove public `units`/`wrap`.
- `display_range.mbt`: remove the obsolete `DisplayRange` type.
- `displaytext_test.mbt`: rewrite tests to use `split_lines` and public
  position/view APIs.
- `README.mbt.md`: document `split_lines` and primitive-only scope.
- `pkg.generated.mbti`: generated public API should remove `display_text`,
  `DisplayText::wrap`, `DisplayText::units`, `DisplayRange`, and all
  `DisplayUnit` accessors.
- openseek `displaytext-api-trial`: replace `display_text` construction with
  `split_lines`, move soft wrap to composer, and remove direct use of
  `DisplayText::units`.

### API/interface diff

Expected public API:

- `pub fn split_lines(StringView, cjk? : Bool) -> Array[DisplayText]`
- opaque `DisplayText`
- opaque `TextualPosition`
- opaque `DisplayPosition`
- `DisplayText::width(Self) -> Int`
- `DisplayText::start(Self) -> TextualPosition`
- `DisplayText::end(Self) -> TextualPosition`
- `DisplayText::next(Self, TextualPosition) -> TextualPosition?`
- `DisplayText::prev(Self, TextualPosition) -> TextualPosition?`
- `DisplayText::display_position(Self, TextualPosition) -> DisplayPosition`
- `DisplayText::textual_position_at_or_before(Self, DisplayPosition) -> TextualPosition`
- `DisplayText::textual_position_at_or_after(Self, DisplayPosition) -> TextualPosition`
- `DisplayText::view(Self, TextualPosition, TextualPosition) -> StringView`
- `DisplayText::truncate(Self, Int, suffix? : StringView) -> String`
- `DisplayPosition::new(column~ : Int) -> DisplayPosition`
- `DisplayPosition::column(Self) -> Int`

### Open questions

None for this pass. `tui/doc` rich styled wrapping may still need follow-up
after the plain composer migration is validated.

### Next implementation step

Update `displaytext`, run its tests, then migrate openseek against the new API.

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

Expose `DisplayText::new(text : String, cjk? : Bool = false) -> DisplayText`.
The constructor treats the full input string as one display line and is not
aware of `\n`, `\r\n`, or `\r`. `split_lines(text, cjk?)` remains the API for
multiline text and reuses `DisplayText::new` for each hard-line segment it
emits.

### Target files and surfaces

- `display_text.mbt`: make the single-line constructor public and route
  `split_lines` through it.
- `displaytext_test.mbt`: cover that `DisplayText::new` does not split hard
  newlines.
- `README.mbt.md`: document when to use `DisplayText::new` versus
  `split_lines`.
- `pkg.generated.mbti`: generated interface should expose `DisplayText::new`.
- openseek `displaytext-api-trial`: replace known-single-line
  `split_lines(...)[0]` call sites with `DisplayText::new`, including prompt
  prefix values.

### API/interface diff

Expected addition:

- `pub fn DisplayText::new(String, cjk? : Bool) -> DisplayText`

No existing public API should be removed in this pass.

### Open questions

None. A future borrowed constructor can be considered separately if
`DisplayText` stops owning its backing text.

### Next implementation step

Add the constructor in `displaytext`, then migrate openseek single-line call
sites and prefix-returning APIs to use `DisplayText` directly.

### Validation plan

- In displaytext, run `moon fmt`, `moon check`, `moon test`, `moon info`, and
  `git diff --check`.
- In openseek trial worktree, run `moon fmt`, `moon check`,
  `moon test --target native tui/internal/text tui/internal/composer tui/internal/render tui`,
  `moon info`, and `git diff --check`.

## Checkpoint: rename package to displaytext

### Goal

Rename the public module/package identity from `displayline` to `displaytext`
and rename `DisplayLine` to `DisplayText`, matching the current scope: terminal
display-cell text boundaries, not line layout.

### Accepted Design

The module becomes `moonbit-community/displaytext`. The public type becomes
`DisplayText`.

`DisplayText::new(text : String, cjk? : Bool = false)` remains a single text-run
constructor and is not hard-newline aware. `split_lines(text, cjk?)` remains the
API that splits multiline input into `Array[DisplayText]`.

No compatibility aliases are kept in this pass because openseek is migrated in
lockstep and the package has not been published under the new narrowed API.

### Target Files And Surfaces

- `moon.mod`: module name, repository, description.
- source/test/docs filenames and text: `display_line` / `displayline` /
  `DisplayLine` to `display_text` / `displaytext` / `DisplayText`.
- `pkg.generated.mbti`: generated public package name and type signatures.
- openseek trial worktree: dependency/import/type references updated to
  `moonbit-community/displaytext` / `@displaytext` / `DisplayText`.

### API/Interface Diff

- package: `moonbit-community/displayline` -> `moonbit-community/displaytext`
- type: `DisplayLine` -> `DisplayText`
- `split_lines(StringView, cjk? : Bool) -> Array[DisplayText]`
- `DisplayText::new(String, cjk? : Bool) -> DisplayText`

### Open Questions

The repository directory may remain `displayline` locally for now; module name
is the import identity. A repository rename can happen separately.

### Next Implementation Step

Rename the displaytext module and source symbols, then migrate openseek imports.

### Validation Plan

- In displaytext, run `moon fmt`, `moon check`, `moon test`, `moon info`, and
  `git diff --check`.
- In openseek trial worktree, run `moon fmt`, `moon check`,
  `moon test --target native tui/doc tui/internal/text tui/internal/composer tui/internal/render tui`,
  `moon info`, `rg` for old names, and `git diff --check`.
