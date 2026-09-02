pragma Ada_2022;

with Greplib.Byte_Strings;
with Greplib.Diagnostics;
with Greplib.Directories;
pragma Elaborate_All (Greplib.Directories);
with Greplib.Files;
with Greplib.Path_Filters;
with Greplib.Paths;
with Greplib.Result_Authority;
with Greplib.Results.Editing;
with Greplib.Search;

package body Greplib.Collected is
   package RE renames Greplib.Results.Editing;
   Edit_Key : constant Greplib.Result_Authority.Token := Greplib.Result_Authority.Internal;
   use type Greplib.Results.Overall_Status;

   Event_Overhead_Bytes : constant Byte_Count := 64;

   type Collector is new Greplib.Events.Event_Sink with record
      Options : Collection_Options;
      Events : Event_Vectors.Vector;
      Truncated : Boolean := False;
      Truncation : Collection_Truncation := (others => False);
      Bytes : Byte_Count := 0;
      Records : Wide_Count := 0;
   end record;

   overriding procedure On_Event
     (Sink : in out Collector;
      Event : Greplib.Events.Search_Event;
      Action : out Greplib.Events.Event_Action);

   function Event_Size (Event : Greplib.Events.Search_Event) return Byte_Count is
      use type Greplib.Events.Event_Kind;
      Content_Bytes : Byte_Count := 0;
      Diagnostic_Bytes : Byte_Count := 0;
      Span_Bytes : constant Byte_Count := Byte_Count (Greplib.Events.Spans (Event).Length) * 24;
      Path_Bytes : constant Byte_Count := Byte_Count (Greplib.Paths.Image (Greplib.Events.Source_Path (Event))'Length);
   begin
      if Greplib.Events.Kind (Event) in Greplib.Events.Selected_Record | Greplib.Events.Context_Record then
         Content_Bytes := Greplib.Byte_Strings.Length (Greplib.Events.Content (Event));
      elsif Greplib.Events.Kind (Event) = Greplib.Events.Diagnostic_Event then
         Diagnostic_Bytes :=
           Byte_Count (Greplib.Diagnostics.Message (Greplib.Events.Diagnostic (Event))'Length);
      end if;

      return Event_Overhead_Bytes + Path_Bytes + Content_Bytes + Diagnostic_Bytes + Span_Bytes;
   end Event_Size;

   overriding procedure On_Event
     (Sink : in out Collector;
      Event : Greplib.Events.Search_Event;
      Action : out Greplib.Events.Event_Action) is
      use type Greplib.Events.Event_Kind;
      use type Greplib.Events.Event_Action;
      Size : constant Byte_Count := Event_Size (Event);
      Is_Record_Result : constant Boolean :=
        Greplib.Events.Kind (Event) in
          Greplib.Events.Selected_Record | Greplib.Events.Context_Record | Greplib.Events.Binary_Match;
      Event_Limit : constant Boolean := Wide_Count (Sink.Events.Length) >= Sink.Options.Maximum_Events;
      Record_Limit : constant Boolean := Is_Record_Result and then Sink.Records >= Sink.Options.Maximum_Records;
      Byte_Limit : constant Boolean :=
        Sink.Bytes > Sink.Options.Maximum_Bytes
        or else Size > Sink.Options.Maximum_Bytes - Sink.Bytes;
   begin
      Action := Greplib.Events.Continue_Search;

      if Event_Limit or else Record_Limit or else Byte_Limit then
         Sink.Truncated := True;
         Sink.Truncation.Events := Sink.Truncation.Events or else Event_Limit;
         Sink.Truncation.Records := Sink.Truncation.Records or else Record_Limit;
         Sink.Truncation.Bytes := Sink.Truncation.Bytes or else Byte_Limit;
         if Sink.Options.On_Limit = Stop_And_Return_Partial then
            Action := Greplib.Events.Stop_All_Search;
         end if;
         return;
      end if;

      Sink.Events.Append (Event);
      Sink.Bytes := Sink.Bytes + Size;
      if Is_Record_Result then
         Sink.Records := Sink.Records + 1;
      end if;
   end On_Event;

   procedure Append_Invalid_Collection_Diagnostic
     (Diagnostics : in out Greplib.Diagnostics.Diagnostic_List;
      Message : String) is
   begin
      Diagnostics.Append
        (Greplib.Diagnostics.Make
           (Greplib.Diagnostics.Configuration_Invalid_Option_Combination,
            Greplib.Diagnostics.Fatal_Error,
            Message));
   end Append_Invalid_Collection_Diagnostic;

   function Validate (Collection : Collection_Options) return Greplib.Diagnostics.Diagnostic_List is
      Result : Greplib.Diagnostics.Diagnostic_List;
   begin
      if Collection.Maximum_Records = 0 then
         Append_Invalid_Collection_Diagnostic (Result, "collection record limit must be positive");
      end if;

      if Collection.Maximum_Bytes = 0 then
         Append_Invalid_Collection_Diagnostic (Result, "collection byte limit must be positive");
      end if;

      if Collection.Maximum_Events = 0 then
         Append_Invalid_Collection_Diagnostic (Result, "collection event limit must be positive");
      end if;

      return Result;
   end Validate;

   procedure Append_All
     (Target : in out Greplib.Diagnostics.Diagnostic_List;
      Source : Greplib.Diagnostics.Diagnostic_List) is
   begin
      for I in 1 .. Natural (Source.Length) loop
         Target.Append (Source.Element (I));
      end loop;
   end Append_All;

   function Validate
     (Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options) return Greplib.Diagnostics.Diagnostic_List
   is
      Result : Greplib.Diagnostics.Diagnostic_List := Validate (Collection);
   begin
      Append_All (Result, Greplib.Search.Validate (Patterns, Search_Options));
      return Result;
   end Validate;

   function Validate_File
     (Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options) return Greplib.Diagnostics.Diagnostic_List
   is
      Result : Greplib.Diagnostics.Diagnostic_List := Validate (Collection);
   begin
      Append_All (Result, Greplib.Files.Validate (Patterns, Search_Options));
      return Result;
   end Validate_File;

   function Validate_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Collection : Collection_Options) return Greplib.Diagnostics.Diagnostic_List
   is
      Result : Greplib.Diagnostics.Diagnostic_List := Validate (Collection);
   begin
      Append_All
        (Result,
         Greplib.Directories.Validate (Roots, Patterns, Search_Options, Directory_Options));
      return Result;
   end Validate_Paths;

   function Validate_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Collection : Collection_Options) return Greplib.Diagnostics.Diagnostic_List
   is
      Result : Greplib.Diagnostics.Diagnostic_List := Validate (Collection);
   begin
      Append_All
        (Result,
         Greplib.Directories.Validate (Roots, Patterns, Filters, Search_Options, Directory_Options));
      return Result;
   end Validate_Paths;

   procedure Set_Collection_Failure
     (Diagnostics : Greplib.Diagnostics.Diagnostic_List;
      Result : out Collected_Result) is
   begin
      Result := (Events => <>, Outcome => <>, Truncated => False, Truncation => (others => False));
      RE.Set_Status (Edit_Key, Result.Outcome, Greplib.Results.Failed);
      RE.Set_Reason (Edit_Key, Result.Outcome, Greplib.Results.Fatal_Error);
      RE.Set_Wide (Edit_Key, Result.Outcome, RE.Diagnostic_Count_Field, Wide_Count (Diagnostics.Length));
      for I in 1 .. Natural (Diagnostics.Length) loop
         RE.Append_Diagnostic (Edit_Key, Result.Outcome, Diagnostics.Element (I));
      end loop;
   end Set_Collection_Failure;

   procedure Finish
     (Sink : Collector;
      Collection : Collection_Options;
      Result : in out Collected_Result) is
   begin
      Result.Events := Sink.Events;
      Result.Truncated := Sink.Truncated;
      Result.Truncation := Sink.Truncation;

      if Sink.Truncated then
         RE.Set_Diagnostics_Truncated (Edit_Key, Result.Outcome, True);
         RE.Set_Reason (Edit_Key, Result.Outcome, Greplib.Results.Result_Limit_Reached);
         RE.Set_Last_Source_Reason (Edit_Key, Result.Outcome, Greplib.Results.Result_Limit_Reached);
         if Greplib.Results.Status (Result.Outcome) = Greplib.Results.Cancelled
           and then Collection.On_Limit = Stop_And_Return_Partial
         then
            RE.Set_Status (Edit_Key, Result.Outcome, Greplib.Results.Completed);
            RE.Set_Cancellation_Observed (Edit_Key, Result.Outcome, False);
         end if;
      end if;
   end Finish;

   procedure Search_String
     (Subject : String;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result)
   is
      Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
        Validate (Patterns, Search_Options, Collection);
      Sink : Collector :=
        (Options => Collection, Events => <>, Truncated => False,
         Truncation => (others => False), Bytes => 0, Records => 0);
   begin
      Result := (Events => <>, Outcome => <>, Truncated => False, Truncation => (others => False));
      if not Diagnostics.Is_Empty then
         Set_Collection_Failure (Diagnostics, Result);
         return;
      end if;

      Greplib.Search.Search_String (Subject, Patterns, Search_Options, Sink, Result.Outcome);
      Finish (Sink, Collection, Result);
   end Search_String;

   procedure Search_Bytes
     (Subject : Ada.Streams.Stream_Element_Array;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result)
   is
      Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
        Validate (Patterns, Search_Options, Collection);
      Sink : Collector :=
        (Options => Collection, Events => <>, Truncated => False,
         Truncation => (others => False), Bytes => 0, Records => 0);
   begin
      Result := (Events => <>, Outcome => <>, Truncated => False, Truncation => (others => False));
      if not Diagnostics.Is_Empty then
         Set_Collection_Failure (Diagnostics, Result);
         return;
      end if;

      Greplib.Search.Search_Bytes (Subject, Patterns, Search_Options, Sink, Result.Outcome);
      Finish (Sink, Collection, Result);
   end Search_Bytes;

   procedure Search_Stream
     (Stream : in out Ada.Streams.Root_Stream_Type'Class;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation)
   is
      Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
        Validate_File (Patterns, Search_Options, Collection);
      Sink : Collector :=
        (Options => Collection, Events => <>, Truncated => False,
         Truncation => (others => False), Bytes => 0, Records => 0);
   begin
      Result := (Events => <>, Outcome => <>, Truncated => False, Truncation => (others => False));
      if not Diagnostics.Is_Empty then
         Set_Collection_Failure (Diagnostics, Result);
         return;
      end if;

      Greplib.Files.Search_Stream (Stream, Patterns, Search_Options, Sink, Result.Outcome, Cancellation);
      Finish (Sink, Collection, Result);
   end Search_Stream;

   procedure Search_File
     (Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation)
   is
      Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
        Validate_File (Patterns, Search_Options, Collection);
      Sink : Collector :=
        (Options => Collection, Events => <>, Truncated => False,
         Truncation => (others => False), Bytes => 0, Records => 0);
   begin
      Result := (Events => <>, Outcome => <>, Truncated => False, Truncation => (others => False));
      if not Diagnostics.Is_Empty then
         Set_Collection_Failure (Diagnostics, Result);
         return;
      end if;

      Greplib.Files.Search_File (Path, Patterns, Search_Options, Sink, Result.Outcome, Cancellation);
      Finish (Sink, Collection, Result);
   end Search_File;

   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation)
   is
      Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
        Validate_Paths (Roots, Patterns, Search_Options, Directory_Options, Collection);
      Sink : Collector :=
        (Options => Collection, Events => <>, Truncated => False,
         Truncation => (others => False), Bytes => 0, Records => 0);
   begin
      Result := (Events => <>, Outcome => <>, Truncated => False, Truncation => (others => False));
      if not Diagnostics.Is_Empty then
         Set_Collection_Failure (Diagnostics, Result);
         return;
      end if;

      Greplib.Directories.Search_Paths
        (Roots, Patterns, Search_Options, Directory_Options, Sink, Result.Outcome, Cancellation);
      Finish (Sink, Collection, Result);
   end Search_Paths;

   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation)
   is
      Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
        Validate_Paths (Roots, Patterns, Filters, Search_Options, Directory_Options, Collection);
      Sink : Collector :=
        (Options => Collection, Events => <>, Truncated => False,
         Truncation => (others => False), Bytes => 0, Records => 0);
   begin
      Result := (Events => <>, Outcome => <>, Truncated => False, Truncation => (others => False));
      if not Diagnostics.Is_Empty then
         Set_Collection_Failure (Diagnostics, Result);
         return;
      end if;

      Greplib.Directories.Search_Paths
        (Roots, Patterns, Filters, Search_Options, Directory_Options, Sink, Result.Outcome, Cancellation);
      Finish (Sink, Collection, Result);
   end Search_Paths;
end Greplib.Collected;
