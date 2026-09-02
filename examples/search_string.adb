pragma Ada_2022;

with Ada.Text_IO;
with Greplib.Collected;
with Greplib.Options;
with Greplib.Patterns;
with Greplib.Results;

procedure Search_String is
   Patterns : Greplib.Patterns.Pattern_List;
   Set : Greplib.Patterns.Compiled_Pattern_Set;
   Result : Greplib.Collected.Collected_Result;
   Options : Greplib.Options.Search_Options;
begin
   Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("needle"));
   Set := Greplib.Patterns.Compile (Patterns);
   Greplib.Collected.Search_String
     ("needle" & ASCII.LF & "hay", Set, Options, (others => <>), Result);
   Ada.Text_IO.Put_Line
     ("selected records:" & Greplib.Results.Selected_Record_Count
        (Greplib.Results.Summary (Result.Outcome))'Image);
end Search_String;
