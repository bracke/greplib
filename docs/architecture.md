# Architecture

Pattern compilation owns all matcher state in `Greplib.Patterns`. Regex calls pass through
`Greplib.Internal.Regexp_Adapter`. `Greplib.Internal.Execution_Plans` derives immutable result-mode decisions from
validated search options, including whether spans, context, content retention, complete input consumption, or early
stop behavior are needed. String and byte-array operations use `Greplib.Search`; file and directory operations delegate
into that shared processor. `Greplib.Collected` is implemented as an `Event_Sink` over the streaming event API.
Directory traversal uses `Greplib.Internal.Filesystem` for host filesystem classification and enumeration, while
`Greplib.Internal.Filesystem_Identity` provides object and filesystem identity where the platform supports it.
`Greplib.Internal.Filesystem` also owns the internal fake/fault-injection table used by tests, so traversal and file
search policy can be exercised without depending on host directory ordering, permissions, or file contents.
