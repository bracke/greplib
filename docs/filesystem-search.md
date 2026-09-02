# Filesystem Search

`Greplib.Files.Search_File` opens byte streams with `Ada.Streams.Stream_IO` and closes handles on completion paths.
`Greplib.Directories.Search_Paths` supports file roots, directory roots, recursive traversal, hidden filtering, and
lexicographic deterministic ordering.
Production traversal accesses the host filesystem through `Greplib.Internal.Filesystem`, an internal adapter around
`Ada.Directories`, `GNAT.OS_Lib`, and platform identity helpers. This keeps filesystem classification, child
enumeration, symlink detection, and normalized identity handling isolated from traversal policy code.
The same internal adapter has a resettable fake mode used by the test crate for deterministic traversal and
fault-injection coverage. It can classify fake files, directories, special files, and symlinks; enumerate fake child
entries; hide dot-prefixed children when hidden entries are disabled; provide normalized identities; and raise
controlled classification, enumeration, and stream-read failures. Fake ordinary files can also carry deterministic
byte content; `Greplib.Files.Search_File` routes those fake paths through the same incremental stream engine used for
host files. The fake adapter is internal-only and is not part of the public library API.

Directory search has explicit file-type policy fields. `Search_Regular_Files` defaults to `True`.
`Search_Special_Files` defaults to `False`; enabling it is an explicit opt-in because special files can block or have
side effects. Skipped file types are counted in `Files_Filtered` and are not opened.

`Search_Paths` also has an overload accepting `Greplib.Path_Filters.Compiled_Filter_Set`. Filters are evaluated before
searching files and before descending into non-root directories. An excluded directory is pruned; later descendant
include rules do not revive it.

Filter compilation is explicit. Exact-name and glob filters are compiled into owned rules, and regular-expression
filters are compiled once through the same internal regexp adapter used by search patterns. Malformed globs and invalid
filter regular expressions produce `path_filter.invalid_pattern`, leaving the compiled filter set unusable with no
partial compiled rules exposed. Relative-path subjects are normalized to slash separators before filtering; exact
relative-path filter patterns are normalized the same way.
`Greplib.Path_Filters.Validate` exposes the same filter-rule validation without starting traversal or evaluating
filesystem entries.

Missing roots and directory enumeration failures are reported as recoverable filesystem diagnostics. Per-file outcomes
are merged into the directory outcome, including retained diagnostics, counts, and recoverable-error status.
Directory outcomes also populate traversal counters in `Search_Summary`: `Roots_Considered`,
`Directories_Visited`, `Directories_Skipped`, `Entries_Examined`, `Files_Accepted`, `Files_Filtered`,
`Links_Encountered`, `Links_Followed`, `Cycles_Detected`, and `Filesystem_Boundaries_Skipped`.
Every searched file consumes a source sequence in accepted traversal order. File-open failures also consume their
sequence, so later source numbers remain stable. Concurrent directory search uses the same assigned sequence numbers for
all source lifecycle, record, diagnostic, count, name, binary-match, and completion events.
`Greplib.Files.Validate` exposes file-search configuration validation without opening the path, delivering callbacks, or
observing cancellation. `Greplib.Files.Search_File` runs that validation automatically before filesystem I/O.
`Greplib.Files.Search_File` also records `Sources_Changed_During_Search = 1` when supported file size or modification
time metadata differs between the start and end of a successfully opened file search. The corresponding retained
per-source summary reports `Source_Changed_During_Search = True`. Metadata failures do not convert an otherwise
successful search into an error.

Directory search validates empty root lists, pattern usability, search options, worker count, queued-source limits, and
in-flight source limits before traversal. It enforces configured path byte, depth, and directory entry limits during
traversal. A child directory deeper than `Maximum_Depth` is skipped with `traversal.maximum_depth_exceeded`.
`Greplib.Directories.Validate` exposes the same pre-traversal configuration validation without opening files,
enumerating directories, spawning worker tasks, or invoking callbacks.
The overload accepting `Greplib.Path_Filters.Compiled_Filter_Set` also includes retained diagnostics from an unusable
compiled filter set.
An explicit root directory is still enumerated when `Maximum_Depth` is zero; direct children are depth one.
Duplicate roots are processed independently in caller order.

Cancellation is checked before each root and while collecting directory entries. A callback or external token can stop
later roots or later directory entries, though an active filesystem call can still delay observation.

`Traversal_Errors = Continue_After_Error` keeps traversal diagnostics recoverable and continues where practical.
`Fail_Root` stops the current root after a traversal diagnostic and continues with later roots. `Fail_Search` makes
traversal diagnostics fatal and stops the directory operation.

`Stay_On_Starting_Filesystem` uses an internal `stat` binding when platform identity is available. Each directory root
gets its own starting filesystem identity, and recursive traversal skips child directories whose device differs from
that root. A skipped boundary emits `traversal.filesystem_boundary_skipped` and increments both
`Directories_Skipped` and `Filesystem_Boundaries_Skipped`.
If starting identity cannot be read for a root, that root reports `filesystem.open_failed` according to the traversal
error policy.

Quiet mode stops directory traversal after the first searched source confirms a selected record. The directory outcome
uses `Quiet_Match_Found` and records the matching source in `Sources_With_Results`.

Supported glob behavior:

- `*` matches zero or more non-separator bytes;
- `?` matches exactly one non-separator byte;
- `**` may cross separators;
- backslash escapes the next glob byte;
- a glob ending with an unpaired backslash fails filter compilation;
- rules are evaluated in declaration order and the last matching rule wins.

Symlink handling uses `GNAT.OS_Lib.Is_Symbolic_Link`. `Never_Follow` skips symlink roots and traversal symlinks.
`Follow_Explicit_Roots` follows only symlink roots. `Follow_All` follows traversal symlinks too. Cycle checks use
device/inode identity when the internal platform binding can read it, otherwise they fall back to
`GNAT.OS_Lib.Normalize_Pathname` with link resolution. Greplib does not claim snapshot consistency.
