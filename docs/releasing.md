# Releasing

Release verification is orchestrated by the Ada tooling crate through `project_tools`:

```sh
cd tools && alr build && cd ..
tools/bin/greplib_tool release-check
```

The `release-check` command runs the clean-tree check, root build, test build, AUnit runner, examples build, tooling
build, metadata checks, documentation checks, style checks, package generation, source-manifest validation, and tar
readback validation. `greplib_tool check-clean-tree` requires a clean `git status --porcelain` result when usable Git
metadata is available; it reports an explicit skip when the source tree is not a Git checkout.

`greplib_tool package` writes `dist/source-manifest.txt`, a deterministic relative-path manifest for the packageable
source set, and `dist/greplib-0.1.0-dev.tar`, a deterministic uncompressed ustar archive rooted at `greplib/`.
`release-check` regenerates and validates both artifacts while rejecting build artifacts and prohibited automation files
from the packageable source set. Manifest validation checks the header, entry count, exact deterministic order, and
every source path against the Ada-computed packageable source list before the tar readback validation runs.
Use `greplib_tool check-package` to validate existing `dist` artifacts without running the full build and test release
workflow.

The current tooling intentionally writes an uncompressed tar archive. Compressed release archives can be added later
through the Ada tooling without changing the package source manifest.
