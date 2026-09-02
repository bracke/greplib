pragma Ada_2022;

with Ada.Text_IO;
with Greplib.Collected;
with Greplib.Options;
with Greplib.Patterns;
with Greplib.Results;

procedure Count_Records is
   Patterns : Greplib.Patterns.Pattern_List;
   Set : Greplib.Patterns.Compiled_Pattern_Set;
   Result : Greplib.Collected.Collected_Result;
   Options : Greplib.Options.Search_Options;
begin
   Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("a"));
   Set := Greplib.Patterns.Compile (Patterns);
   Options.Mode := Greplib.Options.Count_Selected_Records;
   Greplib.Collected.Search_String
     ("a" & ASCII.LF & "b" & ASCII.LF & "aa", Set, Options, (others => <>), Result);
   Ada.Text_IO.Put_Line
     ("count:" & Greplib.Results.Selected_Record_Count
        (Greplib.Results.Summary (Result.Outcome))'Image);
end Count_Records;
