pragma Ada_2022;

with Ada.Text_IO;
with Greplib.Path_Filters;

procedure Custom_Path_Filters is
   Rules : Greplib.Path_Filters.Filter_List;
   Set : Greplib.Path_Filters.Compiled_Filter_Set;
begin
   Greplib.Path_Filters.Append
     (Rules,
      Greplib.Path_Filters.Rule
        (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
         Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Glob_Pattern, "*.tmp"));
   Set := Greplib.Path_Filters.Compile (Rules);
   Ada.Text_IO.Put_Line
     ("keep:" &
      Boolean'Image (Greplib.Path_Filters.Included (Set, "main.adb", "src/main.adb", False)));
end Custom_Path_Filters;
