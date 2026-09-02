# Regexp Compatibility

Reconnaissance date: 2026-08-01.

The workspace contains a local crate at `../regexp`, with crate name `regexp`, root package `Regexp`, and project file
`regexp.gpr`. Greplib pins that crate locally.

Observed API:

- package: `Regexp`;
- compile: `Compile (Pattern : String; ...) return Compile_Result`;
- compile status: `Compile_Ok`, `Empty_Pattern`, syntax errors, unsupported syntax, and limit errors;
- invalid-pattern reporting: failed compiles are converted to unusable greplib pattern sets with structured
  diagnostics; no regexp exception or status type appears in the public API;
- match result: `Match_Result` with `Status`, one-based inclusive `First`/`Last`, and `Steps_Used`;
- no-match representation: `Status = No_Match`;
- arbitrary start-offset support: `Find_From`;
- first-match support: `Find_First`;
- all non-overlapping matches: `Find_All` and `Find_All_From`;
- full-match support: `Matches_Entire`;
- case-insensitive support: `Match_Options.Case_Sensitive`; greplib sets this explicitly;
- zero-length matches: represented with `Last < First`;
- subject type: `String`;
- empty pattern behavior: regexp reports a non-OK compile status, and greplib exposes it as a failed compile;
- empty subject behavior: patterns that can match the empty string, such as `a*`, can full-match an empty subject;
- embedded NUL behavior: subjects are Ada `String` values and embedded NUL bytes are preserved by the adapter;
- compiled expression copy behavior: copied compiled expressions continue to match through the adapter;
- task behavior: the conformance suite shares one copied compiled expression across two Ada tasks for read-only
  matching;
- cancellation hook: `Match_Options.Abort_Callback`.

Greplib converts regexp ranges to half-open zero-based byte spans:

- `First_Byte = Found.First - 1`;
- non-empty `Last_Byte_Exclusive = Found.Last`;
- zero-length `Last_Byte_Exclusive = First_Byte`.

All production regex calls go through `Greplib.Internal.Regexp_Adapter`. The adapter is also exported from the library
interface for the child test crate, but it remains an internal package and is not part of the stable public API.

The AUnit conformance tests exercise the adapter through the public search APIs for normal spans,
case-insensitive matching, whole-record matching, embedded NUL subjects when binary detection is disabled,
and zero-length progress. A direct internal adapter conformance test also verifies invalid and empty pattern compile
failure, no-match representation, arbitrary start offsets, case-insensitive match options, full-match behavior,
empty-subject full matches, embedded NUL subjects, compiled-expression copying, and read-only matching from Ada tasks.
