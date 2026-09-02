# AI Implementation Guide

Package map:

- public values: `Greplib`, `Greplib.Byte_Strings`, `Greplib.Paths`;
- matching: `Greplib.Patterns`, `Greplib.Internal.Regexp_Adapter`;
- execution: `Greplib.Search`, `Greplib.Files`, `Greplib.Directories`, `Greplib.Internal.Execution_Plans`;
- output: `Greplib.Events`, `Greplib.Collected`, `Greplib.Results`, `Greplib.Diagnostics`;
- filters and sources: `Greplib.Path_Filters`, `Greplib.Sources`;
- cancellation: `Greplib.Cancellation`.
- filesystem identity: `Greplib.Internal.Filesystem_Identity` is internal-only and may be used by traversal for
  object identity, cycle detection, and same-filesystem checks.
- filesystem adapter: `Greplib.Internal.Filesystem` is internal-only and owns host filesystem classification,
  symlink detection, normalized identity fallback, child enumeration, fake file content, read-failure injection, and the
  resettable fake/fault-injection table used by tests.
- execution plans: `Greplib.Internal.Execution_Plans` is internal-only and centralizes result-mode decisions such as
  span discovery, context need, content retention, complete-input requirements, and early-stop eligibility.

Directory filters:

- evaluate rules in declaration order;
- last matching rule wins;
- default is include;
- excluded directories are pruned before descent.
- glob `*` and `?` must not cross `/`; only `**` may cross separators.
- `Stay_On_Starting_Filesystem` must compare child directory identity against the root filesystem identity when
  identity is available, and boundary skips use `traversal.filesystem_boundary_skipped`.
- Directory event source sequences are assigned in accepted traversal order and remain stable across live concurrent
  source queues.
- Per-source result summaries are appended through `Greplib.Results.Editing.Append_Source_Summary` after a source
  reaches its terminal state, and directory aggregation preserves those summaries in source-sequence order.
- Synthetic worker failure outcomes must also append descriptor-backed source summaries using the assigned file path
  and source sequence before the source outcome is merged.

Rules:

- do not add another regex engine;
- do not invoke external grep;
- keep all regex calls behind `Greplib.Internal.Regexp_Adapter`;
- do not add shell, Python, Node, Makefile, Perl, or Ruby automation;
- do not call user callbacks from worker tasks;
- do not use task abort for cancellation;
- do not silently ignore invalid options;
- do not implement unbounded collection.

Build commands are listed in `README.md` and `docs/releasing.md`.

Before changing traversal behavior, run the internal fake filesystem traversal test, the fake filesystem reference
traversal test, and the real directory integration tests through the AUnit runner. Before release, run
`tools/bin/greplib_tool release-check`.
