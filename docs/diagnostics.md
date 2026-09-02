# Diagnostics

Diagnostics use stable identifier strings such as `configuration.no_patterns`, `configuration.empty_root_list`,
`pattern.invalid_regular_expression`, `path_filter.invalid_pattern`, `stream.read_failed`,
`filesystem.open_failed`, `traversal.filesystem_boundary_skipped`, `resource.path_limit_exceeded`,
`resource.directory_entry_limit_exceeded`, and `resource.context_buffer_exceeded`. Debug images are English diagnostic
aids and are not stable API.

`Diagnostic_Code` is private. Applications should use `Identifier` and `Domain`; code representation fields are not
public API. `Diagnostic` values are constructed by greplib and inspected through accessors such as `Code`, `Level`,
`Message`, and `Debug_Image`.

Diagnostics may also carry structured optional fields. V1 exposes presence/value accessors for path spelling,
filesystem operation, record number, native error code, exception identity/message text, numeric limit, and observed
size. A value is meaningful only when its matching `Has_*` accessor returns true.

The outcome summary counts every diagnostic observed by the operation. Retained diagnostics are bounded by
`Search_Options.Maximum_Retained_Diagnostics`; when the limit is reached, later diagnostics are still counted and
`Diagnostics_Truncated` is set on the outcome. A zero retention limit keeps no diagnostic objects while preserving the
total count and truncation flag.

Diagnostic events use the same structured diagnostic values as retained outcomes. Expected stream, file, traversal,
resource-limit, and pattern/filter compilation failures are reported structurally rather than as ordinary public
exceptions.

Diagnostics may include path or pattern data supplied by callers.
