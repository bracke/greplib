pragma Ada_2022;

with Ada.Text_IO;
with Greplib.Collected;
with Greplib.Options;
with Greplib.Patterns;

procedure Collect_Matches is
   Patterns : Greplib.Patterns.Pattern_List;
   Set : Greplib.Patterns.Compiled_Pattern_Set;
   Result : Greplib.Collected.Collected_Result;
   Options : Greplib.Options.Search_Options;
begin
   Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("aba"));
   Set := Greplib.Patterns.Compile (Patterns);
   Options.Spans := Greplib.Options.All_Spans;
   Greplib.Collected.Search_String ("ababa", Set, Options, (others => <>), Result);
   Ada.Text_IO.Put_Line ("events:" & Result.Events.Length'Image);
end Collect_Matches;
