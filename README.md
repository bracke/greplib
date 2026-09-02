# greplib

`greplib` is an Ada 2022 library crate for reusable grep-like searching. It is a library, not a command-line grep
program: it exposes pattern compilation, search operations, structured events, collected results, summaries, and
diagnostics for callers to format however they choose.

Implemented in this repository:

- fixed-string pattern compilation and matching;
- regular-expression compilation and span matching through the local `regexp` crate;
- string and byte-array search;
- stream and file entry points;
- basic deterministic directory traversal;
- owned byte strings and paths;
- structured diagnostics and outcomes;
- collected results implemented as an event sink;
- compileable examples and an AUnit-based test runner.

Known limitations are documented in `docs/regexp-compatibility.md` and `docs/api-overview.md`. This workspace uses the
local crate at `../regexp`, pinned in `alire.toml`.

## Build

```sh
alr build
cd tests && alr build && ./bin/greplib_tests
alr exec -- gprbuild -p -P examples/examples.gpr
cd tools && alr build && cd ..
tools/bin/greplib_tool package
tools/bin/greplib_tool release-check
```

## Minimal Example

```ada
with Ada.Text_IO;
with Greplib;
with Greplib.Collected;
with Greplib.Diagnostics;
with Greplib.Options;
with Greplib.Patterns;
with Greplib.Results;

procedure Demo is
   use type Greplib.Results.Overall_Status;

   Patterns : Greplib.Patterns.Pattern_List;
   Set : Greplib.Patterns.Compiled_Pattern_Set;
   Result : Greplib.Collected.Collected_Result;
begin
   Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("needle"));
   Set := Greplib.Patterns.Compile (Patterns);

   if not Greplib.Patterns.Is_Usable (Set) then
      declare
         Diagnostics : constant Greplib.Diagnostics.Diagnostic_List := Greplib.Patterns.Diagnostics (Set);
      begin
         for I in 1 .. Natural (Diagnostics.Length) loop
            Ada.Text_IO.Put_Line (Greplib.Diagnostics.Debug_Image (Diagnostics.Element (I)));
         end loop;
      end;
      return;
   end if;

   Greplib.Collected.Search_String ("needle" & ASCII.LF, Set, (others => <>), (others => <>), Result);

   if Greplib.Results.Status (Result.Outcome) /= Greplib.Results.Completed then
      declare
         Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
           Greplib.Results.Diagnostics (Result.Outcome);
      begin
         for I in 1 .. Natural (Diagnostics.Length) loop
            Ada.Text_IO.Put_Line (Greplib.Diagnostics.Debug_Image (Diagnostics.Element (I)));
         end loop;
      end;
      return;
   end if;

   Ada.Text_IO.Put_Line
     ("selected records:" & Greplib.Wide_Count'Image
        (Greplib.Results.Selected_Record_Count (Greplib.Results.Summary (Result.Outcome))));
end Demo;
```

## License

MIT.
