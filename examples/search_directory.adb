pragma Ada_2022;

with Ada.Text_IO;
with Greplib.Directories;
with Greplib.Events;
with Greplib.Options;
with Greplib.Paths;
with Greplib.Patterns;
with Greplib.Results;

procedure Search_Directory is
   type Null_Sink is new Greplib.Events.Event_Sink with null record;
   overriding procedure On_Event
     (Sink : in out Null_Sink;
      Event : Greplib.Events.Search_Event;
      Action : out Greplib.Events.Event_Action) is
   begin
      Action := Greplib.Events.Continue_Search;
   end On_Event;

   Roots : Greplib.Paths.Path_List;
   Patterns : Greplib.Patterns.Pattern_List;
   Set : Greplib.Patterns.Compiled_Pattern_Set;
   Sink : Null_Sink;
   Outcome : Greplib.Results.Search_Outcome;
begin
   Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("."));
   Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("greplib"));
   Set := Greplib.Patterns.Compile (Patterns);
   Greplib.Directories.Search_Paths
     (Roots, Set, (others => <>), (Recursive => False, others => <>), Sink, Outcome);
   Ada.Text_IO.Put_Line
     ("sources:" & Greplib.Results.Sources_Considered (Greplib.Results.Summary (Outcome))'Image);
end Search_Directory;
