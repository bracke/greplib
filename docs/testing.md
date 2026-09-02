# Testing

The child crate `tests` contains an AUnit-based runner with deterministic tests for fixed-string spans, generated
fixed-string combinations, inverted/count/quiet modes, regex adapter whole-subject behavior, byte and stream record
semantics, generated stream block-size matrices, generated resource-boundary matrices, binary policies, collected
result limits, file search, directory traversal, path filters, generated concurrent directory matrices, callback stop
behavior, generated path-filter models, and diagnostic retention.

The suite includes both an internal fake filesystem adapter test and a test-side fake filesystem reference traversal
model. The internal fake adapter drives production directory traversal and file search through deterministic
classification, enumeration, hidden-entry filtering, entry-limit, fake file content, read-failure, kind-failure, and
child-enumeration-failure cases. The independent reference model covers lexicographic order, hidden filtering,
last-rule-wins filters, directory pruning,
same-filesystem boundaries, and object-identity symlink cycle detection. Real temporary-directory tests cover the
production host filesystem adapter and integration with `Greplib.Directories`.

Commands:

```sh
cd tests
alr build
./bin/greplib_tests
```

The runner supports the V1 mode and selection surface:

```sh
./bin/greplib_tests --mode=fast
./bin/greplib_tests --mode=full --suite=stream
./bin/greplib_tests --mode=stress --repeat=3 --test=directory
./bin/greplib_tests --mode=release --list-tests
```

Supported options are `--mode=fast|full|stress|release`, `--suite=<substring>`, `--test=<substring>`,
`--seed=<integer>`, `--repeat=<count>`, `--keep-temporary-files`, and `--list-tests`. The current generated tests are
deterministic; `--seed` is accepted so seed-reporting workflows have a stable command surface when randomized stress
cases are added.

The Ada release tool runs the same suite during `greplib_tool release-check` and also compiles all examples, verifies
metadata and documentation requirements, enforces style checks, writes the source manifest, creates the tar archive
through `tarlib`, and reads the tar archive back.
