# API Overview

Public packages include `Greplib`, `Greplib.Byte_Strings`, `Greplib.Paths`, `Greplib.Patterns`, `Greplib.Options`,
`Greplib.Diagnostics`, `Greplib.Results`, `Greplib.Events`, `Greplib.Cancellation`, `Greplib.Search`, `Greplib.Files`,
`Greplib.Directories`, `Greplib.Path_Filters`, `Greplib.Sources`, and `Greplib.Collected`.

This implementation provides a buildable core API. Stream search is incremental for the default text-search path,
prefix binary probing, NUL-separated records, and full-source NUL binary policies. Raw record delivery with non-default
full-source binary policies uses bounded delayed event delivery until classification is known. Concurrent directory
traversal uses a live traversal producer task, bounded source queue, bounded in-flight source slots, worker tasks, and
caller-task event delivery.

The common memory/byte search path enforces binary policies, maximum record size, before/after context, selected-record
limits, and structured diagnostics for invalid options and oversized records.

Search option validation runs before source events or input consumption. Collected-result limit validation also runs
before search. Independently detectable option errors are retained together where practical.
`Greplib.Search.Validate`, `Greplib.Files.Validate`, `Greplib.Directories.Validate`, and
`Greplib.Collected.Validate` expose preflight validation for their respective layers without consuming input or
delivering callbacks.

Directory search supports an optional compiled path-filter set for file inclusion and directory pruning. Collected
results are available for strings, byte arrays, borrowed streams, files, and directory/path roots; every collected
operation delegates to the same streaming event engine used by callback-based search.
Collected results retain exact `Greplib.Collected.Collection_Truncation` flags when record, byte, or total event
collection limits prevent retaining every delivered event.
When a collection limit is reached, the global outcome and retained source summary report `Result_Limit_Reached`.

Public event sinks return `Continue_Search`, `Stop_Current_Source`, or `Stop_All_Search`. `Greplib.Events.No_Op_Sink`
is provided for callers that want to discard events explicitly. `Greplib.Search`, `Greplib.Files`, and
`Greplib.Directories` also provide callback-free overloads that return only structured outcomes. Current single-source
search honors both stop actions at the callback boundary, suppresses later callbacks for that source, and records the
callback completion reason in the returned outcome.

Quiet mode stops after the first selected record and records `Quiet_Match_Found`; the summary still records that the
source had a result. Source-name modes emit a source result rather than record content.

All public events expose an owned source descriptor through `Greplib.Events.Source`. The descriptor reports
`Greplib.Sources.Kind`, `Greplib.Sources.Sequence`, and the preserved reporting path through `Greplib.Sources.Path`.
`Greplib.Events.Source_Path` and `Greplib.Events.Source_No` remain convenience accessors for the descriptor path and
sequence. Standalone string and byte-array searches report `Memory_Source`, borrowed stream searches report
`Stream_Source`, and file or directory searches report `File_Source`. Standalone string, byte-array, stream, and file
searches default to sequence one; the lower-level source-aware overloads accept an explicit sequence for callers that
coordinate multiple sources. Directory search assigns sequences in accepted traversal order, and concurrent search
preserves those sequence numbers even when completion-order delivery is selected.

Selected and context record events expose source path, source sequence, group number, record number, original byte
offset, logical and original content sizes, separator size and presence, CR-stripping status, content, and span data.

`Greplib.Results.Source_Summaries` returns retained immutable per-source summaries. Each source summary exposes the
owned source descriptor, records read, bytes read, selected-record count, match count and completeness, context and
emitted-result counts where known, binary classification, source truncation facts for diagnostics, match spans, and
context, `Source_Changed_During_Search`, diagnostic count, and completion reason. Directory outcomes copy source
summaries from the same per-source search outcomes that are aggregated into the global summary.
Traversal summaries include `Filesystem_Boundaries_Skipped` separately from general skipped-directory counts.
