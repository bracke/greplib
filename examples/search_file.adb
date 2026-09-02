pragma Ada_2022;

with Ada.Text_IO;
with Greplib.Events;
with Greplib.Files;
with Greplib.Options;
with Greplib.Paths;
with Greplib.Patterns;
with Greplib.Results;

procedure Search_File is
   type Null_Sink is new Greplib.Events.Event_Sink with null record;
   overriding procedure On_Event
     (Sink : in out Null_Sink;
      Event : Greplib.Events.Search_Event;
      Action : out Greplib.Events.Event_Action);
   overriding procedure On_Event
     (Sink : in out Null_Sink;
      Event : Greplib.Events.Search_Event;
      Action : out Greplib.Events.Event_Action) is
   begin
      Action := Greplib.Events.Continue_Search;
   end On_Event;

   Patterns : Greplib.Patterns.Pattern_List;
   Set : Greplib.Patterns.Compiled_Pattern_Set;
   Sink : Null_Sink;
   Outcome : Greplib.Results.Search_Outcome;
begin
   Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("needle"));
   Set := Greplib.Patterns.Compile (Patterns);
   Greplib.Files.Search_File
     (Greplib.Paths.To_Path ("README.md"), Set, (others => <>), Sink, Outcome);
   Ada.Text_IO.Put_Line ("status:" & Greplib.Results.Status (Outcome)'Image);
end Search_File;
