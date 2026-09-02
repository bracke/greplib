pragma Ada_2022;

with Greplib.Result_Authority;
with Greplib.Sources;

package Greplib.Events.Building is
   --  @summary Internal event construction API.
   --  Public callers can inspect Search_Event values through Greplib.Events accessors but cannot construct them.

   --  Construct a Source_Started event.
   function Make_Source_Started
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event;

   --  Construct a Selected_Record or Context_Record event with owned content and span data.
   function Make_Record
     (Authority : Greplib.Result_Authority.Token;
      K : Event_Kind;
      Path : Greplib.Paths.Path;
      Group : Wide_Count;
      Number : Record_Number;
      Offset : Byte_Offset;
      Logical_Size : Byte_Count;
      Original_Size : Byte_Count;
      Separator_Size : Byte_Count;
      Separator_Present : Boolean;
      Carriage_Return_Stripped : Boolean;
      Text : Greplib.Byte_Strings.Byte_String;
      Match_Spans : Span_List;
      Complete : Boolean;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event;

   --  Construct a Diagnostic_Event with owned structured diagnostic data.
   function Make_Diagnostic
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Item : Greplib.Diagnostics.Diagnostic;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event;

   --  Construct a Count_Result event.
   function Make_Count
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Value : Wide_Count;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event;

   --  Construct a Binary_Match event that exposes no raw record content.
   function Make_Binary_Match
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event;

   --  Construct a Source_Name_Result event for source-name result modes.
   function Make_Source_Name
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Match : Boolean;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event;

   --  Construct a Source_Completed event.
   function Make_Source_Completed
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event;
end Greplib.Events.Building;
