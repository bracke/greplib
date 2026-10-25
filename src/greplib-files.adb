pragma Ada_2022;

with Ada.Containers.Indefinite_Vectors;
with Ada.Calendar;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded;
with Greplib.Byte_Strings;
with Greplib.Diagnostics;
with Greplib.Events;
with Greplib.Events.Building;
with Greplib.Internal.Filesystem;
with Greplib.Options;
with Greplib.Patterns;
with Greplib.Result_Authority;
with Greplib.Results.Editing;
with Greplib.Search;
with Greplib.Sources;
with Greplib.Sources.Building;

package body Greplib.Files is
   package EB renames Greplib.Events.Building;
   package RE renames Greplib.Results.Editing;
   Edit_Key : constant Greplib.Result_Authority.Token := Greplib.Result_Authority.Internal;
   use type Ada.Streams.Stream_Element_Offset;
   use type Ada.Calendar.Time;
   use type Ada.Directories.File_Size;
   use type Greplib.Diagnostics.Severity;
   use type Greplib.Events.Event_Action;
   use type Greplib.Events.Event_Kind;
   use type Greplib.Options.Binary_Detection_Mode;
   use type Greplib.Options.Binary_Policy;
   use type Greplib.Options.Carriage_Return_Policy;
   use type Greplib.Options.Oversized_Record_Policy;
   use type Greplib.Options.Record_Separator_Kind;
   use type Greplib.Options.Result_Mode;
   use type Greplib.Options.Span_Requirement;
   use type Greplib.Results.Overall_Status;
   use type Greplib.Results.Completion_Reason;
   package U renames Ada.Strings.Unbounded;

   type Fake_File_Stream is new Ada.Streams.Root_Stream_Type with record
      Text : U.Unbounded_String;
      Next : Natural := 1;
      Bytes_Returned : Byte_Count := 0;
      Fail_After : Byte_Count := Byte_Count'Last;
   end record;

   overriding procedure Read
     (Stream : in out Fake_File_Stream;
      Item : out Ada.Streams.Stream_Element_Array;
      Last : out Ada.Streams.Stream_Element_Offset);

   overriding procedure Write
     (Stream : in out Fake_File_Stream;
      Item : Ada.Streams.Stream_Element_Array);

   overriding procedure Read
     (Stream : in out Fake_File_Stream;
      Item : out Ada.Streams.Stream_Element_Array;
      Last : out Ada.Streams.Stream_Element_Offset)
   is
      S : constant String := U.To_String (Stream.Text);
      Count : Natural := 0;
   begin
      if Stream.Bytes_Returned >= Stream.Fail_After then
         raise Constraint_Error;
      end if;

      if Stream.Next > S'Length then
         Last := Item'First - 1;
         return;
      end if;

      for I in Item'Range loop
         exit when Stream.Next > S'Length or else Stream.Bytes_Returned >= Stream.Fail_After;
         Item (I) := Ada.Streams.Stream_Element (Character'Pos (S (Stream.Next)));
         Stream.Next := Stream.Next + 1;
         Stream.Bytes_Returned := Stream.Bytes_Returned + 1;
         Count := Count + 1;
      end loop;

      if Count = 0 then
         raise Constraint_Error;
      end if;

      Last := Item'First + Ada.Streams.Stream_Element_Offset (Count - 1);
   end Read;

   overriding procedure Write
     (Stream : in out Fake_File_Stream;
      Item : Ada.Streams.Stream_Element_Array) is
      pragma Unreferenced (Stream, Item);
   begin
      raise Program_Error;
   end Write;

   function Actual_Read_Block_Size
     (Options : Greplib.Options.Search_Options) return Ada.Streams.Stream_Element_Offset is
   begin
      if Options.Read_Block_Size = 0
        or else Options.Read_Block_Size > Byte_Count (Ada.Streams.Stream_Element_Offset'Last)
      then
         return Ada.Streams.Stream_Element_Offset (Default_Read_Block_Size);
      else
         return Ada.Streams.Stream_Element_Offset (Options.Read_Block_Size);
      end if;
   end Actual_Read_Block_Size;

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

   procedure Set_Source_Failure
     (Outcome : out Greplib.Results.Search_Outcome;
      Diagnostic : Greplib.Diagnostics.Diagnostic;
      Options : Greplib.Options.Search_Options) is
   begin
      RE.Reset (Edit_Key, Outcome);
      RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Failed);
      RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Considered_Field, 1);
      RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Source_Error);
      RE.Set_Wide (Edit_Key, Outcome, RE.Diagnostic_Count_Field, 1);
      if Options.Maximum_Retained_Diagnostics = 0 then
         RE.Set_Diagnostics_Truncated (Edit_Key, Outcome, True);
      else
         RE.Append_Diagnostic (Edit_Key, Outcome, Diagnostic);
      end if;
   end Set_Source_Failure;

   procedure Set_Configuration_Failure
     (Outcome : out Greplib.Results.Search_Outcome;
      Diagnostics : Greplib.Diagnostics.Diagnostic_List;
      Options : Greplib.Options.Search_Options) is
   begin
      RE.Reset (Edit_Key, Outcome);
      RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Failed);
      RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Considered_Field, 1);
      RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Fatal_Error);
      RE.Set_Wide (Edit_Key, Outcome, RE.Diagnostic_Count_Field, Wide_Count (Diagnostics.Length));
      for I in 1 .. Natural (Diagnostics.Length) loop
         declare
            D : constant Greplib.Diagnostics.Diagnostic := Diagnostics.Element (I);
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
   end Set_Configuration_Failure;

   procedure Set_Cancelled_Before_Input (Outcome : out Greplib.Results.Search_Outcome) is
   begin
      RE.Reset (Edit_Key, Outcome);
      RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
      RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Considered_Field, 1);
      RE.Set_Cancellation_Observed (Edit_Key, Outcome, True);
      RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Cancellation_Requested);
   end Set_Cancelled_Before_Input;

   procedure Search_Stream_Buffered
     (Stream : in out Ada.Streams.Root_Stream_Type'Class;
      Source_Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.Stream_Source)
   is
      Buffer : Ada.Streams.Stream_Element_Array (1 .. Actual_Read_Block_Size (Options));
      Last : Ada.Streams.Stream_Element_Offset;
      Text : U.Unbounded_String;
      Diags : Greplib.Diagnostics.Diagnostic_List := Validate (Patterns, Options);
   begin
      if not Diags.Is_Empty then
         Set_Configuration_Failure (Outcome, Diags, Options);
         return;
      end if;

      if Greplib.Cancellation.Is_Requested (Cancellation) then
         Set_Cancelled_Before_Input (Outcome);
         return;
      end if;

      begin
         loop
            Stream.Read (Buffer, Last);
            exit when Last < Buffer'First;
            for I in Buffer'First .. Last loop
               U.Append (Text, Character'Val (Integer (Buffer (I))));
            end loop;
            exit when Greplib.Cancellation.Is_Requested (Cancellation);
         end loop;
      exception
         when E : others =>
            declare
               Stop_Current : Boolean := False;
               Stop_All : Boolean := False;
               D : constant Greplib.Diagnostics.Diagnostic :=
                 Greplib.Diagnostics.Make
                   (Greplib.Diagnostics.Stream_Read_Failed,
                    Greplib.Diagnostics.Fatal_Error,
                    "stream read failed",
                    Path => Greplib.Paths.Image (Source_Path),
                    Filesystem_Operation => "read",
                    Exception_Name => Ada.Exceptions.Exception_Name (E),
                    Exception_Message => Ada.Exceptions.Exception_Message (E));
            begin
               Set_Source_Failure (Outcome, D, Options);
               RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Opened_Field, 1);
               Emit
                 (Sink,
                  EB.Make_Diagnostic (Edit_Key, Source_Path, D, Sequence, Source_Kind),
                  Stop_Current,
                  Stop_All);
               if not Stop_Current and then not Stop_All then
                  Emit
                    (Sink,
                     EB.Make_Source_Completed (Edit_Key, Source_Path, Sequence, Source_Kind),
                     Stop_Current,
                     Stop_All);
               end if;
               if Stop_All then
                  RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
                  RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Callback_Stopped_Search);
               elsif Stop_Current then
                  RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Completed);
                  RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Callback_Stopped_Source);
               end if;
               RE.Append_Source_Summary
                 (Edit_Key,
                  Outcome,
                  Greplib.Sources.Building.Make (Edit_Key, Source_Kind, Sequence, Source_Path));
               return;
            end;
      end;

      Greplib.Search.Search_String_With_Source
        (U.To_String (Text), Source_Path, Patterns, Options, Sink, Outcome, Cancellation, Sequence, Source_Kind);
   end Search_Stream_Buffered;

   function Streaming_Eligible (Options : Greplib.Options.Search_Options) return Boolean is
      pragma Unreferenced (Options);
   begin
      return True;
   end Streaming_Eligible;

   procedure Search_Stream_Incremental
     (Stream : in out Ada.Streams.Root_Stream_Type'Class;
      Source_Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.Stream_Source)
   is
      use Greplib.Events;
      use Greplib.Options;

      Buffer : Ada.Streams.Stream_Element_Array (1 .. Actual_Read_Block_Size (Options));
      Last : Ada.Streams.Stream_Element_Offset;
      Current : U.Unbounded_String;
      Current_Original_Size : Byte_Count := 0;
      Current_Oversized : Boolean := False;
      Sep : constant Character := Greplib.Options.Separator (Options);
      Number : Record_Number := 1;
      Offset : Byte_Offset := 0;
      Stop_Current : Boolean := False;
      Stop_All : Boolean := False;
      Had_Selected : Boolean := False;
      Selected_Count : Wide_Count := 0;
      Total_Selected_Count : Wide_Count := 0;
      Match_Count : Wide_Count := 0;
      Delivered_Context_Count : Wide_Count := 0;
      Delivered_Result_Count : Wide_Count := 0;
      Bytes_Read_Total : Byte_Count := 0;
      Saw_Any_Byte : Boolean := False;
      Fatal_Source_Error : Boolean := False;
      Limit_Reached : Boolean := False;
      Internal_Stop : Boolean := False;
      Full_Binary_Pending : constant Boolean :=
        Options.Binary_Detection = Detect_Null_Byte
        and then Options.Separator_Kind /= NUL
        and then Options.On_Binary /= Search_As_Text;
      Full_Binary_Detected : Boolean := False;
      Binary_Report_Active : Boolean := False;
      Match_Spans_Truncated : Boolean := False;
      Context_Truncated : Boolean := False;
      Delay_Record_Events : constant Boolean :=
        Full_Binary_Pending and then Options.Mode = Emit_Selected_Records;
      Trailing_Context_Only : Boolean := False;
      After_Remaining : Wide_Count := 0;
      Current_Group : Wide_Count := 0;
      Last_Emitted_Record : Record_Number := 1;
      Have_Emitted_Record : Boolean := False;
      Prefix_Probe : U.Unbounded_String;
      Prefix_Limit : constant Natural := 4_096;
      Has_Context : constant Boolean := Options.Context.Before /= 0 or else Options.Context.After /= 0;

      procedure Append_Source_Summary is
      begin
         RE.Append_Source_Summary
           (Edit_Key,
            Outcome,
            Greplib.Sources.Building.Make (Edit_Key, Source_Kind, Sequence, Source_Path),
            Context_Record_Count => Delivered_Context_Count,
            Emitted_Result_Count => Delivered_Result_Count,
            Binary =>
              (if Options.Binary_Detection = No_Binary_Detection
               then Greplib.Results.Not_Classified
               elsif Full_Binary_Detected
               then Greplib.Results.Binary
               else Greplib.Results.Text_Like),
            Match_Spans_Truncated => Match_Spans_Truncated,
            Context_Truncated => Context_Truncated);
      end Append_Source_Summary;

      type Buffered_Record is record
         Number : Record_Number := 1;
         Offset : Byte_Offset := 0;
         Logical_Size : Byte_Count := 0;
         Original_Size : Byte_Count := 0;
         Separator_Size : Byte_Count := 0;
         Separator_Present : Boolean := False;
         CR_Stripped : Boolean := False;
         Text : Greplib.Byte_Strings.Byte_String;
         Spans : Greplib.Events.Span_List;
         Complete : Boolean := True;
      end record;

      package Buffered_Record_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Buffered_Record);
      Before_Buffer : Buffered_Record_Vectors.Vector;
      Before_Buffer_Bytes : Byte_Count := 0;
      Context_Overflow_Reported : Boolean := False;
      package Event_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Greplib.Events.Search_Event);
      Delayed_Events : Event_Vectors.Vector;
      Delayed_Event_Bytes : Byte_Count := 0;

      function Estimated_Record_Size (Rec : Buffered_Record) return Byte_Count is
         Span_Bytes : constant Byte_Count := Byte_Count (Rec.Spans.Length) * 24;
      begin
         return 1 + Greplib.Byte_Strings.Length (Rec.Text) + Span_Bytes;
      end Estimated_Record_Size;

      function Estimated_Event_Size (Event : Greplib.Events.Search_Event) return Byte_Count is
         Span_Bytes : constant Byte_Count := Byte_Count (Greplib.Events.Spans (Event).Length) * 24;
      begin
         if Greplib.Events.Kind (Event) in Greplib.Events.Selected_Record | Greplib.Events.Context_Record then
            return 1 + Greplib.Byte_Strings.Length (Greplib.Events.Content (Event)) + Span_Bytes;
         else
            return 1 + Span_Bytes;
         end if;
      end Estimated_Event_Size;

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

      procedure Publish_Event (Event : Greplib.Events.Search_Event) is
         Size : constant Byte_Count := Estimated_Event_Size (Event);
      begin
         if Delay_Record_Events and then not Full_Binary_Detected then
            if Size > Options.Maximum_Context_Buffer_Bytes - Delayed_Event_Bytes then
               declare
                  D : constant Greplib.Diagnostics.Diagnostic :=
                    Greplib.Diagnostics.Make
                      (Greplib.Diagnostics.Resource_Context_Buffer_Exceeded,
                       Greplib.Diagnostics.Fatal_Error,
                       "delayed binary-classification event buffer exceeded",
                       Path => Greplib.Paths.Image (Source_Path),
                       Has_Numeric_Limit => True,
                       Numeric_Limit => Options.Maximum_Context_Buffer_Bytes,
                       Has_Observed_Size => True,
                       Observed_Size => Delayed_Event_Bytes + Size);
               begin
                  Retain_Diagnostic (D);
                  Context_Truncated := True;
                  Context_Overflow_Reported := True;
                  Emit
                    (Sink,
                     EB.Make_Diagnostic (Edit_Key, Source_Path, D, Sequence, Source_Kind),
                     Stop_Current,
                     Stop_All);
                  Fatal_Source_Error := True;
                  Stop_Current := True;
               end;
            else
               Delayed_Events.Append (Event);
               Delayed_Event_Bytes := Delayed_Event_Bytes + Size;
            end if;
         else
            Emit (Sink, Event, Stop_Current, Stop_All);
         end if;
      end Publish_Event;

      procedure Flush_Delayed_Events is
      begin
         for Event of Delayed_Events loop
            Emit (Sink, Event, Stop_Current, Stop_All);
            exit when Stop_Current or else Stop_All;
         end loop;
         Delayed_Events.Clear;
         Delayed_Event_Bytes := 0;
      end Flush_Delayed_Events;

      procedure Discard_Delayed_Events is
      begin
         Delayed_Events.Clear;
         Delayed_Event_Bytes := 0;
      end Discard_Delayed_Events;

      procedure Finish_Record (Separator_Size : Byte_Count) is
         Raw : constant String := U.To_String (Current);
         Stripped : constant Boolean :=
           Options.CR_Policy = Strip_Before_Line_Feed
           and then Raw'Length > 0
           and then Raw (Raw'Last) = ASCII.CR;
         Logical : constant String := (if Stripped then Raw (Raw'First .. Raw'Last - 1) else Raw);
         Positive : Boolean := False;
         Selected : Boolean := False;
         Spans : Greplib.Events.Span_List;
         Complete : Boolean := True;

         procedure Emit_Record (Kind : Greplib.Events.Event_Kind; Rec : Buffered_Record) is
            Group : Wide_Count := 0;
         begin
            if Has_Context then
               if not Have_Emitted_Record or else Last_Emitted_Record + 1 /= Rec.Number then
                  Current_Group := Current_Group + 1;
               end if;
               Group := Current_Group;
               Last_Emitted_Record := Rec.Number;
               Have_Emitted_Record := True;
            end if;

            Publish_Event
              (EB.Make_Record (Edit_Key, Kind, Source_Path, Group, Rec.Number, Rec.Offset, Rec.Logical_Size,
                  Rec.Original_Size, Rec.Separator_Size, Rec.Separator_Present,
                  Rec.CR_Stripped, Rec.Text, Rec.Spans, Rec.Complete, Sequence, Source_Kind));
            Delivered_Result_Count := Delivered_Result_Count + 1;
            if Kind = Context_Record then
               Delivered_Context_Count := Delivered_Context_Count + 1;
            end if;
         end Emit_Record;

         procedure Add_Before (Rec : Buffered_Record) is
         begin
            if Options.Mode /= Emit_Selected_Records or else Options.Context.Before = 0 then
               return;
            end if;

            while Wide_Count (Before_Buffer.Length) >= Options.Context.Before loop
               Before_Buffer_Bytes := Before_Buffer_Bytes - Estimated_Record_Size (Before_Buffer.First_Element);
               Before_Buffer.Delete_First;
            end loop;
            while not Before_Buffer.Is_Empty
              and then Estimated_Record_Size (Rec) > Options.Maximum_Context_Buffer_Bytes - Before_Buffer_Bytes
            loop
               Before_Buffer_Bytes := Before_Buffer_Bytes - Estimated_Record_Size (Before_Buffer.First_Element);
               Before_Buffer.Delete_First;
               if not Context_Overflow_Reported then
                  declare
                     D : constant Greplib.Diagnostics.Diagnostic :=
                       Greplib.Diagnostics.Make
                         (Greplib.Diagnostics.Resource_Context_Buffer_Exceeded,
                          Greplib.Diagnostics.Recoverable_Error,
                          "before-context buffer exceeded",
                          Path => Greplib.Paths.Image (Source_Path),
                          Has_Numeric_Limit => True,
                          Numeric_Limit => Options.Maximum_Context_Buffer_Bytes,
                          Has_Observed_Size => True,
                          Observed_Size => Before_Buffer_Bytes + Estimated_Record_Size (Rec));
                  begin
                     Context_Overflow_Reported := True;
                     Context_Truncated := True;
                     Retain_Diagnostic (D);
                     Emit
                       (Sink,
                        EB.Make_Diagnostic (Edit_Key, Source_Path, D, Sequence, Source_Kind),
                        Stop_Current,
                        Stop_All);
                  end;
               end if;
            end loop;
            if Estimated_Record_Size (Rec) > Options.Maximum_Context_Buffer_Bytes then
               if not Context_Overflow_Reported then
                  declare
                     D : constant Greplib.Diagnostics.Diagnostic :=
                       Greplib.Diagnostics.Make
                         (Greplib.Diagnostics.Resource_Context_Buffer_Exceeded,
                          Greplib.Diagnostics.Recoverable_Error,
                          "before-context record exceeds buffer",
                          Path => Greplib.Paths.Image (Source_Path),
                          Has_Record => True,
                          Record_No => Rec.Number,
                          Has_Numeric_Limit => True,
                          Numeric_Limit => Options.Maximum_Context_Buffer_Bytes,
                          Has_Observed_Size => True,
                          Observed_Size => Estimated_Record_Size (Rec));
                  begin
                     Context_Overflow_Reported := True;
                     Context_Truncated := True;
                     Retain_Diagnostic (D);
                     Emit
                       (Sink,
                        EB.Make_Diagnostic (Edit_Key, Source_Path, D, Sequence, Source_Kind),
                        Stop_Current,
                        Stop_All);
                  end;
               end if;
               return;
            end if;
            Before_Buffer.Append (Rec);
            Before_Buffer_Bytes := Before_Buffer_Bytes + Estimated_Record_Size (Rec);
         end Add_Before;

         procedure Emit_Before is
         begin
            for Rec of Before_Buffer loop
               Emit_Record (Context_Record, Rec);
               exit when Stop_Current or else Stop_All;
            end loop;
            Before_Buffer.Clear;
            Before_Buffer_Bytes := 0;
         end Emit_Before;

         procedure Apply_Span_Controls is
         begin
            if Options.Mode = Emit_Selected_Records
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
                       Path => Greplib.Paths.Image (Source_Path),
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
                  Publish_Event (EB.Make_Diagnostic (Edit_Key, Source_Path, D, Sequence, Source_Kind));
               end;
            end if;
         end Apply_Span_Controls;
      begin
         if Current_Oversized then
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
                       Path => Greplib.Paths.Image (Source_Path),
                       Has_Record => True,
                       Record_No => Number,
                       Has_Numeric_Limit => True,
                       Numeric_Limit => Options.Maximum_Record_Size,
                       Has_Observed_Size => True,
                       Observed_Size => Current_Original_Size);
               begin
                  Retain_Diagnostic (D);
                  Publish_Event (EB.Make_Diagnostic (Edit_Key, Source_Path, D, Sequence, Source_Kind));
               end;
            end if;

            if Options.Mode = Count_Matches then
               RE.Set_Match_Count_State (Edit_Key, Outcome, Greplib.Results.Lower_Bound);
            end if;
            if Options.On_Oversized_Record = Fail_Source then
               Fatal_Source_Error := True;
            end if;
            Before_Buffer.Clear;
            Before_Buffer_Bytes := 0;
         else
            if not Trailing_Context_Only then
               Greplib.Patterns.Match_Record
                 (Patterns, Logical, Options.Spans /= No_Spans or else Options.Mode = Count_Matches,
                  Positive, Spans, Complete);
               Apply_Span_Controls;
               Selected := (if Options.Invert_Match then not Positive else Positive);
            end if;

            declare
               Rec : constant Buffered_Record :=
                 (Number => Number,
                  Offset => Offset,
                  Logical_Size => Byte_Count (Logical'Length),
                  Original_Size => Current_Original_Size,
                  Separator_Size => Separator_Size,
                  Separator_Present => Separator_Size /= 0,
                  CR_Stripped => Stripped,
                  Text => Greplib.Byte_Strings.To_Byte_String (Logical),
                  Spans => Spans,
                  Complete => Complete);
            begin
               if Trailing_Context_Only then
                  if Options.Mode = Emit_Selected_Records and then After_Remaining > 0 then
                     Emit_Record (Context_Record, Rec);
                     After_Remaining := After_Remaining - 1;
                  end if;
                  if After_Remaining = 0 then
                     Internal_Stop := True;
                     Stop_Current := True;
                  end if;
               elsif Selected then
                  Had_Selected := True;
                  Total_Selected_Count := Total_Selected_Count + 1;
                  if Options.Maximum_Selected_Records = 0
                    or else Selected_Count < Options.Maximum_Selected_Records
                  then
                     Selected_Count := Selected_Count + 1;
                     if Options.Mode = Emit_Selected_Records and then not Binary_Report_Active then
                        if Has_Context then
                           Emit_Before;
                        end if;
                        if not Stop_Current and then not Stop_All then
                           Emit_Record (Selected_Record, Rec);
                        end if;
                     end if;

                     After_Remaining := Options.Context.After;
                     if Options.Maximum_Selected_Records /= 0
                       and then Selected_Count = Options.Maximum_Selected_Records
                     then
                        Limit_Reached := True;
                        RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Match_Limit_Reached);
                        if After_Remaining = 0 then
                           Internal_Stop := True;
                           Stop_Current := True;
                        else
                           Trailing_Context_Only := True;
                        end if;
                     end if;
                  else
                     Limit_Reached := True;
                     RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Match_Limit_Reached);
                     Stop_Current := True;
                  end if;
               elsif Options.Mode = Emit_Selected_Records and then After_Remaining > 0 then
                  Emit_Record (Context_Record, Rec);
                  After_Remaining := After_Remaining - 1;
               else
                  Add_Before (Rec);
               end if;
            end;

            if Positive then
               Match_Count := Match_Count + Wide_Count (Spans.Length);
            end if;
         end if;

         RE.Add_Wide (Edit_Key, Outcome, RE.Records_Read_Field);
         Offset := Offset + Current_Original_Size + Separator_Size;
         Number := Number + 1;
         U.Set_Unbounded_String (Current, "");
         Current_Original_Size := 0;
         Current_Oversized := False;

         if Binary_Report_Active and then Had_Selected then
            Delivered_Result_Count := Delivered_Result_Count + 1;
            Emit (Sink, EB.Make_Binary_Match (Edit_Key, Source_Path, Sequence, Source_Kind), Stop_Current, Stop_All);
            Internal_Stop := True;
            Stop_Current := True;
         elsif Options.Mode = Quiet and then Had_Selected and then not Full_Binary_Pending then
            RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Quiet_Match_Found);
            Internal_Stop := True;
            Stop_Current := True;
         elsif Options.Mode = Source_Names_With_Matches and then Had_Selected and then not Full_Binary_Pending then
            Delivered_Result_Count := Delivered_Result_Count + 1;
            Emit
              (Sink,
               EB.Make_Source_Name (Edit_Key, Source_Path, True, Sequence, Source_Kind),
               Stop_Current,
               Stop_All);
            Internal_Stop := True;
            Stop_Current := True;
         elsif Limit_Reached and then not Trailing_Context_Only then
            RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Match_Limit_Reached);
            Internal_Stop := True;
            Stop_Current := True;
         end if;
      end Finish_Record;

      procedure Append_Byte (C : Character) is
      begin
         Current_Original_Size := Current_Original_Size + 1;
         if Current_Oversized then
            return;
         elsif Current_Original_Size > Options.Maximum_Record_Size then
            Current_Oversized := True;
            U.Set_Unbounded_String (Current, "");
         else
            U.Append (Current, C);
         end if;
      end Append_Byte;

      procedure Process_Byte (C : Character) is
      begin
         Saw_Any_Byte := True;
         if Full_Binary_Pending and then C = Character'Val (0) then
            Full_Binary_Detected := True;
            Discard_Delayed_Events;
            case Options.On_Binary is
               when Skip_Source =>
                  Internal_Stop := True;
                  Stop_Current := True;
                  return;
               when Fail_Source =>
                  declare
                     D : constant Greplib.Diagnostics.Diagnostic :=
                       Greplib.Diagnostics.Make
                         (Greplib.Diagnostics.Input_Binary_Detected,
                          Greplib.Diagnostics.Fatal_Error,
                          "binary input detected");
                  begin
                     Retain_Diagnostic (D);
                     Emit
                       (Sink,
                        EB.Make_Diagnostic (Edit_Key, Source_Path, D, Sequence, Source_Kind),
                        Stop_Current,
                        Stop_All);
                     Fatal_Source_Error := True;
                     return;
                  end;
               when Report_Match_Without_Record =>
                  Binary_Report_Active := True;
                  if Had_Selected then
                     Delivered_Result_Count := Delivered_Result_Count + 1;
                     Emit
                       (Sink,
                        EB.Make_Binary_Match (Edit_Key, Source_Path, Sequence, Source_Kind),
                        Stop_Current,
                        Stop_All);
                     Internal_Stop := True;
                     Stop_Current := True;
                     return;
                  end if;
               when Search_As_Text =>
                  null;
            end case;
         end if;

         if C = Sep then
            Finish_Record (1);
         else
            Append_Byte (C);
         end if;
      end Process_Byte;

      procedure Replay_Prefix is
         S : constant String := U.To_String (Prefix_Probe);
      begin
         for C of S loop
            Process_Byte (C);
            exit when Stop_Current
              or else Stop_All
              or else Fatal_Source_Error
              or else Greplib.Cancellation.Is_Requested (Cancellation);
         end loop;
         U.Set_Unbounded_String (Prefix_Probe, "");
      end Replay_Prefix;

      function Probe_Is_Binary return Boolean is
         S : constant String := U.To_String (Prefix_Probe);
      begin
         if Options.Separator_Kind = NUL then
            return False;
         end if;
         for C of S loop
            if C = Character'Val (0) then
               return True;
            end if;
         end loop;
         return False;
      end Probe_Is_Binary;

      procedure Apply_Binary_Policy is
      begin
         case Options.On_Binary is
            when Search_As_Text =>
               Replay_Prefix;
            when Skip_Source =>
               Internal_Stop := True;
               Stop_Current := True;
            when Report_Match_Without_Record =>
               Binary_Report_Active := True;
               Replay_Prefix;
            when Fail_Source =>
               declare
                  D : constant Greplib.Diagnostics.Diagnostic :=
                    Greplib.Diagnostics.Make
                      (Greplib.Diagnostics.Input_Binary_Detected,
                       Greplib.Diagnostics.Fatal_Error,
                       "binary input detected");
               begin
                  Retain_Diagnostic (D);
                  Emit
                    (Sink,
                     EB.Make_Diagnostic (Edit_Key, Source_Path, D, Sequence, Source_Kind),
                     Stop_Current,
                     Stop_All);
                  Fatal_Source_Error := True;
               end;
         end case;
      end Apply_Binary_Policy;

      procedure Report_Read_Failure is
         D : constant Greplib.Diagnostics.Diagnostic :=
           Greplib.Diagnostics.Make
             (Greplib.Diagnostics.Stream_Read_Failed,
              Greplib.Diagnostics.Fatal_Error,
              "stream read failed",
              Path => Greplib.Paths.Image (Source_Path),
              Filesystem_Operation => "read");
      begin
         Retain_Diagnostic (D);
         Emit (Sink, EB.Make_Diagnostic (Edit_Key, Source_Path, D, Sequence, Source_Kind), Stop_Current, Stop_All);
         Fatal_Source_Error := True;
      end Report_Read_Failure;

      Diags : Greplib.Diagnostics.Diagnostic_List := Validate (Patterns, Options);
   begin
      RE.Reset (Edit_Key, Outcome);
      RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Considered_Field, 1);

      if not Diags.Is_Empty then
         Set_Configuration_Failure (Outcome, Diags, Options);
         return;
      end if;

      if Greplib.Cancellation.Is_Requested (Cancellation) then
         Set_Cancelled_Before_Input (Outcome);
         return;
      end if;

      Emit (Sink, EB.Make_Source_Started (Edit_Key, Source_Path, Sequence, Source_Kind), Stop_Current, Stop_All);
      RE.Set_Wide (Edit_Key, Outcome, RE.Sources_Opened_Field, 1);

      if Options.Binary_Detection = Detect_Using_Prefix
        and then Options.Separator_Kind /= NUL
      then
         while Natural (U.Length (Prefix_Probe)) < Prefix_Limit loop
            declare
               Remaining : constant Ada.Streams.Stream_Element_Offset :=
                 Ada.Streams.Stream_Element_Offset
                   (Prefix_Limit - Natural (U.Length (Prefix_Probe)));
               Request_Count : constant Ada.Streams.Stream_Element_Offset :=
                 Ada.Streams.Stream_Element_Offset'Min (Remaining, Buffer'Length);
               Read_Last : Ada.Streams.Stream_Element_Offset;
            begin
               begin
                  Stream.Read (Buffer (Buffer'First .. Buffer'First + Request_Count - 1), Read_Last);
               exception
                  when others =>
                     Report_Read_Failure;
                     exit;
               end;
               exit when Read_Last < Buffer'First;
               Bytes_Read_Total :=
                 Bytes_Read_Total + Byte_Count (Read_Last - Buffer'First + 1);
               for I in Buffer'First .. Read_Last loop
                  U.Append (Prefix_Probe, Character'Val (Integer (Buffer (I))));
               end loop;
            end;
            exit when Greplib.Cancellation.Is_Requested (Cancellation) or else Fatal_Source_Error;
         end loop;

         if not Fatal_Source_Error then
            if Probe_Is_Binary then
               Full_Binary_Detected := True;
               Apply_Binary_Policy;
            else
               Replay_Prefix;
            end if;
         end if;
      end if;

      while not Stop_Current and then not Stop_All and then not Fatal_Source_Error loop
         begin
            Stream.Read (Buffer, Last);
         exception
            when others =>
               Report_Read_Failure;
               exit;
         end;
         exit when Last < Buffer'First;
         Bytes_Read_Total := Bytes_Read_Total + Byte_Count (Last - Buffer'First + 1);
         for I in Buffer'First .. Last loop
            declare
               C : constant Character := Character'Val (Integer (Buffer (I)));
            begin
               Process_Byte (C);
            end;
            exit when Stop_Current
              or else Stop_All
              or else Fatal_Source_Error
              or else Greplib.Cancellation.Is_Requested (Cancellation);
         end loop;
         exit when Greplib.Cancellation.Is_Requested (Cancellation);
      end loop;

      if not Stop_Current
        and then not Stop_All
        and then not Fatal_Source_Error
        and then not Greplib.Cancellation.Is_Requested (Cancellation)
        and then Saw_Any_Byte
        and then Current_Original_Size > 0
      then
         Finish_Record (0);
      end if;

      if Full_Binary_Pending and then Options.On_Binary = Skip_Source and then Full_Binary_Detected then
         null;
      elsif not Stop_Current
        and then not Stop_All
        and then not Fatal_Source_Error
        and then RE.Status (Outcome) /= Greplib.Results.Failed
      then
         if Delay_Record_Events and then not Full_Binary_Detected then
            Flush_Delayed_Events;
         end if;
         if Options.Mode = Count_Selected_Records then
            Delivered_Result_Count := Delivered_Result_Count + 1;
            Emit
              (Sink,
               EB.Make_Count (Edit_Key, Source_Path, Selected_Count, Sequence, Source_Kind),
               Stop_Current,
               Stop_All);
         elsif Options.Mode = Count_Matches then
            Delivered_Result_Count := Delivered_Result_Count + 1;
            Emit
              (Sink,
               EB.Make_Count (Edit_Key, Source_Path, Match_Count, Sequence, Source_Kind),
               Stop_Current,
               Stop_All);
         elsif Options.Mode = Quiet and then Had_Selected then
            RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Quiet_Match_Found);
         elsif Options.Mode = Source_Names_With_Matches and then Had_Selected then
            Delivered_Result_Count := Delivered_Result_Count + 1;
            Emit
              (Sink,
               EB.Make_Source_Name (Edit_Key, Source_Path, True, Sequence, Source_Kind),
               Stop_Current,
               Stop_All);
         elsif Options.Mode = Source_Names_Without_Matches and then not Had_Selected then
            Delivered_Result_Count := Delivered_Result_Count + 1;
            Emit
              (Sink,
               EB.Make_Source_Name (Edit_Key, Source_Path, False, Sequence, Source_Kind),
               Stop_Current,
               Stop_All);
         end if;
      end if;

      if not Stop_Current
        and then not Stop_All
        and then not Fatal_Source_Error
        and then RE.Status (Outcome) /= Greplib.Results.Failed
      then
         Emit (Sink, EB.Make_Source_Completed (Edit_Key, Source_Path, Sequence, Source_Kind), Stop_Current, Stop_All);
      end if;

      if Stop_All then
         RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Callback_Stopped_Search);
      elsif Stop_Current
        and then not Internal_Stop
        and then RE.Reason (Outcome) = Greplib.Results.Input_Exhausted
      then
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Callback_Stopped_Source);
      elsif Greplib.Cancellation.Is_Requested (Cancellation) then
         RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
         RE.Set_Cancellation_Observed (Edit_Key, Outcome, True);
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Cancellation_Requested);
      end if;

      RE.Set_Wide
        (Edit_Key, Outcome, RE.Sources_Completed_Field,
        (if RE.Status (Outcome) = Greplib.Results.Failed
           or else RE.Status (Outcome) = Greplib.Results.Cancelled
           or else RE.Reason (Outcome) = Greplib.Results.Callback_Stopped_Source
         then 0
         else 1));
      RE.Set_Wide (Edit_Key, Outcome, RE.Selected_Record_Count_Field, Selected_Count);
      RE.Set_Wide (Edit_Key, Outcome, RE.Match_Count_Field, Match_Count);
      RE.Set_Bytes_Read (Edit_Key, Outcome, Bytes_Read_Total);
      RE.Set_Wide
        (Edit_Key, Outcome, RE.Sources_With_Results_Field,
        (if Full_Binary_Detected and then Options.On_Binary = Skip_Source
         then 0
         elsif Had_Selected or else Options.Mode = Source_Names_Without_Matches
         then 1
         else 0));
      Append_Source_Summary;
   end Search_Stream_Incremental;

   procedure Search_Stream_With_Source
     (Stream : in out Ada.Streams.Root_Stream_Type'Class;
      Source_Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.Stream_Source) is
   begin
      if Streaming_Eligible (Options) then
         Search_Stream_Incremental
           (Stream, Source_Path, Patterns, Options, Sink, Outcome, Cancellation, Sequence, Source_Kind);
      else
         Search_Stream_Buffered
           (Stream, Source_Path, Patterns, Options, Sink, Outcome, Cancellation, Sequence, Source_Kind);
      end if;
   end Search_Stream_With_Source;

   procedure Search_Stream
     (Stream : in out Ada.Streams.Root_Stream_Type'Class;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1) is
   begin
      Search_Stream_With_Source
        (Stream, Greplib.Paths.To_Path ("<stream>"), Patterns, Options, Sink, Outcome, Cancellation, Sequence,
         Greplib.Sources.Stream_Source);
   end Search_Stream;

   procedure Search_Stream
     (Stream : in out Ada.Streams.Root_Stream_Type'Class;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1)
   is
      Sink : Greplib.Events.No_Op_Sink;
   begin
      Search_Stream (Stream, Patterns, Options, Sink, Outcome, Cancellation, Sequence);
   end Search_Stream;

   procedure Search_File_With_Sequence
     (Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1)
   is
      File : Ada.Streams.Stream_IO.File_Type;
      Source_Kind : constant Greplib.Sources.Source_Kind := Greplib.Sources.File_Source;
      Diags : Greplib.Diagnostics.Diagnostic_List := Validate (Patterns, Options);
      Have_Start_Metadata : Boolean := False;
      Start_Size : Ada.Directories.File_Size := 0;
      Start_Time : Ada.Calendar.Time := Ada.Calendar.Time_Of (1901, 1, 1);

      procedure Capture_Start_Metadata is
      begin
         Start_Size := Ada.Directories.Size (Greplib.Paths.Image (Path));
         Start_Time := Ada.Directories.Modification_Time (Greplib.Paths.Image (Path));
         Have_Start_Metadata := True;
      exception
         when others =>
            Have_Start_Metadata := False;
      end Capture_Start_Metadata;

      procedure Mark_Changed_If_Metadata_Differs is
         End_Size : Ada.Directories.File_Size;
         End_Time : Ada.Calendar.Time;
      begin
         if not Have_Start_Metadata then
            return;
         end if;

         End_Size := Ada.Directories.Size (Greplib.Paths.Image (Path));
         End_Time := Ada.Directories.Modification_Time (Greplib.Paths.Image (Path));
         if End_Size /= Start_Size or else End_Time /= Start_Time then
            RE.Mark_Last_Source_Changed (Edit_Key, Outcome);
         end if;
      exception
         when others =>
            null;
      end Mark_Changed_If_Metadata_Differs;
   begin
      if not Diags.Is_Empty then
         Set_Configuration_Failure (Outcome, Diags, Options);
         return;
      end if;

      if Greplib.Cancellation.Is_Requested (Cancellation) then
         Set_Cancelled_Before_Input (Outcome);
         return;
      end if;

      if Greplib.Internal.Filesystem.Has_Fake_Content (Greplib.Paths.Image (Path)) then
         declare
            Fake_Stream : Fake_File_Stream :=
              (Ada.Streams.Root_Stream_Type with
               Text => U.To_Unbounded_String
                 (Greplib.Internal.Filesystem.Fake_Content (Greplib.Paths.Image (Path))),
               Next => 1,
               Bytes_Returned => 0,
               Fail_After =>
                 Greplib.Internal.Filesystem.Fake_Read_Failure_After (Greplib.Paths.Image (Path)));
         begin
            Search_Stream_With_Source
              (Fake_Stream, Path, Patterns, Options, Sink, Outcome, Cancellation, Sequence,
               Greplib.Sources.File_Source);
            return;
         end;
      end if;

      Capture_Start_Metadata;
      begin
         Ada.Streams.Stream_IO.Open (File, Ada.Streams.Stream_IO.In_File, Greplib.Paths.Image (Path),
                                     Form => "shared=no");
      exception
         when E : others =>
            declare
               Stop_Current : Boolean := False;
               Stop_All : Boolean := False;
               D : constant Greplib.Diagnostics.Diagnostic :=
                 Greplib.Diagnostics.Make
                   (Greplib.Diagnostics.Filesystem_Open_Failed,
                    Greplib.Diagnostics.Fatal_Error,
                    Greplib.Paths.Image (Path),
                    Path => Greplib.Paths.Image (Path),
                    Filesystem_Operation => "open",
                    Exception_Name => Ada.Exceptions.Exception_Name (E),
                    Exception_Message => Ada.Exceptions.Exception_Message (E));
            begin
               Set_Source_Failure (Outcome, D, Options);
               Emit (Sink, EB.Make_Source_Started (Edit_Key, Path, Sequence, Source_Kind), Stop_Current, Stop_All);
               Emit (Sink, EB.Make_Diagnostic (Edit_Key, Path, D, Sequence, Source_Kind), Stop_Current, Stop_All);
               if not Stop_Current and then not Stop_All then
                  Emit (Sink, EB.Make_Source_Completed (Edit_Key, Path, Sequence, Source_Kind), Stop_Current, Stop_All);
               end if;
               if Stop_All then
                  RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
                  RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Callback_Stopped_Search);
               elsif Stop_Current then
                  RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Completed);
                  RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Callback_Stopped_Source);
               end if;
               RE.Append_Source_Summary
                 (Edit_Key,
                  Outcome,
                  Greplib.Sources.Building.Make (Edit_Key, Source_Kind, Sequence, Path));
               return;
            end;
      end;

      Search_Stream_With_Source
        (Ada.Streams.Stream_IO.Stream (File).all, Path, Patterns, Options, Sink, Outcome, Cancellation, Sequence,
         Greplib.Sources.File_Source);
      Ada.Streams.Stream_IO.Close (File);
      Mark_Changed_If_Metadata_Differs;
   exception
      when others =>
         if Ada.Streams.Stream_IO.Is_Open (File) then
            Ada.Streams.Stream_IO.Close (File);
         end if;
         raise;
   end Search_File_With_Sequence;

   procedure Search_File
     (Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1) is
   begin
      Search_File_With_Sequence (Path, Patterns, Options, Sink, Outcome, Cancellation, Sequence);
   end Search_File;

   procedure Search_File
     (Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1)
   is
      Sink : Greplib.Events.No_Op_Sink;
   begin
      Search_File (Path, Patterns, Options, Sink, Outcome, Cancellation, Sequence);
   end Search_File;
end Greplib.Files;
