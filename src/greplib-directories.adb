pragma Ada_2022;

with Ada.Containers.Indefinite_Vectors;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Greplib.Byte_Strings;
with Greplib.Diagnostics;
with Greplib.Events.Building;
with Greplib.Files;
with Greplib.Internal.Filesystem;
with Greplib.Internal.Filesystem_Identity;
with Greplib.Path_Filters;
with Greplib.Patterns;
with Greplib.Result_Authority;
with Greplib.Results.Editing;
with Greplib.Sources;
with Greplib.Sources.Building;

package body Greplib.Directories is
   package EB renames Greplib.Events.Building;
   package RE renames Greplib.Results.Editing;
   Edit_Key : constant Greplib.Result_Authority.Token := Greplib.Result_Authority.Internal;
   package U renames Ada.Strings.Unbounded;
   use type Ada.Containers.Count_Type;
   use type Greplib.Diagnostics.Severity;
   use type Greplib.Options.Result_Mode;
   use type Greplib.Options.Result_Order;
   use type Greplib.Events.Event_Kind;
   use type Greplib.Results.Count_Completeness;
   use type Greplib.Results.Completion_Reason;
   use type Greplib.Results.Overall_Status;
   use type Greplib.Directories.Traversal_Error_Policy;
   use type Greplib.Internal.Filesystem.Entry_Kind;
   use type Greplib.Events.Search_Event;

   procedure Retain_Diagnostic
     (Outcome : in out Greplib.Results.Search_Outcome;
      Item : Greplib.Diagnostics.Diagnostic;
      Maximum_Retained : Wide_Count) is
   begin
      RE.Add_Wide (Edit_Key, Outcome, RE.Diagnostic_Count_Field);
      if Maximum_Retained = 0 then
         RE.Set_Diagnostics_Truncated (Edit_Key, Outcome, True);
      elsif RE.Retained_Diagnostic_Count (Outcome) < Maximum_Retained then
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

   function Traversal_Severity
     (Options : Directory_Search_Options) return Greplib.Diagnostics.Severity is
   begin
      if Options.Traversal_Errors = Fail_Search then
         return Greplib.Diagnostics.Fatal_Error;
      else
         return Greplib.Diagnostics.Recoverable_Error;
      end if;
   end Traversal_Severity;

   procedure Add_Diagnostic
     (Outcome : in out Greplib.Results.Search_Outcome;
      Item : Greplib.Diagnostics.Diagnostic;
      Search_Options : Greplib.Options.Search_Options) is
   begin
      Retain_Diagnostic (Outcome, Item, Search_Options.Maximum_Retained_Diagnostics);
   end Add_Diagnostic;

   procedure Apply_Pre_Traversal_Failure
     (Outcome : in out Greplib.Results.Search_Outcome;
      Diagnostics : Greplib.Diagnostics.Diagnostic_List;
      Search_Options : Greplib.Options.Search_Options) is
   begin
      RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Failed);
      RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Fatal_Error);
      RE.Set_Wide (Edit_Key, Outcome, RE.Diagnostic_Count_Field, Wide_Count (Diagnostics.Length));
      for I in 1 .. Natural (Diagnostics.Length) loop
         declare
            D : constant Greplib.Diagnostics.Diagnostic := Diagnostics.Element (I);
         begin
            if Search_Options.Maximum_Retained_Diagnostics = 0 then
               RE.Set_Diagnostics_Truncated (Edit_Key, Outcome, True);
            elsif RE.Retained_Diagnostic_Count (Outcome) < Search_Options.Maximum_Retained_Diagnostics then
               RE.Append_Diagnostic (Edit_Key, Outcome, D);
            else
               RE.Set_Diagnostics_Truncated (Edit_Key, Outcome, True);
            end if;
         end;
      end loop;
   end Apply_Pre_Traversal_Failure;

   procedure Merge_Source_Outcome
     (Outcome : in out Greplib.Results.Search_Outcome;
      Source : Greplib.Results.Search_Outcome;
      Search_Options : Greplib.Options.Search_Options) is
   begin
      RE.Add_Summary (Edit_Key, Outcome, Source);
      if RE.Match_Count_State (Source) = Greplib.Results.Unavailable then
         RE.Set_Match_Count_State (Edit_Key, Outcome, Greplib.Results.Unavailable);
      elsif RE.Match_Count_State (Source) = Greplib.Results.Lower_Bound
        and then RE.Match_Count_State (Outcome) = Greplib.Results.Exact
      then
         RE.Set_Match_Count_State (Edit_Key, Outcome, Greplib.Results.Lower_Bound);
      end if;

      if RE.Diagnostics_Truncated (Source) then
         RE.Set_Diagnostics_Truncated (Edit_Key, Outcome, True);
      end if;
      for I in 1 .. Natural (RE.Retained_Diagnostic_Count (Source)) loop
         declare
            D : constant Greplib.Diagnostics.Diagnostic := RE.Retained_Diagnostic (Source, I);
         begin
            if Search_Options.Maximum_Retained_Diagnostics = 0 then
               RE.Set_Diagnostics_Truncated (Edit_Key, Outcome, True);
            elsif RE.Retained_Diagnostic_Count (Outcome) < Search_Options.Maximum_Retained_Diagnostics then
               RE.Append_Diagnostic (Edit_Key, Outcome, D);
            else
               RE.Set_Diagnostics_Truncated (Edit_Key, Outcome, True);
            end if;
         end;
      end loop;

      if RE.Status (Source) = Greplib.Results.Cancelled then
         RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
         RE.Set_Cancellation_Observed (Edit_Key, Outcome, True);
         RE.Set_Reason (Edit_Key, Outcome, RE.Reason (Source));
      elsif RE.Status (Source) = Greplib.Results.Failed
        and then RE.Reason (Source) = Greplib.Results.Fatal_Error
      then
         RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Failed);
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Fatal_Error);
      elsif RE.Status (Source) = Greplib.Results.Failed
        and then RE.Status (Outcome) = Greplib.Results.Completed
      then
         RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Completed_With_Recoverable_Errors);
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Source_Error);
      elsif RE.Status (Source) = Greplib.Results.Completed_With_Recoverable_Errors
        and then RE.Status (Outcome) = Greplib.Results.Completed
      then
         RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Completed_With_Recoverable_Errors);
         RE.Set_Reason (Edit_Key, Outcome, RE.Reason (Source));
      elsif RE.Reason (Source) = Greplib.Results.Callback_Stopped_Source
        and then RE.Status (Outcome) = Greplib.Results.Completed
      then
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Callback_Stopped_Source);
      end if;
   end Merge_Source_Outcome;

   package String_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, String);

   type Source_Result is record
      Outcome : Greplib.Results.Search_Outcome;
   end record;
   type Source_Result_Array is array (Positive range <>) of Source_Result;

   type Event_Array is array (Positive range <>) of Greplib.Events.Search_Event;

   function Event_Size (Event : Greplib.Events.Search_Event) return Byte_Count is
      Span_Bytes : constant Byte_Count := Byte_Count (Greplib.Events.Spans (Event).Length) * 24;
   begin
      if Greplib.Events.Kind (Event) in Greplib.Events.Selected_Record | Greplib.Events.Context_Record then
         return 1 + Greplib.Byte_Strings.Length (Greplib.Events.Content (Event)) + Span_Bytes;
      else
         return 1 + Span_Bytes;
      end if;
   end Event_Size;

   protected type Event_Channel
     (Capacity : Positive;
      Maximum_Bytes : Byte_Count)
   is
      entry Publish
        (Event : Greplib.Events.Search_Event;
         Size : Byte_Count;
         Accepted : out Boolean);
      entry Take (Event : out Greplib.Events.Search_Event; Found : out Boolean);
      procedure Reset;
      procedure Close;
      procedure Cancel;
   private
      Buffer : Event_Array (1 .. Capacity);
      Head : Positive := 1;
      Tail : Positive := 1;
      Count : Natural := 0;
      Queued_Bytes : Byte_Count := 0;
      Closed : Boolean := False;
      Cancelled : Boolean := False;
   end Event_Channel;

   protected body Event_Channel is
      entry Publish
        (Event : Greplib.Events.Search_Event;
         Size : Byte_Count;
         Accepted : out Boolean)
        when Count < Capacity or else Cancelled
      is
      begin
         if Cancelled then
            Accepted := False;
         elsif Count > 0 and then Size > Maximum_Bytes - Queued_Bytes then
            Accepted := False;
         else
            Buffer (Tail) := Event;
            Tail := (if Tail = Capacity then 1 else Tail + 1);
            Count := Count + 1;
            Queued_Bytes := Queued_Bytes + Size;
            Accepted := True;
         end if;
      end Publish;

      entry Take (Event : out Greplib.Events.Search_Event; Found : out Boolean)
        when Count > 0 or else Closed or else Cancelled
      is
      begin
         if Count > 0 then
            Event := Buffer (Head);
            Head := (if Head = Capacity then 1 else Head + 1);
            Count := Count - 1;
            Queued_Bytes := Queued_Bytes - Event_Size (Event);
            Found := True;
         else
            Found := False;
         end if;
      end Take;

      procedure Reset is
      begin
         Head := 1;
         Tail := 1;
         Count := 0;
         Queued_Bytes := 0;
         Closed := False;
         Cancelled := False;
      end Reset;

      procedure Close is
      begin
         Closed := True;
      end Close;

      procedure Cancel is
      begin
         Cancelled := True;
      end Cancel;
   end Event_Channel;

   procedure Search_Files_Concurrently
     (Files : String_Vectors.Vector;
      First_Sequence : Source_Sequence;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : in out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token);

   procedure Search_Paths_Concurrently
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : in out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token);

   function Validate
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Options : Directory_Search_Options) return Greplib.Diagnostics.Diagnostic_List
   is
      Result : Greplib.Diagnostics.Diagnostic_List := Greplib.Options.Validate (Search_Options);
   begin
      if Greplib.Paths.Length (Roots) = 0 then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Empty_Root_List,
               Greplib.Diagnostics.Fatal_Error, "empty root list"));
      end if;

      if not Greplib.Patterns.Is_Usable (Patterns) then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
               Greplib.Diagnostics.Fatal_Error, "compiled pattern set is unusable"));
      end if;

      if Options.Worker_Count = 0 or else Options.Worker_Count > Default_Maximum_Worker_Count then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
               Greplib.Diagnostics.Fatal_Error, "invalid directory worker count"));
      end if;

      if Options.Maximum_Queued_Sources = 0 then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
               Greplib.Diagnostics.Fatal_Error, "maximum queued sources must be positive"));
      end if;

      if Options.Maximum_In_Flight_Sources = 0 then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
               Greplib.Diagnostics.Fatal_Error, "maximum in-flight sources must be positive"));
      end if;

      if Options.Maximum_Queued_Events_Per_Source = 0
        or else Options.Maximum_Queued_Events_Per_Source > Wide_Count (Positive'Last)
      then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
               Greplib.Diagnostics.Fatal_Error, "maximum queued events per source is invalid"));
      end if;

      if Options.Maximum_Queued_Event_Bytes_Per_Source = 0 then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
               Greplib.Diagnostics.Fatal_Error, "maximum queued event bytes per source must be positive"));
      end if;

      if Options.Worker_Count > Options.Maximum_In_Flight_Sources then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
               Greplib.Diagnostics.Fatal_Error, "worker count exceeds in-flight source limit"));
      end if;

      if Options.Worker_Count > Options.Maximum_Queued_Sources then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
               Greplib.Diagnostics.Fatal_Error, "worker count exceeds queued source limit"));
      end if;

      if Options.Maximum_Path_Bytes = 0 then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
               Greplib.Diagnostics.Fatal_Error, "maximum path bytes must be positive"));
      end if;

      if Options.Maximum_Directory_Entries = 0 then
         Result.Append
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
               Greplib.Diagnostics.Fatal_Error, "maximum directory entries must be positive"));
      end if;

      return Result;
   end Validate;

   function Validate
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Options : Directory_Search_Options) return Greplib.Diagnostics.Diagnostic_List
   is
      Result : Greplib.Diagnostics.Diagnostic_List := Validate (Roots, Patterns, Search_Options, Options);
   begin
      if not Greplib.Path_Filters.Is_Usable (Filters) then
         declare
            Filter_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
              Greplib.Path_Filters.Diagnostics (Filters);
         begin
            for I in 1 .. Natural (Filter_Diagnostics.Length) loop
               Result.Append (Filter_Diagnostics.Element (I));
            end loop;
         end;
      end if;

      return Result;
   end Validate;

   function Contains (Items : String_Vectors.Vector; Value : String) return Boolean is
   begin
      for Item of Items loop
         if Item = Value then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Source_Limit_Reached
     (Outcome : Greplib.Results.Search_Outcome;
      Options : Directory_Search_Options) return Boolean is
   begin
      return Options.Maximum_Sources /= 0
        and then RE.Wide_Value (Outcome, RE.Files_Accepted_Field) >= Options.Maximum_Sources;
   end Source_Limit_Reached;

   procedure Mark_Source_Limit_If_Reached
     (Outcome : in out Greplib.Results.Search_Outcome;
      Options : Directory_Search_Options) is
   begin
      if Source_Limit_Reached (Outcome, Options)
        and then RE.Status (Outcome) = Greplib.Results.Completed
      then
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Source_Limit_Reached);
      end if;
   end Mark_Source_Limit_If_Reached;

   function Relative_Name (Root : String; Name : String) return String is
      First : Natural := Name'First;
   begin
      if Name'Length >= Root'Length
        and then Name (Name'First .. Name'First + Root'Length - 1) = Root
      then
         First := Name'First + Root'Length;
         if First <= Name'Last and then (Name (First) = '/' or else Name (First) = '\') then
            First := First + 1;
         end if;
      end if;

      if First > Name'Last then
         return "";
      end if;

      declare
         Result : String := Name (First .. Name'Last);
      begin
         for C of Result loop
            if C = '\' then
               C := '/';
            end if;
         end loop;
         return Result;
      end;
   end Relative_Name;

   procedure Sort (Items : in out String_Vectors.Vector) is
   begin
      if Items.Length < 2 then
         return;
      end if;
      for I in Items.First_Index .. Items.Last_Index loop
         for J in I + 1 .. Items.Last_Index loop
            if Items.Element (J) < Items.Element (I) then
               declare
                  T : constant String := Items.Element (I);
               begin
                  Items.Replace_Element (I, Items.Element (J));
                  Items.Replace_Element (J, T);
               end;
            end if;
         end loop;
      end loop;
   end Sort;

   procedure Sort (Items : in out Greplib.Internal.Filesystem.Path_List) is
   begin
      if Items.Length < 2 then
         return;
      end if;
      for I in Items.First_Index .. Items.Last_Index loop
         for J in I + 1 .. Items.Last_Index loop
            if Items.Element (J) < Items.Element (I) then
               declare
                  T : constant String := Items.Element (I);
               begin
                  Items.Replace_Element (I, Items.Element (J));
                  Items.Replace_Element (J, T);
               end;
            end if;
         end loop;
      end loop;
   end Sort;

   procedure Search_One
     (Name : String;
      Root : String;
      Depth : Wide_Count;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : in out Greplib.Results.Search_Outcome;
      Root_Failed : in out Boolean;
      Cancellation : Greplib.Cancellation.Cancellation_Token;
      Root_Identity : Greplib.Internal.Filesystem_Identity.Object_Identity :=
        Greplib.Internal.Filesystem_Identity.Unavailable;
      Collected_Files : access String_Vectors.Vector := null;
      Acceptor : access Source_Acceptor'Class := null;
      Ancestors : in out String_Vectors.Vector)
   is
      Kind : Greplib.Internal.Filesystem.Entry_Kind;
      Base : constant String := Greplib.Internal.Filesystem.Simple_Name (Name);
      Relative : constant String := Relative_Name (Root, Name);
      Is_Link : constant Boolean := Greplib.Internal.Filesystem.Is_Symbolic_Link (Name);
      Follow_Link : constant Boolean :=
        not Is_Link
        or else Directory_Options.Symbolic_Links = Follow_All
        or else (Directory_Options.Symbolic_Links = Follow_Explicit_Roots and then Depth = 0);

      procedure Add_Traversal_Diagnostic (Item : Greplib.Diagnostics.Diagnostic) is
      begin
         Add_Diagnostic (Outcome, Item, Search_Options);
         if Directory_Options.Traversal_Errors = Fail_Root then
            Root_Failed := True;
         end if;
      end Add_Traversal_Diagnostic;

      procedure Flush_Collected_Files is
         First : Source_Sequence;
      begin
         if Collected_Files = null or else Collected_Files.Is_Empty then
            return;
         end if;

         First :=
           Source_Sequence
             (RE.Wide_Value (Outcome, RE.Files_Accepted_Field) - Wide_Count (Collected_Files.Length) + 1);
         Search_Files_Concurrently
           (Collected_Files.all, First, Patterns, Search_Options, Directory_Options,
            Sink, Outcome, Cancellation);
         Collected_Files.Clear;
      end Flush_Collected_Files;
   begin
      if Greplib.Cancellation.Is_Requested (Cancellation) then
         RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
         RE.Set_Cancellation_Observed (Edit_Key, Outcome, True);
         RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Cancellation_Requested);
         return;
      end if;

      if Byte_Count (Name'Length) > Directory_Options.Maximum_Path_Bytes then
         Add_Traversal_Diagnostic
           (Greplib.Diagnostics.Make
              (Greplib.Diagnostics.Resource_Path_Limit_Exceeded,
               Traversal_Severity (Directory_Options), Name,
               Path => Name,
               Has_Numeric_Limit => True,
               Numeric_Limit => Directory_Options.Maximum_Path_Bytes,
               Has_Observed_Size => True,
               Observed_Size => Wide_Count (Name'Length)));
         return;
      end if;

      if Is_Link then
         RE.Add_Wide (Edit_Key, Outcome, RE.Links_Encountered_Field);
      end if;

      begin
         Kind := Greplib.Internal.Filesystem.Kind (Name);
      exception
         when E : others =>
              Add_Traversal_Diagnostic
                (Greplib.Diagnostics.Make
                   (Greplib.Diagnostics.Filesystem_Open_Failed,
                    Traversal_Severity (Directory_Options), Name,
                    Path => Name,
                    Filesystem_Operation => "classify",
                    Exception_Name => Ada.Exceptions.Exception_Name (E),
                    Exception_Message => Ada.Exceptions.Exception_Message (E)));
            return;
      end;

      if Is_Link and then not Follow_Link then
         if Kind = Greplib.Internal.Filesystem.Directory then
            RE.Add_Wide (Edit_Key, Outcome, RE.Directories_Skipped_Field);
         else
            RE.Add_Wide (Edit_Key, Outcome, RE.Files_Filtered_Field);
         end if;
         return;
      elsif Is_Link then
         RE.Add_Wide (Edit_Key, Outcome, RE.Links_Followed_Field);
      end if;

      if Kind = Greplib.Internal.Filesystem.Ordinary_File then
         if not Directory_Options.Search_Regular_Files then
            RE.Add_Wide (Edit_Key, Outcome, RE.Files_Filtered_Field);
            return;
         end if;

         if not Greplib.Path_Filters.Included (Filters, Base, Relative, False) then
            RE.Add_Wide (Edit_Key, Outcome, RE.Files_Filtered_Field);
            return;
         end if;

         if Source_Limit_Reached (Outcome, Directory_Options) then
            RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Source_Limit_Reached);
            return;
         end if;

         RE.Add_Wide (Edit_Key, Outcome, RE.Files_Accepted_Field);
         Mark_Source_Limit_If_Reached (Outcome, Directory_Options);
         if Acceptor /= null then
            Acceptor.Accept_Source (Name, Source_Sequence (RE.Wide_Value (Outcome, RE.Files_Accepted_Field)));
            return;
         end if;
         if Collected_Files /= null then
            Collected_Files.Append (Name);
            if Wide_Count (Collected_Files.Length) >= Directory_Options.Maximum_Queued_Sources then
               Flush_Collected_Files;
            end if;
            return;
         end if;

         declare
            O : Greplib.Results.Search_Outcome;
         begin
            Greplib.Files.Search_File
              (Greplib.Paths.To_Path (Name), Patterns, Search_Options, Sink, O,
               Cancellation, Source_Sequence (RE.Wide_Value (Outcome, RE.Files_Accepted_Field)));
            Merge_Source_Outcome (Outcome, O, Search_Options);
            if Search_Options.Mode = Greplib.Options.Quiet
              and then RE.Wide_Value (O, RE.Sources_With_Results_Field) > 0
            then
               RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Quiet_Match_Found);
            end if;
         end;
      elsif Kind = Greplib.Internal.Filesystem.Directory and then (Directory_Options.Recursive or else Depth = 0) then
         if Depth /= 0 and then not Greplib.Path_Filters.Included (Filters, Base, Relative, True) then
            RE.Add_Wide (Edit_Key, Outcome, RE.Directories_Skipped_Field);
            return;
         end if;

         if Depth > 0 and then Depth >= Directory_Options.Maximum_Depth then
            RE.Add_Wide (Edit_Key, Outcome, RE.Directories_Skipped_Field);
            Add_Traversal_Diagnostic
              (Greplib.Diagnostics.Make
                 (Greplib.Diagnostics.Traversal_Maximum_Depth_Exceeded,
                  Traversal_Severity (Directory_Options), Name,
                  Path => Name,
                  Has_Numeric_Limit => True,
                  Numeric_Limit => Directory_Options.Maximum_Depth,
                  Has_Observed_Size => True,
                  Observed_Size => Depth));
            return;
         end if;

         declare
            Names : Greplib.Internal.Filesystem.Path_List;
            Entries_Examined : Wide_Count := 0;
            Limit_Exceeded : Boolean := False;
            Object_Id : constant Greplib.Internal.Filesystem_Identity.Object_Identity :=
              Greplib.Internal.Filesystem_Identity.Read (Name);
            Identity : constant String :=
              (if Greplib.Internal.Filesystem_Identity.Is_Available (Object_Id)
               then "S" & Greplib.Internal.Filesystem_Identity.Image (Object_Id)
               else "P" & Greplib.Internal.Filesystem.Normalized_Identity (Name));
         begin
            if Directory_Options.Stay_On_Starting_Filesystem
              and then Depth > 0
              and then not Greplib.Internal.Filesystem_Identity.Same_Filesystem (Root_Identity, Object_Id)
            then
               RE.Add_Wide (Edit_Key, Outcome, RE.Directories_Skipped_Field);
               RE.Add_Wide (Edit_Key, Outcome, RE.Filesystem_Boundaries_Skipped_Field);
               Add_Traversal_Diagnostic
                 (Greplib.Diagnostics.Make
                    (Greplib.Diagnostics.Traversal_Filesystem_Boundary_Skipped,
                     Traversal_Severity (Directory_Options), Name,
                     Path => Name,
                     Filesystem_Operation => "same-filesystem"));
               return;
            end if;

            if Identity = "P" or else Contains (Ancestors, Identity) then
               RE.Add_Wide (Edit_Key, Outcome, RE.Cycles_Detected_Field);
               RE.Add_Wide (Edit_Key, Outcome, RE.Directories_Skipped_Field);
               Add_Traversal_Diagnostic
                 (Greplib.Diagnostics.Make
                    (Greplib.Diagnostics.Traversal_Cycle_Detected,
                     Traversal_Severity (Directory_Options), Name,
                     Path => Name,
                     Filesystem_Operation => "descend"));
               return;
            end if;

            Ancestors.Append (Identity);
            RE.Add_Wide (Edit_Key, Outcome, RE.Directories_Visited_Field);
            begin
               Greplib.Internal.Filesystem.Collect_Children
                 (Name, Directory_Options.Include_Hidden, Directory_Options.Maximum_Directory_Entries,
                  Names, Entries_Examined, Limit_Exceeded);
               RE.Add_Wide (Edit_Key, Outcome, RE.Entries_Examined_Field, Entries_Examined);
               if Greplib.Cancellation.Is_Requested (Cancellation) then
                  RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
                  RE.Set_Cancellation_Observed (Edit_Key, Outcome, True);
                  RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Cancellation_Requested);
                  Ancestors.Delete_Last;
                  return;
               elsif Limit_Exceeded then
                  Add_Traversal_Diagnostic
                    (Greplib.Diagnostics.Make
                       (Greplib.Diagnostics.Resource_Directory_Entry_Limit_Exceeded,
                        Traversal_Severity (Directory_Options), Name,
                        Path => Name,
                        Filesystem_Operation => "enumerate",
                        Has_Numeric_Limit => True,
                        Numeric_Limit => Directory_Options.Maximum_Directory_Entries,
                        Has_Observed_Size => True,
                        Observed_Size => RE.Wide_Value (Outcome, RE.Entries_Examined_Field)));
                  Ancestors.Delete_Last;
                  return;
               end if;
            exception
               when E : others =>
                  Add_Traversal_Diagnostic
                    (Greplib.Diagnostics.Make
                       (Greplib.Diagnostics.Filesystem_Open_Failed,
                        Traversal_Severity (Directory_Options), Name,
                        Path => Name,
                        Filesystem_Operation => "enumerate",
                        Exception_Name => Ada.Exceptions.Exception_Name (E),
                        Exception_Message => Ada.Exceptions.Exception_Message (E)));
                  Ancestors.Delete_Last;
                  return;
            end;

            if Directory_Options.Deterministic_Order then
               Sort (Names);
            end if;
            for Child of Names loop
               Search_One
                 (Child, Root, Depth + 1, Patterns, Filters, Search_Options, Directory_Options,
                  Sink, Outcome, Root_Failed, Cancellation, Root_Identity, Collected_Files,
                  Acceptor, Ancestors);
               exit when RE.Status (Outcome) = Greplib.Results.Cancelled
                 or else RE.Status (Outcome) = Greplib.Results.Failed
                 or else Root_Failed
                 or else RE.Reason (Outcome) = Greplib.Results.Quiet_Match_Found
                 or else RE.Reason (Outcome) = Greplib.Results.Source_Limit_Reached;
            end loop;
            Ancestors.Delete_Last;
         end;
      elsif Kind = Greplib.Internal.Filesystem.Special_File then
         if not Directory_Options.Search_Special_Files then
            RE.Add_Wide (Edit_Key, Outcome, RE.Files_Filtered_Field);
            return;
         end if;

         if not Greplib.Path_Filters.Included (Filters, Base, Relative, False) then
            RE.Add_Wide (Edit_Key, Outcome, RE.Files_Filtered_Field);
            return;
         end if;

         if Source_Limit_Reached (Outcome, Directory_Options) then
            RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Source_Limit_Reached);
            return;
         end if;

         RE.Add_Wide (Edit_Key, Outcome, RE.Files_Accepted_Field);
         Mark_Source_Limit_If_Reached (Outcome, Directory_Options);
         if Acceptor /= null then
            Acceptor.Accept_Source (Name, Source_Sequence (RE.Wide_Value (Outcome, RE.Files_Accepted_Field)));
            return;
         end if;
         if Collected_Files /= null then
            Collected_Files.Append (Name);
            if Wide_Count (Collected_Files.Length) >= Directory_Options.Maximum_Queued_Sources then
               Flush_Collected_Files;
            end if;
            return;
         end if;

         declare
            O : Greplib.Results.Search_Outcome;
         begin
            Greplib.Files.Search_File
              (Greplib.Paths.To_Path (Name), Patterns, Search_Options, Sink, O,
               Cancellation, Source_Sequence (RE.Wide_Value (Outcome, RE.Files_Accepted_Field)));
            Merge_Source_Outcome (Outcome, O, Search_Options);
            if Search_Options.Mode = Greplib.Options.Quiet
              and then RE.Wide_Value (O, RE.Sources_With_Results_Field) > 0
            then
               RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Quiet_Match_Found);
            end if;
         end;
      elsif Kind = Greplib.Internal.Filesystem.Directory then
         RE.Add_Wide (Edit_Key, Outcome, RE.Directories_Skipped_Field);
      end if;
   end Search_One;

   procedure Search_Files_Concurrently
     (Files : String_Vectors.Vector;
      First_Sequence : Source_Sequence;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : in out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token)
   is
      use type Greplib.Events.Event_Action;
      Worker_Total : constant Natural :=
        Natural'Min (Natural (Directory_Options.Worker_Count), Natural (Files.Length));
   begin
      if Files.Is_Empty then
         return;
      end if;

      declare
         Channel_Capacity : constant Positive := Positive (Directory_Options.Maximum_Queued_Events_Per_Source);
         Channel_Bytes : constant Byte_Count := Directory_Options.Maximum_Queued_Event_Bytes_Per_Source;
         type Channel_Array is array (Positive range <>) of aliased Event_Channel (Channel_Capacity, Channel_Bytes);
         type Natural_Array is array (Positive range <>) of Natural;
         Results : Source_Result_Array (Files.First_Index .. Files.Last_Index);
         Channels : aliased Channel_Array (Files.First_Index .. Files.Last_Index);
         Source_Queue_Capacity : constant Positive :=
           Positive'Min (Positive (Directory_Options.Maximum_Queued_Sources), Positive (Files.Length));
         Internal_Cancellation : aliased Greplib.Cancellation.Cancellation_Source;
         Effective_Cancellation : constant Greplib.Cancellation.Cancellation_Token :=
           Greplib.Cancellation.Combine
             (Cancellation, Greplib.Cancellation.Token (Internal_Cancellation));
         Stop_All : Boolean := False;

         type Channel_Sink is new Greplib.Events.Event_Sink with record
            Channel : access Event_Channel;
         end record;

         overriding procedure On_Event
           (Sink : in out Channel_Sink;
            Event : Greplib.Events.Search_Event;
            Action : out Greplib.Events.Event_Action);

         overriding procedure On_Event
           (Sink : in out Channel_Sink;
            Event : Greplib.Events.Search_Event;
            Action : out Greplib.Events.Event_Action) is
            Accepted : Boolean;
         begin
            Sink.Channel.Publish (Event, Event_Size (Event), Accepted);
            Action := (if Accepted then Greplib.Events.Continue_Search else Greplib.Events.Stop_Current_Source);
         end On_Event;

         protected type Source_Queue_Type (Capacity : Positive) is
            entry Enqueue (Index : Natural);
            entry Take (Index : out Natural; Found : out Boolean);
            procedure Close;
            procedure Cancel;
         private
            Buffer : Natural_Array (1 .. Capacity) := (others => 0);
            Head : Positive := 1;
            Tail : Positive := 1;
            Count : Natural := 0;
            Closed : Boolean := False;
            Cancelled : Boolean := False;
         end Source_Queue_Type;

         protected body Source_Queue_Type is
            entry Enqueue (Index : Natural) when Count < Buffer'Length or else Cancelled is
            begin
               if not Cancelled then
                  Buffer (Tail) := Index;
                  Tail := (if Tail = Buffer'Last then Buffer'First else Tail + 1);
                  Count := Count + 1;
               end if;
            end Enqueue;

            entry Take (Index : out Natural; Found : out Boolean)
              when Count > 0 or else Closed or else Cancelled
            is
            begin
               if Count > 0 then
                  Index := Buffer (Head);
                  Head := (if Head = Buffer'Last then Buffer'First else Head + 1);
                  Count := Count - 1;
                  Found := True;
               else
                  Index := 0;
                  Found := False;
               end if;
            end Take;

            procedure Close is
            begin
               Closed := True;
            end Close;

            procedure Cancel is
            begin
               Cancelled := True;
            end Cancel;
         end Source_Queue_Type;

         Source_Queue : Source_Queue_Type (Source_Queue_Capacity);

         protected Ready_Sources is
            entry Publish (Index : Natural);
            entry Take (Index : out Natural);
            procedure Cancel;
         private
            Buffer : Natural_Array (Files.First_Index .. Files.Last_Index) := (others => 0);
            Head : Natural := Files.First_Index;
            Tail : Natural := Files.First_Index;
            Count : Natural := 0;
            Cancelled : Boolean := False;
         end Ready_Sources;

         protected body Ready_Sources is
            entry Publish (Index : Natural) when Count < Buffer'Length or else Cancelled is
            begin
               if not Cancelled then
                  Buffer (Tail) := Index;
                  Tail := (if Tail = Buffer'Last then Buffer'First else Tail + 1);
                  Count := Count + 1;
               end if;
            end Publish;

            entry Take (Index : out Natural) when Count > 0 or else Cancelled is
            begin
               if Cancelled and then Count = 0 then
                  Index := 0;
               else
                  Index := Buffer (Head);
                  Head := (if Head = Buffer'Last then Buffer'First else Head + 1);
                  Count := Count - 1;
               end if;
            end Take;

            procedure Cancel is
            begin
               Cancelled := True;
            end Cancel;
         end Ready_Sources;

         procedure Cancel_All_Channels is
         begin
            Source_Queue.Cancel;
            Ready_Sources.Cancel;
            Internal_Cancellation.Request;
            for J in Channels'Range loop
               Channels (J).Cancel;
            end loop;
         end Cancel_All_Channels;

         procedure Deliver_Source (I : Positive) is
            Stop_Current : Boolean := False;
            Delivered_Selected : Wide_Count := 0;
            Delivered_Result : Boolean := False;
            Event : Greplib.Events.Search_Event;
            Found : Boolean;
         begin
            loop
               Channels (I).Take (Event, Found);
               exit when not Found or else Stop_Current or else Stop_All;
               if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record
                 or else Greplib.Events.Kind (Event) = Greplib.Events.Binary_Match
               then
                  Delivered_Selected := Delivered_Selected + 1;
                  Delivered_Result := True;
               elsif Greplib.Events.Kind (Event) = Greplib.Events.Source_Name_Result
                 and then Greplib.Events.Had_Match (Event)
               then
                  Delivered_Result := True;
               end if;

               declare
                  Action : Greplib.Events.Event_Action;
               begin
                  Sink.On_Event (Event, Action);
                  case Action is
                     when Greplib.Events.Continue_Search =>
                        null;
                     when Greplib.Events.Stop_Current_Source =>
                        Stop_Current := True;
                        Channels (I).Cancel;
                     when Greplib.Events.Stop_All_Search =>
                        Stop_All := True;
                        Cancel_All_Channels;
                  end case;
               end;
            end loop;

            if Stop_Current or else Stop_All then
               RE.Set_Wide (Edit_Key, Results (I).Outcome, RE.Selected_Record_Count_Field, Delivered_Selected);
               RE.Set_Wide
                 (Edit_Key, Results (I).Outcome, RE.Sources_With_Results_Field,
                  (if Delivered_Result then 1 else 0));
               RE.Set_Wide (Edit_Key, Results (I).Outcome, RE.Sources_Completed_Field, 0);
               if Stop_All then
                  RE.Set_Status (Edit_Key, Results (I).Outcome, Greplib.Results.Cancelled);
                  RE.Set_Cancellation_Observed (Edit_Key, Results (I).Outcome, True);
                  RE.Set_Reason (Edit_Key, Results (I).Outcome, Greplib.Results.Callback_Stopped_Search);
               else
                  RE.Set_Status (Edit_Key, Results (I).Outcome, Greplib.Results.Completed);
                  RE.Set_Reason (Edit_Key, Results (I).Outcome, Greplib.Results.Callback_Stopped_Source);
               end if;
            end if;

            Merge_Source_Outcome (Outcome, Results (I).Outcome, Search_Options);
            if Search_Options.Mode = Greplib.Options.Quiet
              and then RE.Wide_Value (Results (I).Outcome, RE.Sources_With_Results_Field) > 0
            then
               RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Quiet_Match_Found);
            end if;

            if Stop_All then
               RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
               RE.Set_Cancellation_Observed (Edit_Key, Outcome, True);
               RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Callback_Stopped_Search);
            end if;
         end Deliver_Source;

         task Producer;

         task body Producer is
         begin
            for I in Files.First_Index .. Files.Last_Index loop
               exit when Stop_All;
               Source_Queue.Enqueue (I);
            end loop;
            Source_Queue.Close;
         exception
            when others =>
               Internal_Cancellation.Request;
               Source_Queue.Cancel;
               Ready_Sources.Cancel;
         end Producer;

         task type Worker;

         task body Worker is
            Index : Natural;
            Found : Boolean;
         begin
            loop
               Source_Queue.Take (Index, Found);
               exit when not Found;

               declare
                  Local_Sink : Channel_Sink := (Channel => Channels (Index)'Access);
               begin
                  Ready_Sources.Publish (Index);
                  Greplib.Files.Search_File
                    (Greplib.Paths.To_Path (Files.Element (Index)), Patterns, Search_Options,
                     Local_Sink, Results (Index).Outcome, Effective_Cancellation,
                     Source_Sequence
                       (Wide_Count (First_Sequence) + Wide_Count (Index - Files.First_Index)));
               exception
                  when others =>
                     declare
                        Accepted : Boolean;
                        D : constant Greplib.Diagnostics.Diagnostic :=
                          Greplib.Diagnostics.Make
                            (Greplib.Diagnostics.Internal_Invariant_Failure,
                             Greplib.Diagnostics.Fatal_Error,
                             "concurrent worker failed");
                     begin
                        RE.Set_Status (Edit_Key, Results (Index).Outcome, Greplib.Results.Failed);
                        RE.Set_Reason (Edit_Key, Results (Index).Outcome, Greplib.Results.Fatal_Error);
                        RE.Set_Wide (Edit_Key, Results (Index).Outcome, RE.Diagnostic_Count_Field, 1);
                        RE.Append_Diagnostic (Edit_Key, Results (Index).Outcome, D);
                        RE.Append_Source_Summary
                          (Edit_Key,
                           Results (Index).Outcome,
                           Greplib.Sources.Building.Make
                             (Edit_Key,
                              Greplib.Sources.File_Source,
                              Source_Sequence
                                (Wide_Count (First_Sequence) + Wide_Count (Index - Files.First_Index)),
                              Greplib.Paths.To_Path (Files.Element (Index))));
                        Channels (Index).Publish
                          (EB.Make_Diagnostic
                             (Edit_Key, Greplib.Paths.To_Path (Files.Element (Index)), D,
                              Source_Sequence
                                (Wide_Count (First_Sequence) + Wide_Count (Index - Files.First_Index))),
                           1,
                           Accepted);
                     end;
               end;
               Channels (Index).Close;
            end loop;
         end Worker;

         Workers : array (1 .. Worker_Total) of Worker;
         pragma Unreferenced (Workers);
      begin
         if Search_Options.Order = Greplib.Options.Completion_Order then
            for Delivered in 1 .. Natural (Files.Length) loop
               declare
                  I : Natural;
               begin
                  exit when Stop_All;
                  Ready_Sources.Take (I);
                  exit when I = 0;
                  Deliver_Source (I);
               end;
            end loop;
         else
            for I in Channels'Range loop
               exit when Stop_All;
               Deliver_Source (I);
            end loop;
         end if;
      end;
   end Search_Files_Concurrently;

   procedure Search_Paths_Concurrently
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : in out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token)
   is
      use type Greplib.Events.Event_Action;
      Slot_Count : constant Positive := Positive (Directory_Options.Maximum_In_Flight_Sources);
      Queue_Capacity : constant Positive := Positive (Directory_Options.Maximum_Queued_Sources);
      Worker_Total : constant Positive := Positive (Directory_Options.Worker_Count);
      Channel_Capacity : constant Positive := Positive (Directory_Options.Maximum_Queued_Events_Per_Source);
      Channel_Bytes : constant Byte_Count := Directory_Options.Maximum_Queued_Event_Bytes_Per_Source;
      type Channel_Array is array (Positive range <>) of aliased Event_Channel (Channel_Capacity, Channel_Bytes);
      type Natural_Array is array (Positive range <>) of Natural;
      type Boolean_Array is array (Positive range <>) of Boolean;
      type Sequence_Array is array (Positive range <>) of Source_Sequence;
      type Path_Array is array (Positive range <>) of U.Unbounded_String;

      Traversal_Outcome : Greplib.Results.Search_Outcome;
      Results : Source_Result_Array (1 .. Slot_Count);
      Channels : aliased Channel_Array (1 .. Slot_Count);
      Slot_Paths : Path_Array (1 .. Slot_Count);
      Slot_Sequences : Sequence_Array (1 .. Slot_Count) := (others => 1);
      Internal_Cancellation : aliased Greplib.Cancellation.Cancellation_Source;
      Effective_Cancellation : constant Greplib.Cancellation.Cancellation_Token :=
        Greplib.Cancellation.Combine (Cancellation, Greplib.Cancellation.Token (Internal_Cancellation));
      Stop_All : Boolean := False;

      type Channel_Sink is new Greplib.Events.Event_Sink with record
         Channel : access Event_Channel;
      end record;

      overriding procedure On_Event
        (Sink : in out Channel_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);

      overriding procedure On_Event
        (Sink : in out Channel_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
         Accepted : Boolean;
      begin
         Sink.Channel.Publish (Event, Event_Size (Event), Accepted);
         Action := (if Accepted then Greplib.Events.Continue_Search else Greplib.Events.Stop_Current_Source);
      end On_Event;

      protected Free_Slots is
         entry Acquire (Slot : out Natural; Found : out Boolean);
         procedure Release (Slot : Natural);
         procedure Cancel;
      private
         Free : Natural_Array (1 .. Slot_Count) := (others => 0);
         Free_Count : Natural := 0;
         Next_New : Natural := 1;
         Cancelled : Boolean := False;
      end Free_Slots;

      protected body Free_Slots is
         entry Acquire (Slot : out Natural; Found : out Boolean)
           when Cancelled or else Free_Count > 0 or else Next_New <= Slot_Count
         is
         begin
            if Cancelled then
               Slot := 0;
               Found := False;
            elsif Free_Count > 0 then
               Slot := Free (Free_Count);
               Free_Count := Free_Count - 1;
               Found := True;
            else
               Slot := Next_New;
               Next_New := Next_New + 1;
               Found := True;
            end if;
         end Acquire;

         procedure Release (Slot : Natural) is
         begin
            if not Cancelled and then Slot /= 0 then
               Free_Count := Free_Count + 1;
               Free (Free_Count) := Slot;
            end if;
         end Release;

         procedure Cancel is
         begin
            Cancelled := True;
         end Cancel;
      end Free_Slots;

      protected Source_Queue is
         entry Enqueue (Slot : Natural; Accepted : out Boolean);
         entry Take (Slot : out Natural; Found : out Boolean);
         procedure Close;
         procedure Cancel;
      private
         Buffer : Natural_Array (1 .. Queue_Capacity) := (others => 0);
         Head : Positive := 1;
         Tail : Positive := 1;
         Count : Natural := 0;
         Closed : Boolean := False;
         Cancelled : Boolean := False;
      end Source_Queue;

      protected body Source_Queue is
         entry Enqueue (Slot : Natural; Accepted : out Boolean) when Count < Buffer'Length or else Cancelled is
         begin
            if Cancelled then
               Accepted := False;
            else
               Buffer (Tail) := Slot;
               Tail := (if Tail = Buffer'Last then Buffer'First else Tail + 1);
               Count := Count + 1;
               Accepted := True;
            end if;
         end Enqueue;

         entry Take (Slot : out Natural; Found : out Boolean)
           when Count > 0 or else Closed or else Cancelled
         is
         begin
            if Count > 0 then
               Slot := Buffer (Head);
               Head := (if Head = Buffer'Last then Buffer'First else Head + 1);
               Count := Count - 1;
               Found := True;
            else
               Slot := 0;
               Found := False;
            end if;
         end Take;

         procedure Close is
         begin
            Closed := True;
         end Close;

         procedure Cancel is
         begin
            Cancelled := True;
         end Cancel;
      end Source_Queue;

      protected Slot_States is
         procedure Assign (Slot : Natural; Sequence : Source_Sequence);
         procedure Mark_Queued (Slot : Natural);
         procedure Complete (Slot : Natural);
         entry Take_Next_Assigned (Slot : out Natural; Found : out Boolean);
         entry Take_Ready (Slot : out Natural);
         procedure Release (Slot : Natural);
         procedure Producer_Closed;
         procedure Cancel;
      private
         Assigned : Boolean_Array (1 .. Slot_Count) := (others => False);
         Queued : Boolean_Array (1 .. Slot_Count) := (others => False);
         Completed : Boolean_Array (1 .. Slot_Count) := (others => False);
         Sequences : Sequence_Array (1 .. Slot_Count) := (others => 1);
         Ready_Buffer : Natural_Array (1 .. Slot_Count) := (others => 0);
         Ready_Head : Positive := 1;
         Ready_Tail : Positive := 1;
         Ready_Count : Natural := 0;
         Active_Count : Natural := 0;
         Next_Delivery_Sequence : Source_Sequence := 1;
         Producer_Done : Boolean := False;
         Cancelled : Boolean := False;

         function Has_Sequence (Sequence : Source_Sequence) return Boolean;
      end Slot_States;

      protected body Slot_States is
         function Has_Sequence (Sequence : Source_Sequence) return Boolean is
         begin
            for I in Assigned'Range loop
               if Assigned (I) and then Queued (I) and then Sequences (I) = Sequence then
                  return True;
               end if;
            end loop;
            return False;
         end Has_Sequence;

         procedure Assign (Slot : Natural; Sequence : Source_Sequence) is
         begin
            if not Cancelled and then Slot /= 0 then
               Assigned (Slot) := True;
               Queued (Slot) := False;
               Completed (Slot) := False;
               Sequences (Slot) := Sequence;
               Active_Count := Active_Count + 1;
            end if;
         end Assign;

         procedure Mark_Queued (Slot : Natural) is
         begin
            if not Cancelled and then Slot /= 0 and then Assigned (Slot) then
               Queued (Slot) := True;
               Ready_Buffer (Ready_Tail) := Slot;
               Ready_Tail := (if Ready_Tail = Ready_Buffer'Last then 1 else Ready_Tail + 1);
               Ready_Count := Ready_Count + 1;
            end if;
         end Mark_Queued;

         procedure Complete (Slot : Natural) is
         begin
            if not Cancelled and then Slot /= 0 and then Assigned (Slot) and then not Completed (Slot) then
               Completed (Slot) := True;
               null;
            end if;
         end Complete;

         entry Take_Next_Assigned (Slot : out Natural; Found : out Boolean)
           when Cancelled or else Producer_Done or else Has_Sequence (Next_Delivery_Sequence)
         is
         begin
            if Cancelled then
               Slot := 0;
               Found := False;
            else
               Slot := 0;
               Found := False;
               for I in Assigned'Range loop
                  if Assigned (I) and then Queued (I) and then Sequences (I) = Next_Delivery_Sequence then
                     Slot := I;
                     Found := True;
                     Next_Delivery_Sequence := Next_Delivery_Sequence + 1;
                     exit;
                  end if;
               end loop;
            end if;
         end Take_Next_Assigned;

         entry Take_Ready (Slot : out Natural)
           when Ready_Count > 0 or else Cancelled or else (Producer_Done and then Active_Count = 0)
         is
         begin
            if Ready_Count > 0 then
               Slot := Ready_Buffer (Ready_Head);
               Ready_Head := (if Ready_Head = Ready_Buffer'Last then 1 else Ready_Head + 1);
               Ready_Count := Ready_Count - 1;
            else
               Slot := 0;
            end if;
         end Take_Ready;

         procedure Release (Slot : Natural) is
         begin
            if Slot /= 0 and then Assigned (Slot) then
               Assigned (Slot) := False;
               Queued (Slot) := False;
               Completed (Slot) := False;
               Active_Count := Active_Count - 1;
            end if;
         end Release;

         procedure Producer_Closed is
         begin
            Producer_Done := True;
         end Producer_Closed;

         procedure Cancel is
         begin
            Cancelled := True;
         end Cancel;
      end Slot_States;

      procedure Cancel_All is
      begin
         Source_Queue.Cancel;
         Free_Slots.Cancel;
         Slot_States.Cancel;
         Internal_Cancellation.Request;
         for J in Channels'Range loop
            Channels (J).Cancel;
         end loop;
      end Cancel_All;

      type Live_Acceptor is new Source_Acceptor with null record;
      overriding procedure Accept_Source
        (Acceptor : in out Live_Acceptor;
         Name : String;
         Sequence : Source_Sequence);

      overriding procedure Accept_Source
        (Acceptor : in out Live_Acceptor;
         Name : String;
         Sequence : Source_Sequence)
      is
         pragma Unreferenced (Acceptor);
         Slot : Natural;
         Found : Boolean;
         Accepted : Boolean;
      begin
         Free_Slots.Acquire (Slot, Found);
         if not Found then
            return;
         end if;

         Channels (Slot).Reset;
         Slot_Paths (Slot) := U.To_Unbounded_String (Name);
         Slot_Sequences (Slot) := Sequence;
         RE.Reset (Edit_Key, Results (Slot).Outcome);
         Slot_States.Assign (Slot, Sequence);
         Source_Queue.Enqueue (Slot, Accepted);
         if Accepted then
            Slot_States.Mark_Queued (Slot);
         else
            Slot_States.Release (Slot);
            Free_Slots.Release (Slot);
         end if;
      end Accept_Source;

      procedure Deliver_Source (Slot : Positive) is
         Stop_Current : Boolean := False;
         Delivered_Selected : Wide_Count := 0;
         Delivered_Result : Boolean := False;
         Event : Greplib.Events.Search_Event;
         Found : Boolean;
      begin
         loop
            Channels (Slot).Take (Event, Found);
            exit when not Found or else Stop_Current or else Stop_All;
            if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record
              or else Greplib.Events.Kind (Event) = Greplib.Events.Binary_Match
            then
               Delivered_Selected := Delivered_Selected + 1;
               Delivered_Result := True;
            elsif Greplib.Events.Kind (Event) = Greplib.Events.Source_Name_Result
              and then Greplib.Events.Had_Match (Event)
            then
               Delivered_Result := True;
            end if;

            declare
               Action : Greplib.Events.Event_Action;
            begin
               Sink.On_Event (Event, Action);
               case Action is
                  when Greplib.Events.Continue_Search =>
                     null;
                  when Greplib.Events.Stop_Current_Source =>
                     Stop_Current := True;
                     Channels (Slot).Cancel;
                  when Greplib.Events.Stop_All_Search =>
                     Stop_All := True;
                     Cancel_All;
               end case;
            end;
         end loop;

         if Stop_Current or else Stop_All then
            RE.Set_Wide (Edit_Key, Results (Slot).Outcome, RE.Selected_Record_Count_Field, Delivered_Selected);
            RE.Set_Wide
              (Edit_Key, Results (Slot).Outcome, RE.Sources_With_Results_Field,
               (if Delivered_Result then 1 else 0));
            RE.Set_Wide (Edit_Key, Results (Slot).Outcome, RE.Sources_Completed_Field, 0);
            if Stop_All then
               RE.Set_Status (Edit_Key, Results (Slot).Outcome, Greplib.Results.Cancelled);
               RE.Set_Cancellation_Observed (Edit_Key, Results (Slot).Outcome, True);
               RE.Set_Reason (Edit_Key, Results (Slot).Outcome, Greplib.Results.Callback_Stopped_Search);
            else
               RE.Set_Status (Edit_Key, Results (Slot).Outcome, Greplib.Results.Completed);
               RE.Set_Reason (Edit_Key, Results (Slot).Outcome, Greplib.Results.Callback_Stopped_Source);
            end if;
         end if;

         Merge_Source_Outcome (Outcome, Results (Slot).Outcome, Search_Options);
         if Search_Options.Mode = Greplib.Options.Quiet
           and then RE.Wide_Value (Results (Slot).Outcome, RE.Sources_With_Results_Field) > 0
         then
            RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Quiet_Match_Found);
            Stop_All := True;
            Cancel_All;
         end if;

         Slot_States.Release (Slot);
         Free_Slots.Release (Slot);

         if Stop_All then
            RE.Set_Status (Edit_Key, Outcome, Greplib.Results.Cancelled);
            RE.Set_Cancellation_Observed (Edit_Key, Outcome, True);
            RE.Set_Reason (Edit_Key, Outcome, Greplib.Results.Callback_Stopped_Search);
         end if;
      end Deliver_Source;

      task Traversal_Producer;

      task body Traversal_Producer is
         Acceptor : aliased Live_Acceptor;
      begin
         for I in 1 .. Greplib.Paths.Length (Roots) loop
            declare
               Root : constant String := Greplib.Paths.Image (Greplib.Paths.Element (Roots, I));
               Root_Failed : Boolean := False;
               Ancestors : String_Vectors.Vector;
               Root_Identity : constant Greplib.Internal.Filesystem_Identity.Object_Identity :=
                 Greplib.Internal.Filesystem_Identity.Read (Root);
            begin
               RE.Add_Wide (Edit_Key, Traversal_Outcome, RE.Roots_Considered_Field);
               if Directory_Options.Stay_On_Starting_Filesystem
                 and then not Greplib.Internal.Filesystem_Identity.Is_Available (Root_Identity)
               then
                  Add_Diagnostic
                    (Traversal_Outcome,
                     Greplib.Diagnostics.Make
                       (Greplib.Diagnostics.Filesystem_Open_Failed,
                        Traversal_Severity (Directory_Options),
                        Root,
                        Path => Root,
                        Filesystem_Operation => "read-root-filesystem"),
                     Search_Options);
                  Root_Failed := Directory_Options.Traversal_Errors = Fail_Root;
               else
                  Search_One
                    (Root, Root, 0, Patterns, Filters, Search_Options,
                     Directory_Options, Sink, Traversal_Outcome, Root_Failed,
                     Effective_Cancellation, Root_Identity, null, Acceptor'Access,
                     Ancestors);
               end if;
               exit when RE.Status (Traversal_Outcome) = Greplib.Results.Cancelled
                 or else RE.Status (Traversal_Outcome) = Greplib.Results.Failed
                 or else Root_Failed
                 or else RE.Reason (Traversal_Outcome) = Greplib.Results.Source_Limit_Reached
                 or else Greplib.Cancellation.Is_Requested (Effective_Cancellation);
            end;
         end loop;
         Source_Queue.Close;
         Slot_States.Producer_Closed;
      exception
         when others =>
            RE.Set_Status (Edit_Key, Traversal_Outcome, Greplib.Results.Failed);
            RE.Set_Reason (Edit_Key, Traversal_Outcome, Greplib.Results.Fatal_Error);
            Internal_Cancellation.Request;
            Source_Queue.Cancel;
            Slot_States.Producer_Closed;
            Slot_States.Cancel;
      end Traversal_Producer;

      task type Worker;

      task body Worker is
         Slot : Natural;
         Found : Boolean;
      begin
         loop
            Source_Queue.Take (Slot, Found);
            exit when not Found;

            declare
               Local_Sink : Channel_Sink := (Channel => Channels (Slot)'Access);
            begin
               Greplib.Files.Search_File
                 (Greplib.Paths.To_Path (U.To_String (Slot_Paths (Slot))),
                  Patterns, Search_Options, Local_Sink, Results (Slot).Outcome,
                  Effective_Cancellation, Slot_Sequences (Slot));
            exception
               when others =>
                  declare
                     Accepted : Boolean;
                     D : constant Greplib.Diagnostics.Diagnostic :=
                       Greplib.Diagnostics.Make
                         (Greplib.Diagnostics.Internal_Invariant_Failure,
                          Greplib.Diagnostics.Fatal_Error,
                          "concurrent worker failed");
                  begin
                     RE.Set_Status (Edit_Key, Results (Slot).Outcome, Greplib.Results.Failed);
                     RE.Set_Wide (Edit_Key, Results (Slot).Outcome, RE.Sources_Considered_Field, 1);
                     RE.Set_Reason (Edit_Key, Results (Slot).Outcome, Greplib.Results.Fatal_Error);
                     RE.Set_Wide (Edit_Key, Results (Slot).Outcome, RE.Diagnostic_Count_Field, 1);
                     RE.Append_Diagnostic (Edit_Key, Results (Slot).Outcome, D);
                     RE.Append_Source_Summary
                       (Edit_Key,
                        Results (Slot).Outcome,
                        Greplib.Sources.Building.Make
                          (Edit_Key,
                           Greplib.Sources.File_Source,
                           Slot_Sequences (Slot),
                           Greplib.Paths.To_Path (U.To_String (Slot_Paths (Slot)))));
                     Channels (Slot).Publish
                       (EB.Make_Diagnostic
                          (Edit_Key, Greplib.Paths.To_Path (U.To_String (Slot_Paths (Slot))),
                           D, Slot_Sequences (Slot)),
                        1,
                        Accepted);
                  end;
            end;
            Channels (Slot).Close;
            Slot_States.Complete (Slot);
         end loop;
      end Worker;

      Workers : array (1 .. Worker_Total) of Worker;
      pragma Unreferenced (Workers);
   begin
      if Search_Options.Order = Greplib.Options.Completion_Order then
         loop
            declare
               Slot : Natural;
            begin
               exit when Stop_All;
               Slot_States.Take_Ready (Slot);
               exit when Slot = 0;
               Deliver_Source (Slot);
            end;
         end loop;
      else
         loop
            declare
               Slot : Natural;
               Found : Boolean;
            begin
               exit when Stop_All;
               Slot_States.Take_Next_Assigned (Slot, Found);
               exit when not Found;
               Deliver_Source (Slot);
            end;
         end loop;
      end if;

      Merge_Source_Outcome (Outcome, Traversal_Outcome, Search_Options);
   exception
      when others =>
         Cancel_All;
         raise;
   end Search_Paths_Concurrently;

   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation) is
      Empty : Greplib.Path_Filters.Filter_List;
      Filters : constant Greplib.Path_Filters.Compiled_Filter_Set := Greplib.Path_Filters.Compile (Empty);
   begin
      Search_Paths
        (Roots, Patterns, Filters, Search_Options, Directory_Options, Sink, Outcome, Cancellation);
   end Search_Paths;

   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation)
   is
      Sink : Greplib.Events.No_Op_Sink;
   begin
      Search_Paths (Roots, Patterns, Search_Options, Directory_Options, Sink, Outcome, Cancellation);
   end Search_Paths;

   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation)
   is
      Diags : Greplib.Diagnostics.Diagnostic_List :=
        Validate (Roots, Patterns, Filters, Search_Options, Directory_Options);
   begin
      RE.Reset (Edit_Key, Outcome);

      if not Diags.Is_Empty then
         Apply_Pre_Traversal_Failure (Outcome, Diags, Search_Options);
         return;
      end if;

      if Directory_Options.Worker_Count > 1 then
         Search_Paths_Concurrently
           (Roots, Patterns, Filters, Search_Options, Directory_Options,
            Sink, Outcome, Cancellation);
         return;
      end if;

      for I in 1 .. Greplib.Paths.Length (Roots) loop
         declare
            Root : constant String := Greplib.Paths.Image (Greplib.Paths.Element (Roots, I));
            Root_Failed : Boolean := False;
            Ancestors : String_Vectors.Vector;
            Root_Identity : constant Greplib.Internal.Filesystem_Identity.Object_Identity :=
              Greplib.Internal.Filesystem_Identity.Read (Root);
         begin
            RE.Add_Wide (Edit_Key, Outcome, RE.Roots_Considered_Field);
            if Directory_Options.Stay_On_Starting_Filesystem
              and then not Greplib.Internal.Filesystem_Identity.Is_Available (Root_Identity)
            then
               Add_Diagnostic
                 (Outcome,
                  Greplib.Diagnostics.Make
                    (Greplib.Diagnostics.Filesystem_Open_Failed,
                     Traversal_Severity (Directory_Options),
                     Root,
                     Path => Root,
                     Filesystem_Operation => "read-root-filesystem"),
                  Search_Options);
               Root_Failed := Directory_Options.Traversal_Errors = Fail_Root;
            else
               Search_One
                 (Root, Root, 0, Patterns, Filters, Search_Options,
                  Directory_Options, Sink, Outcome, Root_Failed, Cancellation,
                  Root_Identity, null, null, Ancestors);
            end if;
            exit when RE.Status (Outcome) = Greplib.Results.Cancelled
              or else RE.Status (Outcome) = Greplib.Results.Failed
              or else RE.Reason (Outcome) = Greplib.Results.Quiet_Match_Found
              or else RE.Reason (Outcome) = Greplib.Results.Source_Limit_Reached;
         end;
      end loop;
   end Search_Paths;

   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation)
   is
      Sink : Greplib.Events.No_Op_Sink;
   begin
      Search_Paths (Roots, Patterns, Filters, Search_Options, Directory_Options, Sink, Outcome, Cancellation);
   end Search_Paths;
end Greplib.Directories;
