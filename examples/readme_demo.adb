pragma Ada_2022;

with Ada.Text_IO;
with Greplib;
with Greplib.Collected;
with Greplib.Diagnostics;
with Greplib.Options;
with Greplib.Patterns;
with Greplib.Results;

procedure Readme_Demo is
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
end Readme_Demo;
