# Resource Limits

Canonical defaults are declared in `Greplib`: record size, context buffer bytes, pattern counts, retained diagnostics,
collected records, collected bytes, collected events, traversal depth, path bytes, directory entries, worker counts,
source queues, and event queue byte limits.

Default values:

- `Default_Read_Block_Size`: 64 KiB;
- `Default_Initial_Record_Buffer`: 4 KiB;
- `Default_Maximum_Record_Size`: 16 MiB;
- `Default_Maximum_Context_Buffer_Bytes`: 8 MiB;
- `Default_Maximum_Pattern_Count`: 1024;
- `Default_Maximum_Total_Pattern_Bytes`: 16 MiB;
- `Default_Maximum_Match_Spans_Per_Record`: 100000;
- `Default_Maximum_Retained_Diagnostics`: 1000;
- `Default_Maximum_Collected_Records`: 10000;
- `Default_Maximum_Collected_Bytes`: 64 MiB;
- `Default_Maximum_Traversal_Depth`: 1024;
- `Default_Maximum_Path_Bytes`: 1 MiB;
- `Default_Maximum_Directory_Entries`: 1000000;
- `Default_Maximum_Worker_Count`: 256;
- `Default_Maximum_In_Flight_Sources`: 64;
- `Default_Maximum_Queued_Events_Per_Source`: 128;
- `Default_Maximum_Queued_Event_Bytes_Per_Source`: 32 MiB.

This implementation enforces pattern count/bytes, regexp compile and match limits, option validation, binary policy
validation, read block size validation, maximum record size, delayed context/event buffering, collection
records/bytes/events, directory worker-count and source-queue validation, path byte limits, directory entry limits, and
traversal depth diagnostics.

Pattern compilation rejects zero `Maximum_Pattern_Count` and zero `Maximum_Total_Pattern_Bytes` as invalid compile
options. These diagnostics are reported independently from an empty pattern-list diagnostic where both are detectable.

`Search_Options.Maximum_Context_Buffer_Bytes` rejects zero during validation. It bounds before-context retention and the
stream delayed-event buffer used while full-source binary classification is pending before raw record delivery.
Exceeding the stream delayed-event bound fails the source with `resource.context_buffer_exceeded`. Exceeding the
before-context byte bound reports `resource.context_buffer_exceeded` once and drops oldest before-context records,
retaining records closest to a later selected record where possible.

`Maximum_Match_Spans_Per_Record` is enforced after candidate arbitration. Truncated span lists remain ordered and
non-overlapping, but completeness is false. A span-limit diagnostic makes the outcome recoverable and makes
`Count_Matches` a lower-bound count.

`First_Span` also marks record spans incomplete when additional accepted spans existed and marks the summary match count
as a lower bound.

When an oversized record is reported and skipped, the outcome is completed with recoverable errors. If match counting is
requested, skipped oversized content also makes the match count a lower bound.

Collected results require positive `Maximum_Records`, `Maximum_Bytes`, and `Maximum_Events`. `Maximum_Records` counts
selected records, context records, and binary-match results. `Maximum_Events` bounds all retained events, including
source lifecycle and diagnostics. `Maximum_Bytes` accounts for an event overhead estimate, source path bytes, retained
record content, span storage, and diagnostic message bytes. When any collection limit is reached, `Collected_Result`
sets `Truncated`, records exact `Collection_Truncation` flags for `Records`, `Bytes`, and `Events`, and the outcome
reason is `Result_Limit_Reached`. `Stop_And_Return_Partial` stops the underlying search intentionally;
`Continue_Without_Collecting` keeps searching while dropping later events. The retained source summary reason is also
rewritten to `Result_Limit_Reached` when a collection limit is the decisive result condition.
`Greplib.Collected.Validate` exposes collection-limit validation without starting a search, consuming input, invoking
callbacks, or observing cancellation. It reports independently invalid zero record, byte, and event limits.
Collected validation overloads also compose the underlying `Greplib.Search`, `Greplib.Files`, and `Greplib.Directories`
preflight checks, including unusable compiled path filters for filtered directory collection.

Directory traversal enforces `Maximum_Path_Bytes` before filesystem classification and
`Maximum_Directory_Entries` while collecting entries. Over-limit paths or directories produce recoverable diagnostics
and are skipped.

Directory `Maximum_Sources` defaults to zero, meaning unlimited. A positive value stops traversal after that many
accepted file sources have been searched or queued and returns `Source_Limit_Reached` as the completion reason.
When directory concurrency is enabled, `Maximum_Queued_Sources` bounds the live worker source queue and
`Maximum_In_Flight_Sources` bounds accepted source slots whose event streams have not yet been delivered.

Directory validation rejects zero queued/in-flight limits and rejects worker counts that exceed either in-flight source
capacity or queued-source capacity. `Maximum_Depth` treats explicit roots as depth zero; root directories are still
enumerated at zero, while deeper directories are limited according to their child depth.
`Stay_On_Starting_Filesystem = True` skips recursive child directories that cross away from each root's filesystem
identity, reports `traversal.filesystem_boundary_skipped`, and increments `Filesystem_Boundaries_Skipped`.

Diagnostic retention is also bounded. `Maximum_Retained_Diagnostics` controls how many diagnostic objects are retained
in the final outcome, while summary diagnostic counts continue to include diagnostics beyond the retention limit. The
same retention rule is applied to memory, byte-array, stream, file, and directory outcomes.
Per-source summaries expose source-level truncation facts through `Source_Truncation`, including diagnostic retention
truncation, match-span truncation, and context-buffer truncation.
