# Stream Semantics

The public stream API borrows the caller's stream and does not close it. Stream processing reads bounded chunks and
processes records incrementally for `No_Binary_Detection`, prefix binary probing, NUL-separated records, the default
`Search_As_Text` binary policy, and full-source NUL detection. The implementation does not treat short reads as EOF;
EOF is the Ada stream convention where `Last < Item'First`.

`Search_Options.Read_Block_Size` controls the maximum stream read buffer size. The default is
`Default_Read_Block_Size` (64 KiB). A zero read block size, or one that cannot be represented as an Ada stream element
offset, is rejected during option validation before the stream is read.
`Greplib.Files.Validate` exposes the same stream/file configuration validation without reading a stream, opening a file,
delivering callbacks, or observing cancellation.

The incremental stream path keeps only the current record accumulator, stops quiet and source-name-with-matches modes
early, supports count modes, strips CR before LF when configured, resynchronizes after skipped oversized records,
maintains before/after context with deterministic group numbering, and preserves record numbers and byte offsets across
read-block boundaries.

Full-source NUL detection with non-default binary policies delays raw record events until classification is known. If a
NUL byte is found, delayed raw records are discarded and `Skip_Source`, `Fail_Source`, or
`Report_Match_Without_Record` is applied without exposing record content. If EOF is reached without a NUL byte, delayed
events are flushed in order. The delayed event buffer is bounded by `Search_Options.Maximum_Context_Buffer_Bytes`; if
that limit is exceeded, the source fails with `resource.context_buffer_exceeded`.

For memory and byte-array search, binary detection supports NUL-byte detection and prefix probing. NUL-separated search
does not classify NUL separators as binary. Memory search reports the source path `<memory>`; byte-array search reports
`<bytes>`.

Record events report byte offsets in original source bytes. `Logical_Content_Size` reflects content after optional CR
stripping, while `Original_Content_Size`, `Separator_Size`, `Separator_Present`, and `Carriage_Return_Stripped` preserve
the original record framing facts.

For incremental stream search, summary `Bytes_Read` reports bytes successfully read from the borrowed stream. This can
include bytes in an unfinished record when a read failure, cancellation, or binary skip stops the source before that
record is emitted or counted.

Oversized record handling is enforced by `Maximum_Record_Size` and `On_Oversized_Record`:

- `Fail_Source`: emit a fatal diagnostic and stop the source;
- `Skip_Record`: count and skip the record without matching it;
- `Report_And_Skip`: emit a recoverable diagnostic, count the record, skip matching it, and continue.
