# Matching Semantics

Fixed strings use byte-for-byte matching with optional ASCII-only case folding. Fixed-string spans are half-open byte
ranges relative to logical record content. Duplicate patterns retain declaration order.

Pattern compilation is explicit and atomic. If any pattern fails, the compiled set is unusable and exposes no partial
compiled subset through `Count`; diagnostics refer to the original declaration index where applicable.
`Greplib.Patterns.Validate` exposes the same pattern and compilation-option checks without returning a compiled matcher
set. Invalid regular expressions report `pattern.invalid_regular_expression`; invalid compilation limits report
`configuration.invalid_option_combination`; an empty list reports `configuration.no_patterns`.

Regex syntax and behavior are those of the local `regexp` crate. Its one-based inclusive match ranges are converted to
greplib half-open zero-based byte spans.

Span controls:

- `No_Spans` selects records without retaining span lists;
- `First_Span` retains only the first accepted non-overlapping span, marks spans incomplete when more existed, and
  makes summary match counts lower bounds;
- `All_Spans` retains accepted non-overlapping spans until `Maximum_Match_Spans_Per_Record`;
- when the span limit is exceeded, greplib emits `resource.match_span_limit_exceeded`,
  truncates retained spans, and marks match counts as lower bounds.

Whole-word mode uses ASCII word bytes only: `A-Z`, `a-z`, `0-9`, and underscore. Zero-length candidates, including an
empty fixed-string pattern, do not satisfy whole-word matching.

An empty fixed string selects every record. When spans are requested outside whole-word mode, it emits zero-length spans
at each byte position from record start through record end.

When a regex candidate is rejected by whole-word validation, greplib resumes searching after the rejected candidate's
start byte, not after its end byte. This preserves later overlapping candidates that can satisfy the boundary rule.

`Maximum_Selected_Records` caps emitted and summarized selected records. When the cap excludes later selected records,
the outcome reason is `Match_Limit_Reached`; configured trailing context for the final accepted selected record is still
emitted in `Emit_Selected_Records` mode.

Binary policies currently implemented for memory and byte-array search:

- `Search_As_Text`: continue normal record search;
- `Skip_Source`: complete the source without record events;
- `Fail_Source`: return a fatal binary diagnostic;
- `Report_Match_Without_Record`: emit a structural `Binary_Match` if a selected record exists and suppress raw record
  content. This policy is valid only with `Emit_Selected_Records`.
