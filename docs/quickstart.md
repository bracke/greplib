# Quickstart

Build with `alr build`. Compile tests in `tests` with `alr build`, then run `./bin/greplib_tests`.

The most direct API is `Greplib.Collected.Search_String`, which compiles fixed or regex patterns once and retains
emitted events in a bounded result object.

When only counts or summaries are needed, use the callback-free overloads in `Greplib.Search`, `Greplib.Files`, or
`Greplib.Directories`; they install `Greplib.Events.No_Op_Sink` internally and return the same structured outcome.
