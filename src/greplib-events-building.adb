pragma Ada_2022;

with Greplib.Sources.Building;

package body Greplib.Events.Building is
   function Make_Source_Started
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event is
   begin
      return
        (K => Source_Started,
         Source => Greplib.Sources.Building.Make (Authority, Source_Kind, Sequence, Path),
         others => <>);
   end Make_Source_Started;

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
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event is
   begin
      return
        (K => K,
         Source => Greplib.Sources.Building.Make (Authority, Source_Kind, Sequence, Path),
         Group => Group,
         Number => Number,
         Offset => Offset,
         Logical_Size => Logical_Size,
         Original_Size => Original_Size,
         Separator_Bytes => Separator_Size,
         Has_Separator => Separator_Present,
         CR_Stripped => Carriage_Return_Stripped,
         Text => Text,
         Match_Spans => Match_Spans,
         Complete => Complete,
         others => <>);
   end Make_Record;

   function Make_Diagnostic
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Item : Greplib.Diagnostics.Diagnostic;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event is
   begin
      return
        (K => Diagnostic_Event,
         Source => Greplib.Sources.Building.Make (Authority, Source_Kind, Sequence, Path),
         Diag => Item,
         others => <>);
   end Make_Diagnostic;

   function Make_Count
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Value : Wide_Count;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event is
   begin
      return
        (K => Count_Result,
         Source => Greplib.Sources.Building.Make (Authority, Source_Kind, Sequence, Path),
         Value => Value,
         others => <>);
   end Make_Count;

   function Make_Binary_Match
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event is
   begin
      return
        (K => Binary_Match,
         Source => Greplib.Sources.Building.Make (Authority, Source_Kind, Sequence, Path),
         Match => True,
         others => <>);
   end Make_Binary_Match;

   function Make_Source_Name
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Match : Boolean;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event is
   begin
      return
        (K => Source_Name_Result,
         Source => Greplib.Sources.Building.Make (Authority, Source_Kind, Sequence, Path),
         Match => Match,
         others => <>);
   end Make_Source_Name;

   function Make_Source_Completed
     (Authority : Greplib.Result_Authority.Token;
      Path : Greplib.Paths.Path;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.File_Source) return Search_Event is
   begin
      return
        (K => Source_Completed,
         Source => Greplib.Sources.Building.Make (Authority, Source_Kind, Sequence, Path),
         others => <>);
   end Make_Source_Completed;
end Greplib.Events.Building;
