pragma Ada_2022;

with Greplib.Byte_Strings;
with Greplib.Diagnostics;
with Greplib.Events.Building;
with Greplib.Internal.Execution_Plans;
with Greplib.Paths;
with Greplib.Result_Authority;
with Greplib.Results.Editing;
with Greplib.Sources;
with Greplib.Sources.Building;
with Ada.Containers.Indefinite_Vectors;

package body Greplib.Search is
   package EB renames Greplib.Events.Building;
   package EP renames Greplib.Internal.Execution_Plans;
   package RE renames Greplib.Results.Editing;
   Edit_Key : constant Greplib.Result_Authority.Token := Greplib.Result_Authority.Internal;
   use type Greplib.Events.Event_Action;
   use type Greplib.Internal.Execution_Plans.Plan_Kind;
   use type Greplib.Diagnostics.Severity;
   use type Greplib.Results.Overall_Status;

   type Record_Info is record
      Number : Record_Number := 1;
      Offset : Byte_Offset := 0;
      Logical_Size : Byte_Count := 0;
      Original_Size : Byte_Count := 0;
      Separator_Size : Byte_Count := 0;
      Separator_Present : Boolean := False;
      CR_Stripped : Boolean := False;
      Text : Greplib.Byte_Strings.Byte_String;
      Positive : Boolean := False;
      Selected : Boolean := False;
      Spans : Greplib.Events.Span_List;
      Complete : Boolean := True;
      Emit : Boolean := False;
      Emit_Selected : Boolean := False;
      Group : Wide_Count := 0;
   end record;

   package Record_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Record_Info);

   function Validate
     (Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options) return Greplib.Diagnostics.Diagnostic_List
   is
      Result : Greplib.Diagnostics.Diagnostic_List := Greplib.Options.Validate (Options);
   begin
      if not Greplib.Patterns.Is_Usable (Patterns) then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
               Greplib.Diagnostics.Fatal_Error,
               "compiled pattern set is unusable"));
      end if;

      return Result;
   end Validate;

   procedure Emit
     (Sink : in out Greplib.Events.Event_Sink'Class;
      Event : Greplib.Events.Search_Event;
      Stop_Current : in out Boolean;
      Stop_All : in out Boolean) is
      Action : Greplib.Events.Event_Action;
   begin
      if Stop_Current or else Stop_All then
         return;
      end if;
      Sink.On_Event (Event, Action);
      case Action is
         when Greplib.Events.Continue_Search =>
            null;
         when Greplib.Events.Stop_Current_Source =>
            Stop_Current := True;
         when Greplib.Events.Stop_All_Search =>
            Stop_All := True;
      end case;
   end Emit;

   procedure Search_String_With_Source
     (Subject : String;
      Source_Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.Memory_Source)
   is
      use Greplib.Events;
      use Greplib.Options;
      Diags : Greplib.Diagnostics.Diagnostic_List := Validate (Patterns, Options);
      Sep : constant Character := Greplib.Options.Separator (Options);
      Path : constant Greplib.Paths.Path := Source_Path;
      Start : Positive := Subject'First;
      Offset : Byte_Offset := 0;
      Number : Record_Number := 1;
      Stop_Current : Boolean := False;
      Stop_All : Boolean := False;
      Selected_Count : Wide_Count := 0;
      Total_Selected_Count : Wide_Count := 0;
      Delivered_Selected_Count : Wide_Count := 0;
      Delivered_Context_Count : Wide_Count := 0;
      Delivered_Result_Count : Wide_Count := 0;
      Match_Count : Wide_Count := 0;
      Had_Selected : Boolean := False;
      Binary_Report_Active : Boolean := False;
      Plan : EP.Search_Plan;
      Source_Binary_Detected : Boolean := False;
      Match_Spans_Truncated : Boolean := False;
      Fatal_Source_Error : Boolean := False;
      Early_Stop : Boolean := False;
      Emitted_Source_Result : Boolean := False;
      Records : Record_Vectors.Vector;

      procedure Append_Source_Summary is
      begin
         RE.Append_Source_Summary
           (Edit_Key,
            Outcome,
            Greplib.Sources.Building.Make (Edit_Key, Source_Kind, Sequence, Path),
            Context_Record_Count => Delivered_Context_Count,
            Emitted_Result_Count => Delivered_Result_Count,
            Binary =>
              (if Options.Binary_Detection = No_Binary_Detection
               then Greplib.Results.Not_Classified
               elsif Source_Binary_Detected
               then Greplib.Results.Binary
               else Greplib.Results.Text_Like),
            Match_Spans_Truncated => Match_Spans_Truncated);
      end Append_Source_Summary;

      procedure Retain_Diagnostic (Item : Greplib.Diagnostics.Diagnostic) is
      begin
         RE.Add_Wide (Edit_Key, Outcome, RE.Diagnostic_Count_Field);
         if Options.Maximum_Retained_Diagnostics = 0 then
            RE.Set_Diagnostics_Truncated (Edit_Key, Outcome, True);
         elsif RE.Retained_Diagnostic_Count (Outcome) < Options.Maximum_Retained_Diagnostics then
            RE.Append_Diagnostic (Edit_Key, Outcome, Item);
         else
            RE.Set_Diagnostics_Truncated (Edit_Key, Outcome, True);
         end if;

         if Greplib.Diagnostics.Level (Item) = Greplib.Diagnostics.Fatal_Error then
            RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Failed);
            RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Source_Error);
         elsif RE.Status (Outcome) = Greplib.Results.Completed then
            RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Completed_With_Recoverable_Errors);
            RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Source_Error);
         end if;
      end Retain_Diagnostic;

      procedure Apply_Configuration_Failure (Items : Greplib.Diagnostics.Diagnostic_List) is
      begin
         RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Failed);
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Fatal_Error);
         RE.Set_Wide (Edit_Key, Outcome, RE.Diagnostic_Count_Field, Wide_Count (Items.Length));
         for I in 1 .. Natural (Items.Length) loop
            declare
               D : constant Greplib.Diagnostics.Diagnostic := Items.Element (I);
            begin
               if Options.Maximum_Retained_Diagnostics = 0 then
                  RE.Set_Diagnostics_Truncated (Edit_Key, Outcome, True);
               elsif RE.Retained_Diagnostic_Count (Outcome) < Options.Maximum_Retained_Diagnostics then
                  RE.Append_Diagnostic (Edit_Key, Outcome, D);
               else
                  RE.Set_Diagnostics_Truncated (Edit_Key, Outcome, True);
               end if;
            end;
         end loop;
      end Apply_Configuration_Failure;

      procedure Apply_Cancelled_Before_Input is
      begin
         RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
         RE.Set_Cancellation_Observed (Edit_Key, Outcome, True);
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Cancellation_Requested);
      end Apply_Cancelled_Before_Input;

      function Binary_Detected return Boolean is
         Limit : Natural := Subject'Length;
      begin
         if Options.Binary_Detection = No_Binary_Detection
           or else Options.Separator_Kind = NUL
         then
            return False;
         end if;

         if Options.Binary_Detection = Detect_Using_Prefix then
            Limit := Natural'Min (Subject'Length, 4096);
         end if;

         for I in Subject'First .. Subject'First + Limit - 1 loop
            if Subject (I) = Character'Val (0) then
               return True;
            end if;
         end loop;
         return False;
      end Binary_Detected;

      procedure Add_Record (Raw : String; Separator_Size : Byte_Count) is
         Stripped : constant Boolean :=
           Options.CR_Policy = Strip_Before_Line_Feed
           and then Raw'Length > 0
           and then Raw (Raw'Last) = ASCII.CR;
         Logical : constant String :=
           (if Stripped then Raw (Raw'First .. Raw'Last - 1) else Raw);
         Positive : Boolean;
         Spans : Span_List;
         Complete : Boolean;
         Selected : Boolean;

         procedure Apply_Span_Controls is
         begin
            if EP.Kind (Plan) = EP.Emit_Records_Plan
              and then Options.Spans = First_Span
              and then Natural (Spans.Length) > 1
            then
               while Natural (Spans.Length) > 1 loop
                  Spans.Delete_Last;
               end loop;
               Complete := False;
               Match_Spans_Truncated := True;
               RE.Set_Match_Count_State (Edit_Key, Outcome, Greplib.Results.Lower_Bound);
            elsif Wide_Count (Spans.Length) > Options.Maximum_Match_Spans_Per_Record then
               declare
                  D : constant Greplib.Diagnostics.Diagnostic :=
                    Greplib.Diagnostics.Make
                      (Greplib.Diagnostics.Resource_Match_Span_Limit_Exceeded,
                       Greplib.Diagnostics.Recoverable_Error,
                       "match span limit exceeded",
                       Offset => Offset,
                       Path => Greplib.Paths.Image (Path),
                       Has_Record => True,
                       Record_No => Number,
                       Has_Numeric_Limit => True,
                       Numeric_Limit => Options.Maximum_Match_Spans_Per_Record,
                       Has_Observed_Size => True,
                       Observed_Size => Wide_Count (Spans.Length));
               begin
                  while Wide_Count (Spans.Length) > Options.Maximum_Match_Spans_Per_Record loop
                     Spans.Delete_Last;
                  end loop;
                  Complete := False;
                  Match_Spans_Truncated := True;
                  RE.Set_Match_Count_State (Edit_Key, Outcome, Greplib.Results.Lower_Bound);
                  Retain_Diagnostic (D);
                  Emit (Sink, EB.Make_Diagnostic (Edit_Key, Path, D, Sequence, Source_Kind), Stop_Current, Stop_All);
               end;
            end if;
         end Apply_Span_Controls;
      begin
         if Byte_Count (Raw'Length) > Options.Maximum_Record_Size then
            if Options.On_Oversized_Record /= Skip_Record then
               declare
                  D : constant Greplib.Diagnostics.Diagnostic :=
                    Greplib.Diagnostics.Make
                      (Greplib.Diagnostics.Input_Record_Size_Limit_Exceeded,
                       (if Options.On_Oversized_Record = Fail_Source
                        then Greplib.Diagnostics.Fatal_Error
                       else Greplib.Diagnostics.Recoverable_Error),
                       "record size limit exceeded",
                       Offset => Offset,
                       Path => Greplib.Paths.Image (Path),
                       Has_Record => True,
                       Record_No => Number,
                       Has_Numeric_Limit => True,
                       Numeric_Limit => Options.Maximum_Record_Size,
                       Has_Observed_Size => True,
                       Observed_Size => Wide_Count (Raw'Length));
               begin
                  Retain_Diagnostic (D);
                  Emit (Sink, EB.Make_Diagnostic (Edit_Key, Path, D, Sequence, Source_Kind), Stop_Current, Stop_All);
               end;
            end if;

            if EP.Kind (Plan) = EP.Count_Matches_Plan then
               RE.Set_Match_Count_State (Edit_Key, Outcome, Greplib.Results.Lower_Bound);
            end if;

            RE.Add_Wide (Edit_Key, Outcome, RE.Records_Read_Field);
            RE.Add_Bytes_Read (Edit_Key, Outcome, Byte_Count (Raw'Length) + Separator_Size);
            Number := Number + 1;
            Offset := Offset + Byte_Count (Raw'Length) + Separator_Size;

            if Options.On_Oversized_Record = Fail_Source then
                  Fatal_Source_Error := True;
                  RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Failed);
                  RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Source_Error);
            end if;
            return;
         end if;

         Greplib.Patterns.Match_Record
           (Patterns, Logical, EP.Needs_Spans (Plan),
            Positive, Spans, Complete);
         Apply_Span_Controls;
         Selected := (if Options.Invert_Match then not Positive else Positive);

         Records.Append
           (Record_Info'
              (Number => Number,
               Offset => Offset,
               Logical_Size => Byte_Count (Logical'Length),
               Original_Size => Byte_Count (Raw'Length),
               Separator_Size => Separator_Size,
               Separator_Present => Separator_Size /= 0,
               CR_Stripped => Stripped,
               Text => Greplib.Byte_Strings.To_Byte_String (Logical),
               Positive => Positive,
               Selected => Selected,
               Spans => Spans,
               Complete => Complete,
               Emit => False,
               Emit_Selected => False,
               Group => 0));

         RE.Add_Wide (Edit_Key, Outcome, RE.Records_Read_Field);
         RE.Add_Bytes_Read (Edit_Key, Outcome, Byte_Count (Raw'Length) + Separator_Size);
         if Positive then
            Match_Count := Match_Count + Wide_Count (Spans.Length);
         end if;
         Number := Number + 1;
         Offset := Offset + Byte_Count (Raw'Length) + Separator_Size;

         if Selected and then EP.Stops_After_First_Selected (Plan) then
            Early_Stop := True;
         end if;
      end Add_Record;

      procedure Mark_Context is
         Remaining_Selected : Wide_Count := Options.Maximum_Selected_Records;
      begin
         if EP.Kind (Plan) /= EP.Emit_Records_Plan or else Records.Is_Empty then
            return;
         end if;

         for I in Records.First_Index .. Records.Last_Index loop
            declare
               R : Record_Info := Records.Element (I);
            begin
               if R.Selected and then (Options.Maximum_Selected_Records = 0 or else Remaining_Selected > 0) then
                  if Options.Maximum_Selected_Records /= 0 then
                     Remaining_Selected := Remaining_Selected - 1;
                  end if;

                  declare
                     First : constant Positive :=
                       Positive'Max
                         (Records.First_Index,
                          I - Integer'Min (I - Records.First_Index, Integer (Options.Context.Before)));
                     Last : constant Positive :=
                       Positive'Min
                         (Records.Last_Index,
                          I + Integer'Min (Records.Last_Index - I, Integer (Options.Context.After)));
                  begin
                     for J in First .. Last loop
                        declare
                           T : Record_Info := Records.Element (J);
                        begin
                           T.Emit := True;
                           Records.Replace_Element (J, T);
                        end;
                     end loop;

                     declare
                        T : Record_Info := Records.Element (I);
                     begin
                        T.Emit := True;
                        T.Emit_Selected := True;
                        Records.Replace_Element (I, T);
                     end;
                  end;
               end if;
            end;
         end loop;

         declare
            Current_Group : Wide_Count := 0;
            Previous_Emitted : Natural := 0;
         begin
            for I in Records.First_Index .. Records.Last_Index loop
               declare
                  R : Record_Info := Records.Element (I);
               begin
                  if R.Emit then
                     if Current_Group = 0 or else Previous_Emitted + 1 /= I then
                        Current_Group := Current_Group + 1;
                     end if;
                     R.Group :=
                       (if Options.Context.Before = 0 and then Options.Context.After = 0
                        then 0
                        else Current_Group);
                     Previous_Emitted := I;
                     Records.Replace_Element (I, R);
                  end if;
               end;
            end loop;
         end;
      end Mark_Context;
   begin
      RE.Reset (Edit_Key, Outcome);
      RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Considered_Field, 1);

      if not Diags.Is_Empty then
         Apply_Configuration_Failure (Diags);
         return;
      end if;

      if Greplib.Cancellation.Is_Requested (Cancellation) then
         Apply_Cancelled_Before_Input;
         return;
      end if;

      Plan := EP.Compile (Options);
      Emit (Sink, EB.Make_Source_Started (Edit_Key, Path, Sequence, Source_Kind), Stop_Current, Stop_All);

      Source_Binary_Detected := Binary_Detected;

      if not Stop_Current and then not Stop_All and then Source_Binary_Detected then
         case Options.On_Binary is
            when Search_As_Text =>
               null;
            when Report_Match_Without_Record =>
               Binary_Report_Active := True;
               Plan := EP.Compile (Options, Binary_Report_Active => True);
            when Skip_Source =>
               Emit (Sink, EB.Make_Source_Completed (Edit_Key, Path, Sequence, Source_Kind), Stop_Current, Stop_All);
               RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Opened_Field, 1);
               RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Completed_Field, 1);
               Append_Source_Summary;
               return;
            when Fail_Source =>
               declare
                  D : constant Greplib.Diagnostics.Diagnostic :=
                    Greplib.Diagnostics.Make
                      (Greplib.Diagnostics.Input_Binary_Detected,
                       Greplib.Diagnostics.Fatal_Error,
                       "binary input detected");
               begin
                  RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Failed);
                  RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Source_Error);
                  Retain_Diagnostic (D);
                  Emit (Sink, EB.Make_Diagnostic (Edit_Key, Path, D, Sequence, Source_Kind), Stop_Current, Stop_All);
                  Emit (Sink, EB.Make_Source_Completed (Edit_Key, Path, Sequence, Source_Kind), Stop_Current, Stop_All);
                  RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Opened_Field, 1);
                  RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Completed_Field, 1);
                  Append_Source_Summary;
                  return;
               end;
         end case;
      end if;

      if not Stop_Current and then not Stop_All and then Subject'Length /= 0 then
         for I in Subject'Range loop
            if Subject (I) = Sep then
               Add_Record (Subject (Start .. I - 1), 1);
               Start := I + 1;
               exit when Stop_Current
                 or else Stop_All
                 or else Fatal_Source_Error
                 or else Early_Stop
                 or else Greplib.Cancellation.Is_Requested (Cancellation);
            end if;
         end loop;

         if not Stop_Current
           and then not Stop_All
           and then not Fatal_Source_Error
           and then not Early_Stop
           and then not Greplib.Cancellation.Is_Requested (Cancellation)
           and then Start <= Subject'Last
         then
            Add_Record (Subject (Start .. Subject'Last), 0);
         end if;
      end if;

      for R of Records loop
         if R.Selected then
            Had_Selected := True;
            Total_Selected_Count := Total_Selected_Count + 1;
         end if;
      end loop;

      Selected_Count := Total_Selected_Count;
      if Options.Maximum_Selected_Records /= 0 then
         Selected_Count := Wide_Count'Min (Selected_Count, Options.Maximum_Selected_Records);
      end if;

      if EP.Kind (Plan) = EP.Binary_Match_Plan and then Had_Selected then
         Emitted_Source_Result := True;
         Delivered_Result_Count := Delivered_Result_Count + 1;
         Emit (Sink, EB.Make_Binary_Match (Edit_Key, Path, Sequence, Source_Kind), Stop_Current, Stop_All);
      elsif EP.Kind (Plan) = EP.Quiet_Plan and then Had_Selected then
         Emitted_Source_Result := True;
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Quiet_Match_Found);
      elsif EP.Kind (Plan) = EP.Names_With_Matches_Plan and then Had_Selected then
         Emitted_Source_Result := True;
         Delivered_Result_Count := Delivered_Result_Count + 1;
         Emit (Sink, EB.Make_Source_Name (Edit_Key, Path, True, Sequence, Source_Kind), Stop_Current, Stop_All);
      elsif EP.Kind (Plan) = EP.Emit_Records_Plan then
         Mark_Context;
         for R of Records loop
            if R.Emit then
               if R.Emit_Selected then
                  Delivered_Selected_Count := Delivered_Selected_Count + 1;
               else
                  Delivered_Context_Count := Delivered_Context_Count + 1;
               end if;
               Delivered_Result_Count := Delivered_Result_Count + 1;
               Emit
                 (Sink,
                  EB.Make_Record (Edit_Key, (if R.Emit_Selected then Selected_Record else Context_Record),
                     Path, R.Group, R.Number, R.Offset,
                     R.Logical_Size, R.Original_Size, R.Separator_Size,
                     R.Separator_Present, R.CR_Stripped,
                     R.Text, R.Spans, R.Complete, Sequence, Source_Kind),
                  Stop_Current,
                  Stop_All);
               exit when Stop_Current or else Stop_All;
            end if;
         end loop;
      end if;

      if Stop_Current or else Stop_All then
         null;
      elsif EP.Kind (Plan) = EP.Binary_Match_Plan then
         null;
      elsif EP.Kind (Plan) = EP.Count_Selected_Plan then
         Delivered_Result_Count := Delivered_Result_Count + 1;
         Emit (Sink, EB.Make_Count (Edit_Key, Path, Selected_Count, Sequence, Source_Kind), Stop_Current, Stop_All);
      elsif EP.Kind (Plan) = EP.Count_Matches_Plan then
         Delivered_Result_Count := Delivered_Result_Count + 1;
         Emit (Sink, EB.Make_Count (Edit_Key, Path, Match_Count, Sequence, Source_Kind), Stop_Current, Stop_All);
      elsif EP.Kind (Plan) = EP.Names_Without_Matches_Plan and then not Had_Selected then
         Emitted_Source_Result := True;
         Delivered_Result_Count := Delivered_Result_Count + 1;
         Emit (Sink, EB.Make_Source_Name (Edit_Key, Path, False, Sequence, Source_Kind), Stop_Current, Stop_All);
      end if;

      if not Stop_Current and then not Stop_All then
         Emit (Sink, EB.Make_Source_Completed (Edit_Key, Path, Sequence, Source_Kind), Stop_Current, Stop_All);
      end if;
      RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Opened_Field, 1);
      RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Completed_Field, (if Stop_Current or else Stop_All then 0 else 1));
      RE.Set_Wide
        (Edit_Key, Outcome, RE.Selected_Record_Count_Field,
         (if (Stop_Current or else Stop_All) and then EP.Kind (Plan) = EP.Emit_Records_Plan
          then Delivered_Selected_Count
          else Selected_Count));
      RE.Set_Wide (Edit_Key, Outcome, RE.Match_Count_Field, Match_Count);
      RE.Set_Wide
        (Edit_Key, Outcome, RE.Sources_With_Results_Field,
         (if Had_Selected or else Emitted_Source_Result then 1 else 0));
      if Stop_All then
         RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Callback_Stopped_Search);
         if EP.Kind (Plan) = EP.Count_Matches_Plan then
            RE.Set_Match_Count_State (Edit_Key, Outcome, Greplib.Results.Lower_Bound);
         end if;
      elsif Stop_Current then
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Callback_Stopped_Source);
         if EP.Kind (Plan) = EP.Count_Matches_Plan then
            RE.Set_Match_Count_State (Edit_Key, Outcome, Greplib.Results.Lower_Bound);
         end if;
      elsif Greplib.Cancellation.Is_Requested (Cancellation) then
         RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
         RE.Set_Cancellation_Observed (Edit_Key, Outcome, True);
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Cancellation_Requested);
         if EP.Kind (Plan) = EP.Count_Matches_Plan then
            RE.Set_Match_Count_State (Edit_Key, Outcome, Greplib.Results.Lower_Bound);
         end if;
      elsif Options.Maximum_Selected_Records /= 0
        and then Total_Selected_Count > Options.Maximum_Selected_Records
      then
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Match_Limit_Reached);
      end if;

      Append_Source_Summary;
   end Search_String_With_Source;

   procedure Search_String
     (Subject : String;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation) is
   begin
      Search_String_With_Source
        (Subject, Greplib.Paths.To_Path ("<memory>"), Patterns, Options, Sink, Outcome, Cancellation);
   end Search_String;

   procedure Search_String
     (Subject : String;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation)
   is
      Sink : Greplib.Events.No_Op_Sink;
   begin
      Search_String (Subject, Patterns, Options, Sink, Outcome, Cancellation);
   end Search_String;

   procedure Search_Bytes
     (Subject : Ada.Streams.Stream_Element_Array;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation)
   is
   begin
      Search_String_With_Source
        (Greplib.Byte_Strings.To_String (Greplib.Byte_Strings.To_Byte_String (Subject)),
         Greplib.Paths.To_Path ("<bytes>"), Patterns, Options, Sink, Outcome, Cancellation);
   end Search_Bytes;

   procedure Search_Bytes
     (Subject : Ada.Streams.Stream_Element_Array;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation)
   is
      Sink : Greplib.Events.No_Op_Sink;
   begin
      Search_Bytes (Subject, Patterns, Options, Sink, Outcome, Cancellation);
   end Search_Bytes;
end Greplib.Search;
