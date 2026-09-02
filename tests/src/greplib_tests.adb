pragma Ada_2022;

with Ada.Command_Line;
with Ada.Containers.Indefinite_Vectors;
with Ada.Directories;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded;
with Ada.Task_Identification;
with Ada.Text_IO;
with AUnit.Assertions;
with Interfaces.C;
with Interfaces.C.Strings;
with Greplib;
with Greplib.Byte_Strings;
with Greplib.Cancellation;
with Greplib.Collected;
with Greplib.Diagnostics;
with Greplib.Directories;
with Greplib.Events;
with Greplib.Files;
with Greplib.Internal.Execution_Plans;
with Greplib.Internal.Filesystem;
with Greplib.Internal.Regexp_Adapter;
with Greplib.Options;
with Greplib.Path_Filters;
with Greplib.Paths;
with Greplib.Patterns;
with Greplib.Results;
with Greplib.Search;
with Greplib.Sources;
with Project_Tools.Files;

procedure Greplib_Tests is
   package U renames Ada.Strings.Unbounded;
   package PF renames Project_Tools.Files;
   use AUnit.Assertions;
   use type Ada.Streams.Stream_Element;
   use type Ada.Streams.Stream_Element_Offset;
   use type Greplib.Wide_Count;
   use type Greplib.Record_Number;
   use type Greplib.Diagnostics.Diagnostic_Domain;
   use type Greplib.Diagnostics.Severity;
   use type Greplib.Events.Event_Kind;
   use type Greplib.Options.Result_Order;
   use type Greplib.Path_Filters.Filter_Action;
   use type Greplib.Path_Filters.Filter_Basis;
   use type Greplib.Path_Filters.Filter_Kind;
   use type Greplib.Path_Filters.Filter_Target;
   use type Greplib.Results.Binary_Classification;
   use type Greplib.Results.Count_Completeness;
   use type Greplib.Results.Completion_Reason;
   use type Greplib.Results.Overall_Status;
   use type Greplib.Sources.Source_Kind;
   use type Ada.Task_Identification.Task_Id;
   use type Interfaces.C.int;

   function Status (Outcome : Greplib.Results.Search_Outcome) return Greplib.Results.Overall_Status is
      (Greplib.Results.Status (Outcome));
   function Diagnostics (Outcome : Greplib.Results.Search_Outcome) return Greplib.Diagnostics.Diagnostic_List is
      (Greplib.Results.Diagnostics (Outcome));
   function Sources_Considered (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Sources_Considered (Greplib.Results.Summary (Outcome)));
   function Sources_Opened (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Sources_Opened (Greplib.Results.Summary (Outcome)));
   function Sources_Completed (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Sources_Completed (Greplib.Results.Summary (Outcome)));
   function Sources_With_Results (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Sources_With_Results (Greplib.Results.Summary (Outcome)));
   function Sources_Changed_During_Search (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Sources_Changed_During_Search (Greplib.Results.Summary (Outcome)));
   function Roots_Considered (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Roots_Considered (Greplib.Results.Summary (Outcome)));
   function Directories_Visited (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Directories_Visited (Greplib.Results.Summary (Outcome)));
   function Directories_Skipped (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Directories_Skipped (Greplib.Results.Summary (Outcome)));
   function Entries_Examined (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Entries_Examined (Greplib.Results.Summary (Outcome)));
   function Files_Accepted (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Files_Accepted (Greplib.Results.Summary (Outcome)));
   function Files_Filtered (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Files_Filtered (Greplib.Results.Summary (Outcome)));
   function Links_Encountered (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Links_Encountered (Greplib.Results.Summary (Outcome)));
   function Links_Followed (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Links_Followed (Greplib.Results.Summary (Outcome)));
   function Filesystem_Boundaries_Skipped
     (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Filesystem_Boundaries_Skipped (Greplib.Results.Summary (Outcome)));
   function Records_Read (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Records_Read (Greplib.Results.Summary (Outcome)));
   function Bytes_Read (Outcome : Greplib.Results.Search_Outcome) return Greplib.Byte_Count is
      (Greplib.Results.Bytes_Read (Greplib.Results.Summary (Outcome)));
   function Selected_Record_Count (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Selected_Record_Count (Greplib.Results.Summary (Outcome)));
   function Match_Count (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Match_Count (Greplib.Results.Summary (Outcome)));
   function Match_Count_State (Outcome : Greplib.Results.Search_Outcome) return Greplib.Results.Count_Completeness is
      (Greplib.Results.Match_Count_State (Greplib.Results.Summary (Outcome)));
   function Diagnostic_Count (Outcome : Greplib.Results.Search_Outcome) return Greplib.Wide_Count is
      (Greplib.Results.Diagnostic_Count (Greplib.Results.Summary (Outcome)));
   function Diagnostics_Truncated (Outcome : Greplib.Results.Search_Outcome) return Boolean is
      (Greplib.Results.Diagnostics_Truncated (Greplib.Results.Summary (Outcome)));
   function Cancellation_Observed (Outcome : Greplib.Results.Search_Outcome) return Boolean is
      (Greplib.Results.Cancellation_Observed (Greplib.Results.Summary (Outcome)));
   function Reason (Outcome : Greplib.Results.Search_Outcome) return Greplib.Results.Completion_Reason is
      (Greplib.Results.Reason (Greplib.Results.Summary (Outcome)));

   type Short_Read_Stream is new Ada.Streams.Root_Stream_Type with record
      Text : U.Unbounded_String;
      Next : Natural := 1;
      Chunk : Natural := 1;
      Reads : Natural := 0;
      Fail_Read : Natural := 0;
   end record;

   overriding procedure Read
     (Stream : in out Short_Read_Stream;
      Item : out Ada.Streams.Stream_Element_Array;
      Last : out Ada.Streams.Stream_Element_Offset);

   overriding procedure Write
     (Stream : in out Short_Read_Stream;
      Item : Ada.Streams.Stream_Element_Array);

   overriding procedure Read
     (Stream : in out Short_Read_Stream;
      Item : out Ada.Streams.Stream_Element_Array;
      Last : out Ada.Streams.Stream_Element_Offset)
   is
      S : constant String := U.To_String (Stream.Text);
      Count : Natural := 0;
   begin
      Stream.Reads := Stream.Reads + 1;
      if Stream.Fail_Read /= 0 and then Stream.Reads >= Stream.Fail_Read then
         raise Constraint_Error;
      end if;
      if Stream.Next > S'Length then
         Last := Item'First - 1;
         return;
      end if;

      declare
         Max_Count : constant Natural :=
           Natural'Min (Stream.Chunk, Natural'Min (Natural (Item'Length), S'Length - Stream.Next + 1));
      begin
         for J in 0 .. Max_Count - 1 loop
            Item (Item'First + Ada.Streams.Stream_Element_Offset (J)) :=
              Ada.Streams.Stream_Element (Character'Pos (S (Stream.Next + J)));
            Count := Count + 1;
         end loop;
      end;
      Last := Item'First + Ada.Streams.Stream_Element_Offset (Count - 1);
      Stream.Next := Stream.Next + Count;
   end Read;

   overriding procedure Write
     (Stream : in out Short_Read_Stream;
      Item : Ada.Streams.Stream_Element_Array) is
      pragma Unreferenced (Stream, Item);
   begin
      raise Program_Error;
   end Write;

   procedure Test_Foundational_Value_Types is
      Bytes : Greplib.Byte_Strings.Byte_String;
      Roundtrip : Ada.Streams.Stream_Element_Array (1 .. 3);
      Empty_Roundtrip : Ada.Streams.Stream_Element_Array :=
        Greplib.Byte_Strings.To_Stream_Element_Array (Greplib.Byte_Strings.Empty);
      Offset_Data : constant Ada.Streams.Stream_Element_Array (10 .. 12) :=
        (10 => Character'Pos ('x'), 11 => Character'Pos ('y'), 12 => Character'Pos ('z'));
      Paths : Greplib.Paths.Path_List;
      External_Source : aliased Greplib.Cancellation.Cancellation_Source;
      Internal_Source : aliased Greplib.Cancellation.Cancellation_Source;
      External_Token : constant Greplib.Cancellation.Cancellation_Token :=
        Greplib.Cancellation.Token (External_Source);
      Internal_Token : constant Greplib.Cancellation.Cancellation_Token :=
        Greplib.Cancellation.Token (Internal_Source);
      Combined_Token : constant Greplib.Cancellation.Cancellation_Token :=
        Greplib.Cancellation.Combine (External_Token, Internal_Token);
   begin
      Assert (Greplib.Byte_Strings.Length (Greplib.Byte_Strings.Empty) = 0, "empty byte string has zero length");
      Assert (Empty_Roundtrip'Length = 0, "empty byte string converts to empty stream array");
      Bytes := Greplib.Byte_Strings.To_Byte_String ("A" & Character'Val (0) & "Z");
      Assert (Greplib.Byte_Strings.Length (Bytes) = 3, "byte string preserves embedded NUL length");
      Assert (Greplib.Byte_Strings.Element (Bytes, 2) = Character'Val (0), "byte string preserves embedded NUL byte");
      Roundtrip := Greplib.Byte_Strings.To_Stream_Element_Array (Bytes);
      Assert (Roundtrip (1) = Character'Pos ('A'), "stream roundtrip first byte");
      Assert (Roundtrip (2) = 0, "stream roundtrip embedded NUL");
      Assert (Roundtrip (3) = Character'Pos ('Z'), "stream roundtrip final byte");
      Assert
        (Greplib.Byte_Strings.To_String (Greplib.Byte_Strings.To_Byte_String (Offset_Data)) = "xyz",
         "byte string accepts non-one-based stream arrays");

      Assert (Greplib.Paths.Is_Empty (Greplib.Paths.To_Path ("")), "empty path is empty");
      Greplib.Paths.Append (Paths, Greplib.Paths.To_Path ("first"));
      Greplib.Paths.Append (Paths, Greplib.Paths.To_Path ("second"));
      Assert (Greplib.Paths.Length (Paths) = 2, "path list length after append");
      Assert (Greplib.Paths.Image (Greplib.Paths.Element (Paths, 1)) = "first", "path list preserves order");
      Assert (Greplib.Paths.Image (Greplib.Paths.Element (Paths, 2)) = "second", "path list second element");
      Greplib.Paths.Clear (Paths);
      Assert (Greplib.Paths.Length (Paths) = 0, "path list clear resets length");

      Assert (not Greplib.Cancellation.Is_Requested (Combined_Token), "combined token starts unrequested");
      Internal_Source.Request;
      Assert (Greplib.Cancellation.Is_Requested (Combined_Token), "combined token observes internal request");
      Assert
        (not Greplib.Cancellation.Is_Requested
           (Greplib.Cancellation.Combine (Greplib.Cancellation.No_Cancellation, External_Token)),
         "combined token preserves unrequested external source");
      External_Source.Request;
      Assert
        (Greplib.Cancellation.Is_Requested
           (Greplib.Cancellation.Combine (Greplib.Cancellation.No_Cancellation, External_Token)),
         "combined token observes external request");
   end Test_Foundational_Value_Types;

   procedure Test_Fixed_String is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Opts : Greplib.Options.Search_Options;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("aba"));
      Set := Greplib.Patterns.Compile (List);
      Assert (Greplib.Patterns.Is_Usable (Set), "compiled fixed pattern is usable");
      Opts.Spans := Greplib.Options.All_Spans;
      Greplib.Collected.Search_String
        ("ababa" & ASCII.LF & "x", Set, Opts, (others => <>), Result);
      Assert (Status (Result.Outcome) = Greplib.Results.Completed, "search completed");
      Assert (Selected_Record_Count (Result.Outcome) = 1, "one selected record");
      Assert (Natural (Result.Events.Length) >= 1, "events retained");
      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
            Assert (Greplib.Byte_Strings.To_String (Greplib.Events.Content (E)) = "ababa", "record content");
            Assert (Natural (Greplib.Events.Spans (E).Length) = 1, "non-overlapping leftmost span");
         end if;
      end loop;

      declare
         Case_List : Greplib.Patterns.Pattern_List;
         Case_Set : Greplib.Patterns.Compiled_Pattern_Set;
         Case_Options : Greplib.Patterns.Compilation_Options;
      begin
         Case_Options.Case_Insensitive := True;
         Greplib.Patterns.Append (Case_List, Greplib.Patterns.Fixed_String_Pattern ("abc"));
         Case_Set := Greplib.Patterns.Compile (Case_List, Case_Options);
         Greplib.Collected.Search_String ("ABC", Case_Set, Opts, (others => <>), Result);
         Assert (Selected_Record_Count (Result.Outcome) = 1, "ASCII fixed strings fold case");
      end;

      declare
         Byte_List : Greplib.Patterns.Pattern_List;
         Byte_Set : Greplib.Patterns.Compiled_Pattern_Set;
         Byte_Options : Greplib.Patterns.Compilation_Options;
      begin
         Byte_Options.Case_Insensitive := True;
         Greplib.Patterns.Append
           (Byte_List, Greplib.Patterns.Fixed_String_Pattern (Character'Val (16#C0#) & "A"));
         Byte_Set := Greplib.Patterns.Compile (Byte_List, Byte_Options);
         Greplib.Collected.Search_String (Character'Val (16#E0#) & "a", Byte_Set, Opts, (others => <>), Result);
         Assert (Selected_Record_Count (Result.Outcome) = 0, "non-ASCII fixed bytes do not fold");
      end;

      declare
         Empty_List : Greplib.Patterns.Pattern_List;
         Empty_Set : Greplib.Patterns.Compiled_Pattern_Set;
         Saw_Empty : Boolean := False;
      begin
         Greplib.Patterns.Append (Empty_List, Greplib.Patterns.Fixed_String_Pattern (""));
         Empty_Set := Greplib.Patterns.Compile (Empty_List);
         Opts := (others => <>);
         Opts.Spans := Greplib.Options.All_Spans;
         Greplib.Collected.Search_String ("abc", Empty_Set, Opts, (others => <>), Result);
         for E of Result.Events loop
            if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
               Assert (Natural (Greplib.Events.Spans (E).Length) = 4, "empty fixed spans every position");
               Assert (Greplib.Events.Spans (E).Element (4).First_Byte = 3, "empty fixed final span at end");
               Saw_Empty := True;
            end if;
         end loop;
         Assert (Saw_Empty, "empty fixed span event observed");

         Opts.Mode := Greplib.Options.Count_Matches;
         Greplib.Collected.Search_String ("abc", Empty_Set, Opts, (others => <>), Result);
         Assert (Match_Count (Result.Outcome) = 4, "empty fixed count-matches counts zero-length progress");
      end;
   end Test_Fixed_String;

   procedure Test_Invert_And_Count is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Opts : Greplib.Options.Search_Options;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);
      Opts.Mode := Greplib.Options.Count_Selected_Records;
      Opts.Invert_Match := True;
      Greplib.Collected.Search_String
        ("hit" & ASCII.LF & "miss" & ASCII.LF, Set, Opts, (others => <>), Result);
      Assert (Selected_Record_Count (Result.Outcome) = 1, "inverted count selects miss");
   end Test_Invert_And_Count;

   procedure Test_Generated_Fixed_String_Model is
      Alphabet : constant String := "ab_";
      Result : Greplib.Collected.Collected_Result;
      Opts : Greplib.Options.Search_Options;

      function Generated (Value : Natural; Length : Natural) return String is
         Text : String (1 .. Length);
         N : Natural := Value;
      begin
         for I in reverse Text'Range loop
            Text (I) := Alphabet (Alphabet'First + (N mod Alphabet'Length));
            N := N / Alphabet'Length;
         end loop;
         return Text;
      end Generated;

      function Power (Base : Natural; Exponent : Natural) return Natural is
         Result : Natural := 1;
      begin
         for I in 1 .. Exponent loop
            Result := Result * Base;
         end loop;
         return Result;
      end Power;

      function First_Index (Subject : String; Pattern : String) return Natural is
      begin
         if Pattern'Length = 0 then
            return 0;
         end if;
         if Pattern'Length > Subject'Length then
            return Natural'Last;
         end if;
         for I in Subject'First .. Subject'Last - Pattern'Length + 1 loop
            if Subject (I .. I + Pattern'Length - 1) = Pattern then
               return I - Subject'First;
            end if;
         end loop;
         return Natural'Last;
      end First_Index;

      type Expected_Span is record
         Pattern : Greplib.Pattern_Index := 1;
         First : Natural := 0;
         Last : Natural := 0;
      end record;
      package Expected_Span_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Expected_Span);

      procedure Append_Candidates
        (Items : in out Expected_Span_Vectors.Vector;
         Subject : String;
         Pattern_Text : String;
         Pattern_No : Greplib.Pattern_Index) is
      begin
         if Pattern_Text'Length = 0 then
            for Pos in 0 .. Subject'Length loop
               Items.Append (Expected_Span'(Pattern_No, Pos, Pos));
            end loop;
         elsif Subject'Length >= Pattern_Text'Length then
            for Pos in Subject'First .. Subject'Last - Pattern_Text'Length + 1 loop
               if Subject (Pos .. Pos + Pattern_Text'Length - 1) = Pattern_Text then
                  Items.Append
                    (Expected_Span'
                       (Pattern_No,
                      Pos - Subject'First,
                      Pos - Subject'First + Pattern_Text'Length));
               end if;
            end loop;
         end if;
      end Append_Candidates;

      procedure Sort_Candidates (Items : in out Expected_Span_Vectors.Vector) is
      begin
         if Natural (Items.Length) < 2 then
            return;
         end if;

         for I in Items.First_Index .. Items.Last_Index loop
            for J in I + 1 .. Items.Last_Index loop
               declare
                  A : Expected_Span := Items.Element (I);
                  B : Expected_Span := Items.Element (J);
                  Swap : constant Boolean :=
                    B.First < A.First
                    or else (B.First = A.First and then B.Last > A.Last)
                    or else
                      (B.First = A.First and then B.Last = A.Last and then B.Pattern < A.Pattern);
               begin
                  if Swap then
                     Items.Replace_Element (I, B);
                     Items.Replace_Element (J, A);
                  end if;
               end;
            end loop;
         end loop;
      end Sort_Candidates;

      function Reference_Spans
        (Subject : String;
         First_Pattern : String;
         Second_Pattern : String) return Expected_Span_Vectors.Vector
      is
         Candidates : Expected_Span_Vectors.Vector;
         Expected : Expected_Span_Vectors.Vector;
         Last_End : Natural := 0;
         Have : Boolean := False;
      begin
         if Subject'Length = 0 then
            return Expected;
         end if;

         Append_Candidates (Candidates, Subject, First_Pattern, 1);
         Append_Candidates (Candidates, Subject, Second_Pattern, 2);
         Sort_Candidates (Candidates);

         for Candidate of Candidates loop
            if (not Have or else Candidate.First >= Last_End)
              and then
                (Expected.Is_Empty
                 or else Expected.Last_Element.First /= Candidate.First
                 or else Expected.Last_Element.Last /= Candidate.Last)
            then
               Expected.Append (Candidate);
               Last_End := Candidate.Last;
               Have := True;
            end if;
         end loop;

         return Expected;
      end Reference_Spans;
   begin
      Opts.Spans := Greplib.Options.All_Spans;
      for Subject_Length in 0 .. 5 loop
         for Subject_Value in 0 .. Power (Alphabet'Length, Subject_Length) - 1 loop
            declare
               Subject : constant String := Generated (Subject_Value, Subject_Length);
            begin
               for Pattern_Length in 0 .. 3 loop
                  for Pattern_Value in 0 .. Power (Alphabet'Length, Pattern_Length) - 1 loop
                     declare
                        Pattern_Text : constant String := Generated (Pattern_Value, Pattern_Length);
                        Patterns : Greplib.Patterns.Pattern_List;
                        Set : Greplib.Patterns.Compiled_Pattern_Set;
                        Expected : constant Natural :=
                          (if Subject'Length = 0 then Natural'Last else First_Index (Subject, Pattern_Text));
                        Saw_Selected : Boolean := False;
                     begin
                        Greplib.Patterns.Append
                          (Patterns, Greplib.Patterns.Fixed_String_Pattern (Pattern_Text));
                        Set := Greplib.Patterns.Compile (Patterns);
                        Greplib.Collected.Search_String (Subject, Set, Opts, (others => <>), Result);
                        for E of Result.Events loop
                           if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
                              Saw_Selected := True;
                              if Expected /= Natural'Last then
                                 Assert
                                   (Natural (Greplib.Events.Spans (E).Element (1).First_Byte) = Expected,
                                    "generated fixed-string first span matches reference");
                              end if;
                           end if;
                        end loop;
                        Assert
                          (Saw_Selected = (Expected /= Natural'Last),
                           "generated fixed-string selection matches reference");
                     end;
                  end loop;
               end loop;
            end;
         end loop;
      end loop;

      for Subject_Length in 0 .. 4 loop
         for Subject_Value in 0 .. Power (Alphabet'Length, Subject_Length) - 1 loop
            declare
               Subject : constant String := Generated (Subject_Value, Subject_Length);
            begin
               for First_Length in 0 .. 2 loop
                  for First_Value in 0 .. Power (Alphabet'Length, First_Length) - 1 loop
                     for Second_Length in 0 .. 2 loop
                        for Second_Value in 0 .. Power (Alphabet'Length, Second_Length) - 1 loop
                           declare
                              First_Text : constant String := Generated (First_Value, First_Length);
                              Second_Text : constant String := Generated (Second_Value, Second_Length);
                              Patterns : Greplib.Patterns.Pattern_List;
                              Set : Greplib.Patterns.Compiled_Pattern_Set;
                              Expected : constant Expected_Span_Vectors.Vector :=
                                Reference_Spans (Subject, First_Text, Second_Text);
                              Saw_Selected : Boolean := False;
                           begin
                              Greplib.Patterns.Append
                                (Patterns, Greplib.Patterns.Fixed_String_Pattern (First_Text));
                              Greplib.Patterns.Append
                                (Patterns, Greplib.Patterns.Fixed_String_Pattern (Second_Text));
                              Set := Greplib.Patterns.Compile (Patterns);
                              Greplib.Collected.Search_String (Subject, Set, Opts, (others => <>), Result);
                              for E of Result.Events loop
                                 if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
                                    Saw_Selected := True;
                                    Assert
                                      (Natural (Greplib.Events.Spans (E).Length) = Natural (Expected.Length),
                                       "generated two-pattern span count matches reference");
                                    for I in 1 .. Natural (Expected.Length) loop
                                       Assert
                                         (Greplib.Events.Spans (E).Element (I).Pattern =
                                          Expected.Element (I).Pattern,
                                          "generated two-pattern span pattern matches reference");
                                       Assert
                                         (Natural (Greplib.Events.Spans (E).Element (I).First_Byte) =
                                          Expected.Element (I).First,
                                          "generated two-pattern span start matches reference");
                                       Assert
                                         (Natural (Greplib.Events.Spans (E).Element (I).Last_Byte_Exclusive) =
                                          Expected.Element (I).Last,
                                          "generated two-pattern span end matches reference");
                                    end loop;
                                 end if;
                              end loop;
                              Assert
                                (Saw_Selected = (not Expected.Is_Empty),
                                 "generated two-pattern selection matches reference");
                           end;
                        end loop;
                     end loop;
                  end loop;
               end loop;
            end;
         end loop;
      end loop;
   end Test_Generated_Fixed_String_Model;

   procedure Test_Generated_Fixed_Boundary_Model is
      Alphabet : constant String := "ab_!";
      Result : Greplib.Collected.Collected_Result;
      Search_Options : Greplib.Options.Search_Options;

      function Generated (Value : Natural; Length : Natural) return String is
         Text : String (1 .. Length);
         N : Natural := Value;
      begin
         for I in reverse Text'Range loop
            Text (I) := Alphabet (Alphabet'First + (N mod Alphabet'Length));
            N := N / Alphabet'Length;
         end loop;
         return Text;
      end Generated;

      function Power (Base : Natural; Exponent : Natural) return Natural is
         Result : Natural := 1;
      begin
         for I in 1 .. Exponent loop
            Result := Result * Base;
         end loop;
         return Result;
      end Power;

      function Is_Word (C : Character) return Boolean is
      begin
         return C in 'A' .. 'Z' or else C in 'a' .. 'z' or else C in '0' .. '9' or else C = '_';
      end Is_Word;

      function Whole_Word_Hit (Subject : String; Pattern_Text : String) return Boolean is
      begin
         if Subject'Length = 0 or else Pattern_Text'Length = 0 or else Pattern_Text'Length > Subject'Length then
            return False;
         end if;

         for Pos in Subject'First .. Subject'Last - Pattern_Text'Length + 1 loop
            if Subject (Pos .. Pos + Pattern_Text'Length - 1) = Pattern_Text then
               declare
                  First : constant Natural := Pos - Subject'First;
                  Last : constant Natural := First + Pattern_Text'Length;
                  Left_Ok : constant Boolean :=
                    First = 0 or else not Is_Word (Subject (Subject'First + First - 1));
                  Right_Ok : constant Boolean :=
                    Last = Subject'Length or else not Is_Word (Subject (Subject'First + Last));
               begin
                  if Left_Ok and then Right_Ok then
                     return True;
                  end if;
               end;
            end if;
         end loop;

         return False;
      end Whole_Word_Hit;

      function Whole_Record_Hit (Subject : String; Pattern_Text : String; Whole_Word : Boolean) return Boolean is
      begin
         if Subject'Length = 0 then
            return False;
         end if;

         if Subject /= Pattern_Text then
            return False;
         end if;

         return not Whole_Word or else Whole_Word_Hit (Subject, Pattern_Text);
      end Whole_Record_Hit;
   begin
      Search_Options.Spans := Greplib.Options.First_Span;
      for Subject_Length in 0 .. 5 loop
         for Subject_Value in 0 .. Power (Alphabet'Length, Subject_Length) - 1 loop
            declare
               Subject : constant String := Generated (Subject_Value, Subject_Length);
            begin
               for Pattern_Length in 0 .. 3 loop
                  for Pattern_Value in 0 .. Power (Alphabet'Length, Pattern_Length) - 1 loop
                     declare
                        Pattern_Text : constant String := Generated (Pattern_Value, Pattern_Length);
                        List : Greplib.Patterns.Pattern_List;
                        Set : Greplib.Patterns.Compiled_Pattern_Set;
                        Compile_Options : Greplib.Patterns.Compilation_Options;
                     begin
                        Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern (Pattern_Text));

                        Compile_Options.Whole_Word := True;
                        Set := Greplib.Patterns.Compile (List, Compile_Options);
                        Greplib.Collected.Search_String (Subject, Set, Search_Options, (others => <>), Result);
                        Assert
                          ((Selected_Record_Count (Result.Outcome) > 0) = Whole_Word_Hit (Subject, Pattern_Text),
                           "generated whole-word fixed-string selection matches reference");

                        Compile_Options.Whole_Record := True;
                        Set := Greplib.Patterns.Compile (List, Compile_Options);
                        Greplib.Collected.Search_String (Subject, Set, Search_Options, (others => <>), Result);
                        Assert
                          ((Selected_Record_Count (Result.Outcome) > 0) =
                           Whole_Record_Hit (Subject, Pattern_Text, True),
                           "generated whole-record whole-word fixed-string selection matches reference");

                        Compile_Options.Whole_Word := False;
                        Set := Greplib.Patterns.Compile (List, Compile_Options);
                        Greplib.Collected.Search_String (Subject, Set, Search_Options, (others => <>), Result);
                        Assert
                          ((Selected_Record_Count (Result.Outcome) > 0) =
                           Whole_Record_Hit (Subject, Pattern_Text, False),
                           "generated whole-record fixed-string selection matches reference");
                     end;
                  end loop;
               end loop;
            end;
         end loop;
      end loop;
   end Test_Generated_Fixed_Boundary_Model;

   procedure Test_Regex_Adapter_Whole_Subject is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Opts : Greplib.Options.Search_Options;
      Saw_Span : Boolean := False;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Regular_Expression_Pattern ("Pat+ern"));
      Set := Greplib.Patterns.Compile (List);
      Assert (Greplib.Patterns.Is_Usable (Set), "compiled regex pattern is usable");
      Opts.Spans := Greplib.Options.All_Spans;
      Greplib.Collected.Search_String
         ("Test Pattern Test" & ASCII.LF & "no", Set, Opts, (others => <>), Result);
      Assert (Selected_Record_Count (Result.Outcome) = 1, "regex selected one record");
      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
            Assert (Natural (Greplib.Events.Spans (E).Length) = 1, "regex emitted one span");
            Assert (Greplib.Events.Spans (E).Element (1).First_Byte = 5, "regex span start");
            Assert (Greplib.Events.Spans (E).Element (1).Last_Byte_Exclusive = 12, "regex span end");
            Saw_Span := True;
         end if;
      end loop;
      Assert (Saw_Span, "regex span event observed");

      declare
         Case_List : Greplib.Patterns.Pattern_List;
         Case_Set : Greplib.Patterns.Compiled_Pattern_Set;
         Case_Result : Greplib.Collected.Collected_Result;
         Case_Opts : Greplib.Options.Search_Options;
         Saw_Case_Span : Boolean := False;
      begin
         Greplib.Patterns.Append (Case_List, Greplib.Patterns.Regular_Expression_Pattern ("abc"));
         Case_Opts.Spans := Greplib.Options.All_Spans;
         Case_Opts.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Set := Greplib.Patterns.Compile
           (Case_List, Greplib.Patterns.Compilation_Options'(Case_Insensitive => True, others => <>));
         Case_Set := Set;
         Assert (Greplib.Patterns.Is_Usable (Case_Set), "case-insensitive regex set is usable");
         Greplib.Collected.Search_String ("xxABCyy", Case_Set, Case_Opts, (others => <>), Case_Result);
         Assert (Selected_Record_Count (Case_Result.Outcome) = 1, "case-insensitive regex selected");
         for E of Case_Result.Events loop
            if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
               Assert (Natural (Greplib.Events.Spans (E).Length) = 1, "case-insensitive regex has one span");
               Assert (Greplib.Events.Spans (E).Element (1).First_Byte = 2, "case-insensitive span start");
               Assert
                 (Greplib.Events.Spans (E).Element (1).Last_Byte_Exclusive = 5,
                  "case-insensitive span end");
               Saw_Case_Span := True;
            end if;
         end loop;
         Assert (Saw_Case_Span, "case-insensitive regex span observed");
      end;

      declare
         Full_List : Greplib.Patterns.Pattern_List;
         Full_Set : Greplib.Patterns.Compiled_Pattern_Set;
         Full_Result : Greplib.Collected.Collected_Result;
         Full_Opts : Greplib.Options.Search_Options;
         Saw_Full_Span : Boolean := False;
      begin
         Greplib.Patterns.Append (Full_List, Greplib.Patterns.Regular_Expression_Pattern ("a+"));
         Full_Set := Greplib.Patterns.Compile
           (Full_List, Greplib.Patterns.Compilation_Options'(Whole_Record => True, others => <>));
         Assert (Greplib.Patterns.Is_Usable (Full_Set), "whole-record regex set is usable");
         Full_Opts.Spans := Greplib.Options.All_Spans;
         Greplib.Collected.Search_String ("aaa" & ASCII.LF & "baa", Full_Set, Full_Opts, (others => <>), Full_Result);
         Assert (Selected_Record_Count (Full_Result.Outcome) = 1, "whole-record regex selected only full match");
         for E of Full_Result.Events loop
            if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
               Assert (Natural (Greplib.Events.Spans (E).Length) = 1, "whole-record regex has one span");
               Assert (Greplib.Events.Spans (E).Element (1).First_Byte = 0, "whole-record span start");
               Assert (Greplib.Events.Spans (E).Element (1).Last_Byte_Exclusive = 3, "whole-record span end");
               Saw_Full_Span := True;
            end if;
         end loop;
         Assert (Saw_Full_Span, "whole-record regex span observed");
      end;

      declare
         Nul_List : Greplib.Patterns.Pattern_List;
         Nul_Set : Greplib.Patterns.Compiled_Pattern_Set;
         Nul_Result : Greplib.Collected.Collected_Result;
         Nul_Opts : Greplib.Options.Search_Options;
         Saw_Nul_Span : Boolean := False;
      begin
         Greplib.Patterns.Append (Nul_List, Greplib.Patterns.Regular_Expression_Pattern ("b"));
         Nul_Set := Greplib.Patterns.Compile (Nul_List);
         Assert (Greplib.Patterns.Is_Usable (Nul_Set), "NUL-subject regex set is usable");
         Nul_Opts.Spans := Greplib.Options.All_Spans;
         Nul_Opts.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Greplib.Collected.Search_String
           ("a" & Character'Val (0) & "b", Nul_Set, Nul_Opts, (others => <>), Nul_Result);
         Assert (Selected_Record_Count (Nul_Result.Outcome) = 1, "regex selected after embedded NUL");
         for E of Nul_Result.Events loop
            if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
               Assert (Natural (Greplib.Events.Spans (E).Length) = 1, "embedded NUL regex has one span");
               Assert (Greplib.Events.Spans (E).Element (1).First_Byte = 2, "embedded NUL span start");
               Assert (Greplib.Events.Spans (E).Element (1).Last_Byte_Exclusive = 3, "embedded NUL span end");
               Saw_Nul_Span := True;
            end if;
         end loop;
         Assert (Saw_Nul_Span, "embedded NUL regex span observed");
      end;

      declare
         Zero_List : Greplib.Patterns.Pattern_List;
         Zero_Set : Greplib.Patterns.Compiled_Pattern_Set;
         Zero_Result : Greplib.Collected.Collected_Result;
         Zero_Opts : Greplib.Options.Search_Options;
         Saw_Zero_Spans : Boolean := False;
      begin
         Greplib.Patterns.Append (Zero_List, Greplib.Patterns.Regular_Expression_Pattern ("a*"));
         Zero_Set := Greplib.Patterns.Compile (Zero_List);
         Assert (Greplib.Patterns.Is_Usable (Zero_Set), "zero-length regex set is usable");
         Zero_Opts.Spans := Greplib.Options.All_Spans;
         Greplib.Collected.Search_String ("bbb", Zero_Set, Zero_Opts, (others => <>), Zero_Result);
         Assert (Selected_Record_Count (Zero_Result.Outcome) = 1, "zero-length regex selects subject");
         for E of Zero_Result.Events loop
            if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
               Assert (Natural (Greplib.Events.Spans (E).Length) = 4, "zero-length regex emits progress spans");
               for I in 1 .. 4 loop
                  Assert
                    (Natural (Greplib.Events.Spans (E).Element (I).First_Byte) = I - 1,
                     "zero-length regex span start progresses");
                  Assert
                    (Natural (Greplib.Events.Spans (E).Element (I).Last_Byte_Exclusive) = I - 1,
                     "zero-length regex span end equals start");
               end loop;
               Saw_Zero_Spans := True;
            end if;
         end loop;
         Assert (Saw_Zero_Spans, "zero-length regex spans observed");
      end;
   end Test_Regex_Adapter_Whole_Subject;

   procedure Test_Regexp_Adapter_Conformance is
      package RA renames Greplib.Internal.Regexp_Adapter;
      use type Greplib.Byte_Offset;

      procedure Assert_Match
        (Actual : RA.Regex_Match;
         First : Natural;
         Last : Natural;
         Label : String) is
      begin
         Assert (Actual.Found, Label & " found");
         Assert (not Actual.Limit_Exceeded, Label & " did not hit match limit");
         Assert (Actual.First_Byte = First, Label & " first byte");
         Assert (Actual.Last_Byte_Exclusive = Last, Label & " last byte exclusive");
      end Assert_Match;

      procedure Assert_No_Match
        (Actual : RA.Regex_Match;
         Label : String) is
      begin
         Assert (not Actual.Found, Label & " not found");
         Assert (not Actual.Limit_Exceeded, Label & " did not hit match limit");
      end Assert_No_Match;
   begin
      Assert (RA.Supports_Spans, "regexp adapter reports span support");

      declare
         Invalid : constant RA.Compile_Result := RA.Compile ("[", Case_Insensitive => False);
         Empty : constant RA.Compile_Result := RA.Compile ("", Case_Insensitive => False);
      begin
         Assert (not Invalid.Ok, "invalid regex compile fails structurally");
         Assert (U.Length (Invalid.Message) > 0, "invalid regex compile has diagnostic text");
         Assert (not Empty.Ok, "empty regex compile fails structurally");
         Assert (U.Length (Empty.Message) > 0, "empty regex compile has diagnostic text");
      end;

      declare
         Compiled : constant RA.Compile_Result := RA.Compile ("b+", Case_Insensitive => False);
      begin
         Assert (Compiled.Ok, "regex compile succeeds");
         Assert_Match (RA.Find_From (Compiled.Value, "abbc", 0, False), 1, 3, "find from origin");
         Assert_Match (RA.Find_From (Compiled.Value, "abbc", 2, False), 2, 3, "find from arbitrary offset");
         Assert_No_Match (RA.Find_From (Compiled.Value, "abbc", 3, False), "find from after match");
         Assert_No_Match (RA.Find_From (Compiled.Value, "aaaa", 0, False), "no-match representation");
      end;

      declare
         Compiled : constant RA.Compile_Result := RA.Compile ("abc", Case_Insensitive => False);
      begin
         Assert (Compiled.Ok, "case regex compile succeeds");
         Assert_No_Match (RA.Find_From (Compiled.Value, "ABC", 0, False), "case-sensitive mismatch");
         Assert_Match (RA.Find_From (Compiled.Value, "ABC", 0, True), 0, 3, "case-insensitive match");
      end;

      declare
         Compiled : constant RA.Compile_Result := RA.Compile ("a+", Case_Insensitive => False);
      begin
         Assert (Compiled.Ok, "full-match regex compile succeeds");
         Assert_Match (RA.Matches_Entire (Compiled.Value, "aaa", False), 0, 3, "full-match success");
         Assert_No_Match (RA.Matches_Entire (Compiled.Value, "baa", False), "full-match failure");
      end;

      declare
         Compiled : constant RA.Compile_Result := RA.Compile ("a*", Case_Insensitive => False);
      begin
         Assert (Compiled.Ok, "zero-length regex compile succeeds");
         Assert_Match (RA.Find_From (Compiled.Value, "bbb", 0, False), 0, 0, "zero-length at origin");
         Assert_Match (RA.Find_From (Compiled.Value, "bbb", 2, False), 2, 2, "zero-length at offset");
         Assert_Match (RA.Matches_Entire (Compiled.Value, "", False), 0, 0, "empty subject full-match");
      end;

      declare
         Compiled : constant RA.Compile_Result := RA.Compile ("b", Case_Insensitive => False);
         Copy : RA.Compiled_Regex;
      begin
         Assert (Compiled.Ok, "embedded-NUL subject regex compile succeeds");
         Copy := Compiled.Value;
         Assert_Match
           (RA.Find_From (Copy, "a" & Character'Val (0) & "b", 0, False),
            2, 3, "copied regex matches embedded-NUL subject");
      end;

      declare
         Task_1_Ok : Boolean := False;
         Task_2_Ok : Boolean := False;
      begin
         declare
            Compiled : constant RA.Compile_Result := RA.Compile ("a+", Case_Insensitive => False);
            Shared : RA.Compiled_Regex := Compiled.Value;

            task First_Task;
            task Second_Task;

            task body First_Task is
               M : RA.Regex_Match;
            begin
               M := RA.Find_From (Shared, "xxaaa", 0, False);
               Task_1_Ok := M.Found and then M.First_Byte = 2 and then M.Last_Byte_Exclusive = 5;
            end First_Task;

            task body Second_Task is
               M : RA.Regex_Match;
            begin
               M := RA.Matches_Entire (Shared, "aaaa", False);
               Task_2_Ok := M.Found and then M.First_Byte = 0 and then M.Last_Byte_Exclusive = 4;
            end Second_Task;
         begin
            Assert (Compiled.Ok, "task-safety regex compile succeeds");
         end;

         Assert (Task_1_Ok, "shared compiled regex works from first task");
         Assert (Task_2_Ok, "shared compiled regex works from second task");
      end;
   end Test_Regexp_Adapter_Conformance;

   procedure Test_Pattern_Compilation_Atomicity is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Patterns.Compilation_Options;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("valid"));
      declare
         Valid_Diagnostics : Greplib.Diagnostics.Diagnostic_List := Greplib.Patterns.Validate (List);
      begin
         Assert (Valid_Diagnostics.Is_Empty, "valid fixed pattern list validates directly");
      end;

      Greplib.Patterns.Append (List, Greplib.Patterns.Regular_Expression_Pattern ("["));
      declare
         Regex_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List := Greplib.Patterns.Validate (List);
      begin
         Assert (Natural (Regex_Diagnostics.Length) = 1, "direct pattern validation counts invalid regex");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Regex_Diagnostics.Element (1))) =
            "pattern.invalid_regular_expression",
            "direct pattern validation reports invalid regex");
      end;

      Set := Greplib.Patterns.Compile (List);

      Assert (not Greplib.Patterns.Is_Usable (Set), "invalid regex makes compiled set unusable");
      Assert (Greplib.Patterns.Count (Set) = 0, "failed pattern compilation exposes no partial subset");
      Assert (Natural (Greplib.Patterns.Diagnostics (Set).Length) = 1, "failed pattern retains diagnostic");
      Assert
        (Greplib.Diagnostics.Identifier
           (Greplib.Diagnostics.Code (Greplib.Patterns.Diagnostics (Set).Element (1))) =
         "pattern.invalid_regular_expression",
         "failed pattern diagnostic identifier");

      declare
         Count_List : Greplib.Patterns.Pattern_List;
      begin
         Greplib.Patterns.Append (Count_List, Greplib.Patterns.Fixed_String_Pattern ("a"));
         Greplib.Patterns.Append (Count_List, Greplib.Patterns.Fixed_String_Pattern ("b"));
         Options := (others => <>);
         Options.Maximum_Pattern_Count := 1;
         declare
            Count_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
              Greplib.Patterns.Validate (Count_List, Options);
         begin
            Assert (Natural (Count_Diagnostics.Length) = 1, "direct pattern validation counts count limit");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Count_Diagnostics.Element (1))) =
               "configuration.invalid_option_combination",
               "direct pattern validation reports count limit");
         end;

         Set := Greplib.Patterns.Compile (Count_List, Options);
         Assert (not Greplib.Patterns.Is_Usable (Set), "pattern count limit makes set unusable");
         Assert (Greplib.Patterns.Count (Set) = 0, "pattern count limit exposes no partial compiled subset");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Greplib.Patterns.Diagnostics (Set).Element (1))) =
            "configuration.invalid_option_combination",
            "pattern count limit diagnostic identifier");
      end;

      declare
         Bytes_List : Greplib.Patterns.Pattern_List;
      begin
         Greplib.Patterns.Append (Bytes_List, Greplib.Patterns.Fixed_String_Pattern ("ab"));
         Greplib.Patterns.Append (Bytes_List, Greplib.Patterns.Fixed_String_Pattern ("cd"));
         Options := (others => <>);
         Options.Maximum_Total_Pattern_Bytes := 3;
         declare
            Bytes_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
              Greplib.Patterns.Validate (Bytes_List, Options);
         begin
            Assert (Natural (Bytes_Diagnostics.Length) = 1, "direct pattern validation counts byte limit");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Bytes_Diagnostics.Element (1))) =
               "configuration.invalid_option_combination",
               "direct pattern validation reports byte limit");
         end;

         Set := Greplib.Patterns.Compile (Bytes_List, Options);
         Assert (not Greplib.Patterns.Is_Usable (Set), "pattern bytes limit makes set unusable");
         Assert (Greplib.Patterns.Count (Set) = 0, "pattern bytes limit exposes no partial compiled subset");
      end;

      declare
         Empty_List : Greplib.Patterns.Pattern_List;
      begin
         Options := (others => <>);
         Options.Maximum_Pattern_Count := 0;
         Options.Maximum_Total_Pattern_Bytes := 0;
         declare
            Empty_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
              Greplib.Patterns.Validate (Empty_List, Options);
         begin
            Assert
              (Natural (Empty_Diagnostics.Length) = 3,
               "direct pattern validation aggregates invalid limits and empty list");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Empty_Diagnostics.Element (1))) =
               "configuration.invalid_option_combination",
               "direct pattern validation reports zero count first");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Empty_Diagnostics.Element (2))) =
               "configuration.invalid_option_combination",
               "direct pattern validation reports zero bytes second");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Empty_Diagnostics.Element (3))) =
               "configuration.no_patterns",
               "direct pattern validation reports empty list third");
         end;

         Set := Greplib.Patterns.Compile (Empty_List, Options);
         Assert (not Greplib.Patterns.Is_Usable (Set), "invalid compile limits make empty set unusable");
         Assert (Greplib.Patterns.Count (Set) = 0, "invalid compile limits expose no compiled entries");
         Assert
           (Natural (Greplib.Patterns.Diagnostics (Set).Length) = 3,
            "invalid compile limits and empty list report independent diagnostics");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Greplib.Patterns.Diagnostics (Set).Element (1))) =
            "configuration.invalid_option_combination",
            "zero pattern count diagnostic identifier");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Greplib.Patterns.Diagnostics (Set).Element (2))) =
            "configuration.invalid_option_combination",
            "zero pattern bytes diagnostic identifier");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Greplib.Patterns.Diagnostics (Set).Element (3))) =
            "configuration.no_patterns",
            "empty pattern list diagnostic still retained");
      end;
   end Test_Pattern_Compilation_Atomicity;

   procedure Test_Pattern_Resource_Boundary_Matrix is
      type Limit_Array is array (Positive range <>) of Greplib.Wide_Count;
      Count_Limits : constant Limit_Array := (1, 2, 3);
      Byte_Limits : constant Limit_Array := (2, 3, 4);

      procedure Assert_Configuration_Diagnostic
        (Set : Greplib.Patterns.Compiled_Pattern_Set;
         Label : String) is
      begin
         Assert
           (Natural (Greplib.Patterns.Diagnostics (Set).Length) = 1,
            Label & " retains one diagnostic");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Greplib.Patterns.Diagnostics (Set).Element (1))) =
            "configuration.invalid_option_combination",
            Label & " diagnostic identifier");
      end Assert_Configuration_Diagnostic;
   begin
      for Limit of Count_Limits loop
         declare
            Patterns : Greplib.Patterns.Pattern_List;
            Options : Greplib.Patterns.Compilation_Options := (others => <>);
            Set : Greplib.Patterns.Compiled_Pattern_Set;
            Label : constant String := "pattern-count limit" & Greplib.Wide_Count'Image (Limit);
         begin
            Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("first"));
            Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("second"));
            Options.Maximum_Pattern_Count := Limit;
            Set := Greplib.Patterns.Compile (Patterns, Options);

            if Limit < 2 then
               Assert (not Greplib.Patterns.Is_Usable (Set), Label & " below boundary is unusable");
               Assert (Greplib.Patterns.Count (Set) = 0, Label & " below boundary has no partial entries");
               Assert_Configuration_Diagnostic (Set, Label);
            else
               Assert (Greplib.Patterns.Is_Usable (Set), Label & " at or above boundary is usable");
               Assert (Greplib.Patterns.Count (Set) = 2, Label & " at or above boundary preserves both entries");
               Assert
                 (Natural (Greplib.Patterns.Diagnostics (Set).Length) = 0,
                  Label & " at or above boundary has no diagnostics");
            end if;
         end;
      end loop;

      for Limit of Byte_Limits loop
         declare
            Patterns : Greplib.Patterns.Pattern_List;
            Options : Greplib.Patterns.Compilation_Options := (others => <>);
            Set : Greplib.Patterns.Compiled_Pattern_Set;
            Label : constant String := "pattern-byte limit" & Greplib.Wide_Count'Image (Limit);
         begin
            Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("ab"));
            Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("c"));
            Options.Maximum_Total_Pattern_Bytes := Greplib.Byte_Count (Limit);
            Set := Greplib.Patterns.Compile (Patterns, Options);

            if Limit < 3 then
               Assert (not Greplib.Patterns.Is_Usable (Set), Label & " below boundary is unusable");
               Assert (Greplib.Patterns.Count (Set) = 0, Label & " below boundary has no partial entries");
               Assert_Configuration_Diagnostic (Set, Label);
            else
               Assert (Greplib.Patterns.Is_Usable (Set), Label & " at or above boundary is usable");
               Assert (Greplib.Patterns.Count (Set) = 2, Label & " at or above boundary preserves both entries");
               Assert
                 (Natural (Greplib.Patterns.Diagnostics (Set).Length) = 0,
                  Label & " at or above boundary has no diagnostics");
            end if;
         end;
      end loop;
   end Test_Pattern_Resource_Boundary_Matrix;

   procedure Test_Internal_Execution_Plans is
      package EP renames Greplib.Internal.Execution_Plans;
      use type EP.Plan_Kind;
      Options : Greplib.Options.Search_Options;
      Plan : EP.Search_Plan;
   begin
      Options := (others => <>);
      Plan := EP.Compile (Options);
      Assert (EP.Kind (Plan) = EP.Emit_Records_Plan, "emit mode compiles to emit-records plan");
      Assert (EP.Retains_Record_Content (Plan), "emit-records plan retains content");
      Assert (not EP.Needs_Context (Plan), "emit-records plan without context does not need context");
      Assert (not EP.Needs_Spans (Plan), "emit-records plan without spans does not discover spans");
      Assert (EP.Needs_Complete_Input (Plan), "emit-records plan needs complete input");
      Assert (not EP.Stops_After_First_Selected (Plan), "emit-records plan does not stop at first selected");

      Options.Context.Before := 1;
      Options.Spans := Greplib.Options.First_Span;
      Plan := EP.Compile (Options);
      Assert (EP.Kind (Plan) = EP.Emit_Records_Plan, "context mode still emits records");
      Assert (EP.Needs_Context (Plan), "context mode needs context");
      Assert (EP.Needs_Spans (Plan), "first-span mode discovers spans");

      Options := (others => <>);
      Options.Mode := Greplib.Options.Count_Selected_Records;
      Plan := EP.Compile (Options);
      Assert (EP.Kind (Plan) = EP.Count_Selected_Plan, "selected-count mode compiles to count-selected plan");
      Assert (not EP.Retains_Record_Content (Plan), "selected-count plan does not retain content");
      Assert (EP.Needs_Complete_Input (Plan), "selected-count plan needs complete input");

      Options.Mode := Greplib.Options.Count_Matches;
      Plan := EP.Compile (Options);
      Assert (EP.Kind (Plan) = EP.Count_Matches_Plan, "match-count mode compiles to count-matches plan");
      Assert (EP.Needs_Spans (Plan), "match-count plan discovers spans");
      Assert (EP.Needs_Complete_Input (Plan), "match-count plan needs complete input");

      Options.Mode := Greplib.Options.Source_Names_With_Matches;
      Plan := EP.Compile (Options);
      Assert (EP.Kind (Plan) = EP.Names_With_Matches_Plan, "names-with mode compiles to names-with plan");
      Assert (EP.Stops_After_First_Selected (Plan), "names-with plan stops after first selected");
      Assert (not EP.Needs_Complete_Input (Plan), "names-with plan can stop early");

      Options.Mode := Greplib.Options.Source_Names_Without_Matches;
      Plan := EP.Compile (Options);
      Assert (EP.Kind (Plan) = EP.Names_Without_Matches_Plan, "names-without mode compiles to names-without plan");
      Assert (not EP.Stops_After_First_Selected (Plan), "names-without plan does not stop at first selected");
      Assert (EP.Needs_Complete_Input (Plan), "names-without plan needs complete input");

      Options.Mode := Greplib.Options.Quiet;
      Plan := EP.Compile (Options);
      Assert (EP.Kind (Plan) = EP.Quiet_Plan, "quiet mode compiles to quiet plan");
      Assert (EP.Stops_After_First_Selected (Plan), "quiet plan stops after first selected");
      Assert (not EP.Needs_Complete_Input (Plan), "quiet plan can stop early");

      Plan := EP.Compile (Options, Binary_Report_Active => True);
      Assert (EP.Kind (Plan) = EP.Binary_Match_Plan, "binary report compiles to binary-match plan");
      Assert (EP.Stops_After_First_Selected (Plan), "binary-match plan stops after first selected");
      Assert (not EP.Needs_Complete_Input (Plan), "binary-match plan can stop early");
   end Test_Internal_Execution_Plans;

   procedure Test_Boundary_Modes is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Compile_Options : Greplib.Patterns.Compilation_Options;
      Search_Options : Greplib.Options.Search_Options;
      Result : Greplib.Collected.Collected_Result;
      Selected : Natural := 0;
   begin
      Compile_Options.Whole_Word := True;
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("cat"));
      Set := Greplib.Patterns.Compile (List, Compile_Options);
      Search_Options.Spans := Greplib.Options.All_Spans;
      Greplib.Collected.Search_String
        ("cat" & ASCII.LF & "concatenate" & ASCII.LF & "cat_1" & ASCII.LF & "cat!" & ASCII.LF & "-cat-",
         Set, Search_Options, (others => <>), Result);

      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
            Selected := Selected + 1;
            Assert (Natural (Greplib.Events.Spans (E).Length) = 1, "whole-word selected records retain one span");
         end if;
      end loop;
      Assert (Selected = 3, "whole-word accepts only ASCII non-word boundaries");

      declare
         Empty_List : Greplib.Patterns.Pattern_List;
         Empty_Options : Greplib.Patterns.Compilation_Options;
      begin
         Empty_Options.Whole_Word := True;
         Greplib.Patterns.Append (Empty_List, Greplib.Patterns.Fixed_String_Pattern (""));
         Set := Greplib.Patterns.Compile (Empty_List, Empty_Options);
         Greplib.Collected.Search_String ("abc" & ASCII.LF & "", Set, Search_Options, (others => <>), Result);
         Assert (Selected_Record_Count (Result.Outcome) = 0, "whole-word rejects empty fixed-string matches");
      end;

      declare
         Record_List : Greplib.Patterns.Pattern_List;
         Record_Options : Greplib.Patterns.Compilation_Options;
         Saw_Record_Span : Boolean := False;
      begin
         Record_Options.Whole_Record := True;
         Greplib.Patterns.Append (Record_List, Greplib.Patterns.Fixed_String_Pattern ("cat"));
         Set := Greplib.Patterns.Compile (Record_List, Record_Options);
         Greplib.Collected.Search_String ("cat" & ASCII.LF & "cat!", Set, Search_Options, (others => <>), Result);
         Assert (Selected_Record_Count (Result.Outcome) = 1, "whole-record requires exact record content");
         for E of Result.Events loop
            if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
               Assert (Greplib.Events.Spans (E).Element (1).First_Byte = 0, "whole-record span starts at zero");
               Assert
                 (Greplib.Events.Spans (E).Element (1).Last_Byte_Exclusive = 3,
                  "whole-record span covers record");
               Saw_Record_Span := True;
            end if;
         end loop;
         Assert (Saw_Record_Span, "whole-record span observed");
      end;

      declare
         Duplicate_List : Greplib.Patterns.Pattern_List;
         Duplicate_Options : Greplib.Patterns.Compilation_Options;
         Saw_Duplicate_Span : Boolean := False;
      begin
         Duplicate_Options.Whole_Record := True;
         Greplib.Patterns.Append (Duplicate_List, Greplib.Patterns.Fixed_String_Pattern ("cat"));
         Greplib.Patterns.Append (Duplicate_List, Greplib.Patterns.Regular_Expression_Pattern ("cat"));
         Greplib.Patterns.Append (Duplicate_List, Greplib.Patterns.Fixed_String_Pattern ("cat"));
         Set := Greplib.Patterns.Compile (Duplicate_List, Duplicate_Options);
         Greplib.Collected.Search_String ("cat", Set, Search_Options, (others => <>), Result);
         for E of Result.Events loop
            if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
               Assert (Natural (Greplib.Events.Spans (E).Length) = 1, "whole-record emits one full span");
               Assert (Greplib.Events.Spans (E).Element (1).Pattern = 1, "whole-record keeps lowest pattern index");
               Saw_Duplicate_Span := True;
            end if;
         end loop;
         Assert (Saw_Duplicate_Span, "whole-record duplicate span observed");
      end;

      declare
         Empty_Record_List : Greplib.Patterns.Pattern_List;
         Empty_Record_Options : Greplib.Patterns.Compilation_Options;
      begin
         Empty_Record_Options.Whole_Record := True;
         Empty_Record_Options.Whole_Word := True;
         Greplib.Patterns.Append (Empty_Record_List, Greplib.Patterns.Fixed_String_Pattern (""));
         Set := Greplib.Patterns.Compile (Empty_Record_List, Empty_Record_Options);
         Greplib.Collected.Search_String (ASCII.LF & "x", Set, Search_Options, (others => <>), Result);
         Assert
           (Selected_Record_Count (Result.Outcome) = 0,
            "whole-record whole-word rejects empty full-record match");
      end;

      declare
         Regex_Word_List : Greplib.Patterns.Pattern_List;
         Regex_Word_Options : Greplib.Patterns.Compilation_Options;
      begin
         Regex_Word_Options.Whole_Word := True;
         Greplib.Patterns.Append
           (Regex_Word_List, Greplib.Patterns.Regular_Expression_Pattern ("-a|ab"));
         Set := Greplib.Patterns.Compile (Regex_Word_List, Regex_Word_Options);
         Greplib.Collected.Search_String ("-ab-", Set, Search_Options, (others => <>), Result);
         Assert
           (Selected_Record_Count (Result.Outcome) = 1,
            "whole-word regex rejection does not skip overlapping valid candidate");
         for E of Result.Events loop
            if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
               Assert (Greplib.Events.Spans (E).Element (1).First_Byte = 1, "overlapping regex span start");
               Assert (Greplib.Events.Spans (E).Element (1).Last_Byte_Exclusive = 3, "overlapping regex span end");
            end if;
         end loop;
      end;
   end Test_Boundary_Modes;

   procedure Test_Record_Metadata is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Result : Greplib.Collected.Collected_Result;
      Seen : Natural := 0;

      type Byte_Count_Array is array (Positive range <>) of Greplib.Byte_Count;
      type Boolean_Array is array (Positive range <>) of Boolean;

      Expected_Offsets : constant Byte_Count_Array := (0, 3, 5, 6);
      Expected_Logical : constant Byte_Count_Array := (1, 1, 0, 1);
      Expected_Original : constant Byte_Count_Array := (2, 1, 0, 1);
      Expected_Separator_Size : constant Byte_Count_Array := (1, 1, 1, 0);
      Expected_Separator_Present : constant Boolean_Array := (True, True, True, False);
      Expected_CR_Stripped : constant Boolean_Array := (True, False, False, False);
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern (""));
      Set := Greplib.Patterns.Compile (List);
      Options.CR_Policy := Greplib.Options.Strip_Before_Line_Feed;

      Greplib.Collected.Search_String
        ("a" & ASCII.CR & ASCII.LF & "b" & ASCII.LF & ASCII.LF & "c",
         Set, Options, (others => <>), Result);

      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
            Seen := Seen + 1;
            Assert (Seen <= Expected_Offsets'Length, "too many record metadata events");
            Assert (Greplib.Events.Record_No (E) = Greplib.Record_Number (Seen), "metadata record number");
            Assert (Greplib.Events.Record_Byte_Offset (E) = Expected_Offsets (Seen), "metadata byte offset");
            Assert (Greplib.Events.Logical_Content_Size (E) = Expected_Logical (Seen), "metadata logical size");
            Assert (Greplib.Events.Original_Content_Size (E) = Expected_Original (Seen), "metadata original size");
            Assert (Greplib.Events.Separator_Size (E) = Expected_Separator_Size (Seen), "metadata separator size");
            Assert
              (Greplib.Events.Separator_Present (E) = Expected_Separator_Present (Seen),
               "metadata separator presence");
            Assert
              (Greplib.Events.Carriage_Return_Stripped (E) = Expected_CR_Stripped (Seen),
               "metadata CR stripping flag");
         end if;
      end loop;

      Assert (Seen = Expected_Offsets'Length, "all metadata records observed");
      Assert (Records_Read (Result.Outcome) = 4, "metadata record count");
      Assert (Bytes_Read (Result.Outcome) = 7, "metadata original bytes read");

      Options := (others => <>);
      Options.Separator_Kind := Greplib.Options.Custom;
      Options.Custom_Separator := '|';
      Greplib.Collected.Search_String ("a|b|", Set, Options, (others => <>), Result);
      Assert (Records_Read (Result.Outcome) = 2, "custom separator trailing separator has no extra record");
   end Test_Record_Metadata;

   procedure Test_Search_Bytes_Parity is
      type Counting_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         First_Offset : Greplib.Byte_Offset := 0;
         Second_Separator : Greplib.Byte_Count := 0;
         First_Path : Greplib.Paths.Path;
         First_Source : Greplib.Sources.Source_Descriptor;
      end record;
      overriding procedure On_Event
        (Sink : in out Counting_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Counting_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
            if Sink.Selected = 1 then
               Sink.First_Offset := Greplib.Events.Record_Byte_Offset (Event);
               Sink.First_Path := Greplib.Events.Source_Path (Event);
               Sink.First_Source := Greplib.Events.Source (Event);
            elsif Sink.Selected = 2 then
               Sink.Second_Separator := Greplib.Events.Separator_Size (Event);
            end if;
         end if;
      end On_Event;

      Data : constant Ada.Streams.Stream_Element_Array :=
        (1 => Character'Pos ('a'),
         2 => 0,
         3 => Character'Pos ('b'),
         4 => 0);
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : Counting_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern (""));
      Set := Greplib.Patterns.Compile (List);
      Options.Separator_Kind := Greplib.Options.NUL;

      Greplib.Search.Search_Bytes (Data, Set, Options, Sink, Outcome);

      Assert (Status (Outcome) = Greplib.Results.Completed, "byte-array search completes");
      Assert (Records_Read (Outcome) = 2, "byte-array NUL records match string semantics");
      Assert (Sink.Selected = 2, "byte-array selected events emitted");
      Assert (Sink.First_Offset = 0, "byte-array first record offset");
      Assert (Greplib.Paths.Image (Sink.First_Path) = "<bytes>", "byte-array event source identity");
      Assert (Greplib.Sources.Kind (Sink.First_Source) = Greplib.Sources.Memory_Source, "byte-array source kind");
      Assert (Greplib.Sources.Sequence (Sink.First_Source) = 1, "byte-array source sequence");
      Assert
        (Greplib.Paths.Image (Greplib.Sources.Path (Sink.First_Source)) = "<bytes>",
         "byte-array descriptor source path");
      Assert (Sink.Second_Separator = 1, "byte-array second separator size");
      declare
         Summaries : constant Greplib.Results.Source_Summary_List := Greplib.Results.Source_Summaries (Outcome);
         Summary : constant Greplib.Results.Source_Summary := Greplib.Results.Element (Summaries, 1);
      begin
         Assert (Greplib.Results.Length (Summaries) = 1, "byte-array retains one source summary");
         Assert (Greplib.Results.Records_Read (Summary) = 2, "byte-array source summary records read");
         Assert (Greplib.Results.Selected_Record_Count (Summary) = 2, "byte-array source summary selected count");
         Assert
           (Greplib.Sources.Kind (Greplib.Results.Source (Summary)) = Greplib.Sources.Memory_Source,
            "byte-array source summary kind");
      end;
   end Test_Search_Bytes_Parity;

   procedure Test_Stream_Source_Descriptor is
      type Descriptor_Sink is new Greplib.Events.Event_Sink with record
         Saw_Selected : Boolean := False;
         Selected_Source : Greplib.Sources.Source_Descriptor;
      end record;
      overriding procedure On_Event
        (Sink : in out Descriptor_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Descriptor_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Saw_Selected := True;
            Sink.Selected_Source := Greplib.Events.Source (Event);
         end if;
      end On_Event;

      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Stream : Short_Read_Stream :=
        (Ada.Streams.Root_Stream_Type with
         Text => U.To_Unbounded_String ("hit"),
         Next => 1,
         Chunk => 2,
         Reads => 0,
         Fail_Read => 0);
      Sink : Descriptor_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);

      Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome, Sequence => 7);

      Assert (Status (Outcome) = Greplib.Results.Completed, "stream source descriptor search completes");
      Assert (Sink.Saw_Selected, "stream source descriptor selected event emitted");
      Assert (Greplib.Sources.Kind (Sink.Selected_Source) = Greplib.Sources.Stream_Source, "stream source kind");
      Assert (Greplib.Sources.Sequence (Sink.Selected_Source) = 7, "stream source sequence");
      Assert
        (Greplib.Paths.Image (Greplib.Sources.Path (Sink.Selected_Source)) = "<stream>",
         "stream descriptor source path");
      declare
         Summaries : constant Greplib.Results.Source_Summary_List := Greplib.Results.Source_Summaries (Outcome);
         Summary : constant Greplib.Results.Source_Summary := Greplib.Results.Element (Summaries, 1);
      begin
         Assert (Greplib.Results.Length (Summaries) = 1, "stream retains one source summary");
         Assert (Greplib.Results.Records_Read (Summary) = 1, "stream source summary records read");
         Assert (Greplib.Results.Selected_Record_Count (Summary) = 1, "stream source summary selected count");
         Assert (Greplib.Sources.Sequence (Greplib.Results.Source (Summary)) = 7, "stream source summary sequence");
         Assert
           (Greplib.Sources.Kind (Greplib.Results.Source (Summary)) = Greplib.Sources.Stream_Source,
            "stream source summary kind");
      end;
   end Test_Stream_Source_Descriptor;

   procedure Test_Callback_Free_Search_Overloads is
      Root : constant String := "generated/callback_free";
      Bytes : constant Ada.Streams.Stream_Element_Array (1 .. 3) :=
        (1 => Character'Pos ('h'), 2 => Character'Pos ('i'), 3 => Character'Pos ('t'));
      Stream : Short_Read_Stream :=
        (Ada.Streams.Root_Stream_Type with
         Text => U.To_Unbounded_String ("hit" & ASCII.LF), Next => 1, Chunk => 1, Reads => 0, Fail_Read => 0);
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Outcome : Greplib.Results.Search_Outcome;

      procedure Local_Ensure_Directory (Name : String) is
      begin
         if not PF.Directory_Exists (Name) then
            Ada.Directories.Create_Directory (Name);
         end if;
      end Local_Ensure_Directory;
   begin
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);

      Greplib.Search.Search_String ("hit", Set, Search_Options, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "callback-free string search completes");
      Assert (Selected_Record_Count (Outcome) = 1, "callback-free string search counts match");

      Greplib.Search.Search_Bytes (Bytes, Set, Search_Options, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "callback-free byte search completes");
      Assert (Selected_Record_Count (Outcome) = 1, "callback-free byte search counts match");

      Greplib.Files.Search_Stream (Stream, Set, Search_Options, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "callback-free stream search completes");
      Assert (Selected_Record_Count (Outcome) = 1, "callback-free stream search counts match");

      Local_Ensure_Directory ("generated");
      Local_Ensure_Directory (Root);
      PF.Write_Raw_File (Root & "/one.txt", "hit");
      Greplib.Files.Search_File (Greplib.Paths.To_Path (Root & "/one.txt"), Set, Search_Options, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "callback-free file search completes");
      Assert (Selected_Record_Count (Outcome) = 1, "callback-free file search counts match");

      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
      Greplib.Directories.Search_Paths (Roots, Set, Search_Options, Directory_Options, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "callback-free directory search completes");
      Assert (Selected_Record_Count (Outcome) >= 1, "callback-free directory search counts match");
   end Test_Callback_Free_Search_Overloads;

   procedure Test_Stream_Incremental_Search is
      type Record_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         Diagnostics : Natural := 0;
         Selected_Record : Greplib.Record_Number := 1;
         Selected_Offset : Greplib.Byte_Offset := 0;
         Selected_Text : Greplib.Byte_Strings.Byte_String;
      end record;
      overriding procedure On_Event
        (Sink : in out Record_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Record_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
            Sink.Selected_Record := Greplib.Events.Record_No (Event);
            Sink.Selected_Offset := Greplib.Events.Record_Byte_Offset (Event);
            Sink.Selected_Text := Greplib.Events.Content (Event);
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Diagnostic_Event then
            Sink.Diagnostics := Sink.Diagnostics + 1;
         end if;
      end On_Event;

      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : Record_Sink;
      Outcome : Greplib.Results.Search_Outcome;
      Stream : Short_Read_Stream :=
        (Ada.Streams.Root_Stream_Type with
         Text => U.To_Unbounded_String ("a" & ASCII.LF & "hit" & ASCII.LF & "z"),
         Next => 1,
         Chunk => 1,
         Reads => 0,
         Fail_Read => 0);
   begin
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
      Options.Spans := Greplib.Options.All_Spans;

      Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);

      Assert (Status (Outcome) = Greplib.Results.Completed, "incremental stream search completes");
      Assert (Records_Read (Outcome) = 3, "incremental stream parses split records");
      Assert (Sink.Selected = 1, "incremental stream emits one selected record");
      Assert (Sink.Selected_Record = 2, "incremental stream selected record number");
      Assert (Sink.Selected_Offset = 2, "incremental stream selected byte offset");
      Assert (Greplib.Byte_Strings.To_String (Sink.Selected_Text) = "hit", "incremental stream selected content");
      Assert (Stream.Reads > 1, "incremental stream handles short reads");

      declare
         Quiet_Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF & "late" & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Options.Mode := Greplib.Options.Quiet;
         Sink := (Selected => 0, Diagnostics => 0, Selected_Record => 1, Selected_Offset => 0, Selected_Text => <>);
         Greplib.Files.Search_Stream (Quiet_Stream, Set, Options, Sink, Outcome);
         Assert
           (Reason (Outcome) = Greplib.Results.Quiet_Match_Found,
            "incremental stream quiet reports quiet reason");
         Assert (Records_Read (Outcome) = 1, "incremental stream quiet stops after first record");
         Assert (Sources_Completed (Outcome) = 1, "incremental stream quiet completes source");
         Assert (Quiet_Stream.Reads <= 4, "incremental stream quiet stops before reading full source");
      end;

      declare
         Oversized_Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("abcd" & ASCII.LF & "hit"),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Options.Maximum_Record_Size := 3;
         Sink := (Selected => 0, Diagnostics => 0, Selected_Record => 1, Selected_Offset => 0, Selected_Text => <>);
         Greplib.Files.Search_Stream (Oversized_Stream, Set, Options, Sink, Outcome);
         Assert
           (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
            "incremental stream reports oversized record recoverably");
         Assert (Sink.Diagnostics = 1, "incremental stream emits oversized diagnostic");
         Assert (Records_Read (Outcome) = 2, "incremental stream resynchronizes after oversized record");
         Assert (Selected_Record_Count (Outcome) = 1, "incremental stream searches after oversized record");
      end;

      declare
         Failing_Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 3);
      begin
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Sink := (Selected => 0, Diagnostics => 0, Selected_Record => 1, Selected_Offset => 0, Selected_Text => <>);
         Greplib.Files.Search_Stream (Failing_Stream, Set, Options, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Failed, "incremental stream read failure fails source");
         Assert (Sink.Diagnostics = 1, "incremental stream read failure emits diagnostic");
         Assert (Diagnostic_Count (Outcome) = 1, "incremental stream read failure counts diagnostic");
         Assert (Bytes_Read (Outcome) = 2, "incremental stream read failure preserves bytes read");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
            "stream.read_failed",
            "incremental stream read failure diagnostic identifier");
      end;

      declare
         Tiny_Block_Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF),
            Next => 1,
            Chunk => 100,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Options.Read_Block_Size := 1;
         Sink := (Selected => 0, Diagnostics => 0, Selected_Record => 1, Selected_Offset => 0, Selected_Text => <>);
         Greplib.Files.Search_Stream (Tiny_Block_Stream, Set, Options, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Completed, "one-byte stream read block completes");
         Assert (Sink.Selected = 1, "one-byte stream read block finds record");
         Assert (Tiny_Block_Stream.Reads >= 5, "one-byte stream read block performs repeated reads");
      end;

      declare
         Bad_Block_Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF),
            Next => 1,
            Chunk => 100,
            Reads => 0,
            Fail_Read => 1);
      begin
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Options.Read_Block_Size := 0;
         Sink := (Selected => 0, Diagnostics => 0, Selected_Record => 1, Selected_Offset => 0, Selected_Text => <>);
         Greplib.Files.Search_Stream (Bad_Block_Stream, Set, Options, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Failed, "zero read block fails validation");
         Assert (Records_Read (Outcome) = 0, "zero read block reads no records");
         Assert (Bad_Block_Stream.Reads = 0, "zero read block consumes no incremental input");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
            "configuration.invalid_option_combination",
            "zero read block diagnostic identifier");
      end;

      declare
         Bad_Buffered_Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF),
            Next => 1,
            Chunk => 100,
            Reads => 0,
            Fail_Read => 1);
      begin
         Options := (others => <>);
         Options.Read_Block_Size := 0;
         Options.On_Binary := Greplib.Options.Skip_Source;
         Sink := (Selected => 0, Diagnostics => 0, Selected_Record => 1, Selected_Offset => 0, Selected_Text => <>);
         Greplib.Files.Search_Stream (Bad_Buffered_Stream, Set, Options, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Failed, "zero read block fails buffered validation");
         Assert (Records_Read (Outcome) = 0, "zero read block buffered reads no records");
         Assert (Bad_Buffered_Stream.Reads = 0, "zero read block consumes no buffered input");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
            "configuration.invalid_option_combination",
            "zero read block buffered diagnostic identifier");
      end;

      declare
         Source : aliased Greplib.Cancellation.Cancellation_Source;
         Cancelled_Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF),
            Next => 1,
            Chunk => 100,
            Reads => 0,
            Fail_Read => 1);
      begin
         Source.Request;
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Sink := (Selected => 0, Diagnostics => 0, Selected_Record => 1, Selected_Offset => 0, Selected_Text => <>);
         Greplib.Files.Search_Stream
           (Cancelled_Stream, Set, Options, Sink, Outcome, Greplib.Cancellation.Token (Source));
         Assert (Status (Outcome) = Greplib.Results.Cancelled, "pre-cancelled incremental stream is cancelled");
         Assert (Cancellation_Observed (Outcome), "pre-cancelled incremental stream observes cancellation");
         Assert (Records_Read (Outcome) = 0, "pre-cancelled incremental stream reads no records");
         Assert (Cancelled_Stream.Reads = 0, "pre-cancelled incremental stream consumes no input");
         Assert (Sink.Selected = 0 and then Sink.Diagnostics = 0, "pre-cancelled incremental stream emits no events");
      end;

      declare
         Source : aliased Greplib.Cancellation.Cancellation_Source;
         Cancelled_Buffered_Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF),
            Next => 1,
            Chunk => 100,
            Reads => 0,
            Fail_Read => 1);
      begin
         Source.Request;
         Options := (others => <>);
         Options.On_Binary := Greplib.Options.Skip_Source;
         Sink := (Selected => 0, Diagnostics => 0, Selected_Record => 1, Selected_Offset => 0, Selected_Text => <>);
         Greplib.Files.Search_Stream
           (Cancelled_Buffered_Stream, Set, Options, Sink, Outcome, Greplib.Cancellation.Token (Source));
         Assert (Status (Outcome) = Greplib.Results.Cancelled, "pre-cancelled buffered stream is cancelled");
         Assert (Cancellation_Observed (Outcome), "pre-cancelled buffered stream observes cancellation");
         Assert (Records_Read (Outcome) = 0, "pre-cancelled buffered stream reads no records");
         Assert (Cancelled_Buffered_Stream.Reads = 0, "pre-cancelled buffered stream consumes no input");
         Assert (Sink.Selected = 0 and then Sink.Diagnostics = 0, "pre-cancelled buffered stream emits no events");
      end;
   end Test_Stream_Incremental_Search;

   procedure Test_Generated_Stream_Block_Matrix is
      type Count_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         Diagnostics : Natural := 0;
      end record;
      overriding procedure On_Event
        (Sink : in out Count_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Count_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Diagnostic_Event then
            Sink.Diagnostics := Sink.Diagnostics + 1;
         end if;
      end On_Event;

      type Natural_Array is array (Positive range <>) of Natural;
      type Byte_Count_Array is array (Positive range <>) of Greplib.Byte_Count;

      Chunks : constant Natural_Array := (1, 2, 3, 7, 16, 100);
      Blocks : constant Byte_Count_Array :=
        (1, 2, 3, 7, 16, Greplib.Default_Read_Block_Size, 512);

      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;

      procedure Run_Case
        (Label : String;
         Text : String;
         Separator : Greplib.Options.Record_Separator_Kind;
         Custom_Separator : Character;
         CR_Policy : Greplib.Options.Carriage_Return_Policy;
         Expected_Records : Greplib.Wide_Count;
         Expected_Selected : Greplib.Wide_Count) is
      begin
         for Chunk of Chunks loop
            for Block of Blocks loop
               declare
                  Options : Greplib.Options.Search_Options;
                  Sink : Count_Sink;
                  Outcome : Greplib.Results.Search_Outcome;
                  Stream : Short_Read_Stream :=
                    (Ada.Streams.Root_Stream_Type with
                     Text => U.To_Unbounded_String (Text),
                     Next => 1,
                     Chunk => Chunk,
                     Reads => 0,
                     Fail_Read => 0);
                  Scenario : constant String :=
                    Label & " chunk=" & Natural'Image (Chunk) &
                    " block=" & Greplib.Byte_Count'Image (Block);
               begin
                  Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
                  Options.Read_Block_Size := Block;
                  Options.Separator_Kind := Separator;
                  Options.Custom_Separator := Custom_Separator;
                  Options.CR_Policy := CR_Policy;

                  Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);

                  Assert (Status (Outcome) = Greplib.Results.Completed, Scenario & " completes");
                  Assert (Records_Read (Outcome) = Expected_Records, Scenario & " record count");
                  Assert
                    (Selected_Record_Count (Outcome) = Expected_Selected,
                     Scenario & " selected count");
                  Assert (Greplib.Wide_Count (Sink.Selected) = Expected_Selected, Scenario & " event count");
                  Assert (Sink.Diagnostics = 0, Scenario & " diagnostic count");
                  Assert (Bytes_Read (Outcome) = Greplib.Byte_Count (Text'Length), Scenario & " byte count");
               end;
            end loop;
         end loop;
      end Run_Case;
   begin
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);

      Run_Case
        ("lf-terminated",
         "miss" & ASCII.LF & "hit" & ASCII.LF & "xhit" & ASCII.LF,
         Greplib.Options.LF,
         ASCII.LF,
         Greplib.Options.Preserve,
         3,
         2);
      Run_Case
        ("lf-final-unterminated",
         "hit" & ASCII.LF & "miss" & ASCII.LF & "hit",
         Greplib.Options.LF,
         ASCII.LF,
         Greplib.Options.Preserve,
         3,
         2);
      Run_Case
        ("nul-separated",
         "hit" & Character'Val (0) & "miss" & Character'Val (0) & "hit",
         Greplib.Options.NUL,
         ASCII.LF,
         Greplib.Options.Preserve,
         3,
         2);
      Run_Case
        ("custom-separated",
         "hit|miss|hit|",
         Greplib.Options.Custom,
         '|',
         Greplib.Options.Preserve,
         3,
         2);
      Run_Case
        ("crlf-stripped",
         "hit" & ASCII.CR & ASCII.LF & "miss" & ASCII.CR & ASCII.LF,
         Greplib.Options.LF,
         ASCII.LF,
         Greplib.Options.Strip_Before_Line_Feed,
         2,
         1);
   end Test_Generated_Stream_Block_Matrix;

   procedure Test_Stream_Prefix_Binary_Policies is
      type Event_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         Binary : Natural := 0;
         Diagnostics : Natural := 0;
      end record;
      overriding procedure On_Event
        (Sink : in out Event_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Event_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Binary_Match then
            Sink.Binary := Sink.Binary + 1;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Diagnostic_Event then
            Sink.Diagnostics := Sink.Diagnostics + 1;
         end if;
      end On_Event;

      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : Event_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Options.Binary_Detection := Greplib.Options.Detect_Using_Prefix;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & Character'Val (0) & "x" & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options.On_Binary := Greplib.Options.Search_As_Text;
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Records_Read (Outcome) = 1, "prefix binary search-as-text replays probe bytes");
         Assert (Selected_Record_Count (Outcome) = 1, "prefix binary search-as-text selects record");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & Character'Val (0) & "x" & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options.On_Binary := Greplib.Options.Skip_Source;
         Sink := (Selected => 0, Binary => 0, Diagnostics => 0);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Records_Read (Outcome) = 0, "prefix binary skip emits no records");
         Assert (Sink.Selected = 0, "prefix binary skip emits no selected event");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & Character'Val (0) & "x" & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options.On_Binary := Greplib.Options.Fail_Source;
         Sink := (Selected => 0, Binary => 0, Diagnostics => 0);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Failed, "prefix binary fail-source fails");
         Assert (Sink.Diagnostics = 1, "prefix binary fail-source emits diagnostic");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & Character'Val (0) & "x" & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options.On_Binary := Greplib.Options.Report_Match_Without_Record;
         Sink := (Selected => 0, Binary => 0, Diagnostics => 0);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Sink.Binary = 1, "prefix binary report emits binary match");
         Assert (Sink.Selected = 0, "prefix binary report emits no raw selected record");
         Assert (Selected_Record_Count (Outcome) = 1, "prefix binary report counts selected record");
      end;

      declare
         Tiny_Block_Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF),
            Next => 1,
            Chunk => 100,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.Detect_Using_Prefix;
         Options.Read_Block_Size := 1;
         Options.On_Binary := Greplib.Options.Search_As_Text;
         Sink := (Selected => 0, Binary => 0, Diagnostics => 0);
         Greplib.Files.Search_Stream (Tiny_Block_Stream, Set, Options, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Completed, "tiny prefix probe block completes");
         Assert (Selected_Record_Count (Outcome) = 1, "tiny prefix probe block replays selected record");
         Assert (Tiny_Block_Stream.Reads >= 5, "tiny prefix probe block performs bounded repeated reads");
      end;
   end Test_Stream_Prefix_Binary_Policies;

   procedure Test_Stream_Full_Binary_Nonrecord_Modes is
      type Event_Sink is new Greplib.Events.Event_Sink with record
         Counts : Natural := 0;
         Names : Natural := 0;
         Diagnostics : Natural := 0;
      end record;
      overriding procedure On_Event
        (Sink : in out Event_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Event_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Count_Result then
            Sink.Counts := Sink.Counts + 1;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Source_Name_Result then
            Sink.Names := Sink.Names + 1;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Diagnostic_Event then
            Sink.Diagnostics := Sink.Diagnostics + 1;
         end if;
      end On_Event;

      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : Event_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF & "later" & Character'Val (0)),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options.Mode := Greplib.Options.Quiet;
         Options.On_Binary := Greplib.Options.Skip_Source;
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Reason (Outcome) = Greplib.Results.Input_Exhausted, "full binary skip suppresses quiet match");
         Assert (Selected_Record_Count (Outcome) = 1, "full binary skip preserves confirmed search facts");
         Assert (Sources_With_Results (Outcome) = 0, "full binary skip reports no source result");
         Assert (Bytes_Read (Outcome) = 10, "full binary skip reports bytes read through NUL");
         Assert (Stream.Reads > 4, "full binary skip does not stop at early quiet match");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF & "later" & Character'Val (0)),
            Next => 1,
            Chunk => 2,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Mode := Greplib.Options.Count_Selected_Records;
         Options.On_Binary := Greplib.Options.Fail_Source;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Failed, "full binary fail-source fails count mode");
         Assert (Sink.Counts = 0, "full binary fail-source emits no count");
         Assert (Sink.Diagnostics = 1, "full binary fail-source emits diagnostic");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
            "input.binary_detected",
            "full binary fail-source diagnostic identifier");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("miss" & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Mode := Greplib.Options.Source_Names_Without_Matches;
         Options.On_Binary := Greplib.Options.Skip_Source;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Sink.Names = 1, "full binary skip without binary emits source-name no-match");
         Assert (Sources_With_Results (Outcome) = 1, "full binary skip without binary records result");
      end;
   end Test_Stream_Full_Binary_Nonrecord_Modes;

   procedure Test_Stream_Full_Binary_Record_Modes is
      type Event_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         Binary : Natural := 0;
         Diagnostics : Natural := 0;
         Completed : Natural := 0;
      end record;
      overriding procedure On_Event
        (Sink : in out Event_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Event_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         case Greplib.Events.Kind (Event) is
            when Greplib.Events.Selected_Record =>
               Sink.Selected := Sink.Selected + 1;
            when Greplib.Events.Binary_Match =>
               Sink.Binary := Sink.Binary + 1;
            when Greplib.Events.Diagnostic_Event =>
               Sink.Diagnostics := Sink.Diagnostics + 1;
            when Greplib.Events.Source_Completed =>
               Sink.Completed := Sink.Completed + 1;
            when others =>
               null;
         end case;
      end On_Event;

      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : Event_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Options.Binary_Detection := Greplib.Options.Detect_Null_Byte;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF & "miss" & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options.On_Binary := Greplib.Options.Skip_Source;
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Completed, "full binary text-like record mode completes");
         Assert (Sink.Selected = 1, "full binary text-like delayed selected record flushes");
         Assert (Sink.Completed = 1, "full binary text-like emits completion");
         Assert (Stream.Reads > 4, "full binary text-like record mode uses incremental reads");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF & "later" & Character'Val (0)),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.On_Binary := Greplib.Options.Skip_Source;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Sink.Selected = 0, "full binary skip discards delayed selected record");
         Assert (Selected_Record_Count (Outcome) = 1, "full binary skip preserves selected fact");
         Assert (Sources_With_Results (Outcome) = 0, "full binary skip reports no source result");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF & "later" & Character'Val (0)),
            Next => 1,
            Chunk => 2,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.On_Binary := Greplib.Options.Report_Match_Without_Record;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Sink.Binary = 1, "full binary report emits binary match from delayed selected fact");
         Assert (Sink.Selected = 0, "full binary report emits no raw record");
         Assert (Selected_Record_Count (Outcome) = 1, "full binary report preserves selected count");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.On_Binary := Greplib.Options.Skip_Source;
         Options.Maximum_Context_Buffer_Bytes := 1;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Failed, "full binary delayed event buffer overflow fails source");
         Assert (Sink.Diagnostics = 1, "full binary delayed event buffer overflow emits diagnostic");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
            "resource.context_buffer_exceeded",
            "full binary delayed event buffer overflow diagnostic identifier");
      end;
   end Test_Stream_Full_Binary_Record_Modes;

   procedure Test_Stream_Incremental_Modes_And_Metadata is
      type Mode_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         Context : Natural := 0;
         Diagnostics : Natural := 0;
         Count_Events : Natural := 0;
         Name_Events : Natural := 0;
         Count_Value : Greplib.Wide_Count := 0;
         Last_Logical_Size : Greplib.Byte_Count := 0;
         Last_Original_Size : Greplib.Byte_Count := 0;
         Last_CR_Stripped : Boolean := False;
         Name_Matched : Boolean := False;
      end record;
      overriding procedure On_Event
        (Sink : in out Mode_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Mode_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
            Sink.Last_Logical_Size := Greplib.Events.Logical_Content_Size (Event);
            Sink.Last_Original_Size := Greplib.Events.Original_Content_Size (Event);
            Sink.Last_CR_Stripped := Greplib.Events.Carriage_Return_Stripped (Event);
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Context_Record then
            Sink.Context := Sink.Context + 1;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Diagnostic_Event then
            Sink.Diagnostics := Sink.Diagnostics + 1;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Count_Result then
            Sink.Count_Events := Sink.Count_Events + 1;
            Sink.Count_Value := Greplib.Events.Count (Event);
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Source_Name_Result then
            Sink.Name_Events := Sink.Name_Events + 1;
            Sink.Name_Matched := Greplib.Events.Had_Match (Event);
         end if;
      end On_Event;

      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : Mode_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.CR & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Options.CR_Policy := Greplib.Options.Strip_Before_Line_Feed;
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Sink.Selected = 1, "incremental stream CR-stripped record selected");
         Assert (Sink.Last_Logical_Size = 3, "incremental stream logical size strips CR");
         Assert (Sink.Last_Original_Size = 4, "incremental stream original size preserves CR");
         Assert (Sink.Last_CR_Stripped, "incremental stream reports CR stripping");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("very-long-before" & ASCII.LF & "hit" & ASCII.LF),
            Next => 1,
            Chunk => 3,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Options.Context.Before := 1;
         Options.Maximum_Context_Buffer_Bytes := 8;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert
           (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
            "incremental stream before-context byte overflow is recoverable");
         Assert (Sink.Selected = 1, "incremental stream context overflow still emits selected record");
         Assert (Sink.Context = 0, "incremental stream drops oversized before-context record");
         Assert (Sink.Diagnostics = 1, "incremental stream context overflow emits one diagnostic");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
            "resource.context_buffer_exceeded",
            "incremental stream context overflow diagnostic identifier");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & Character'Val (0) & "miss"),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Separator_Kind := Greplib.Options.NUL;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Records_Read (Outcome) = 2, "incremental stream NUL separator records");
         Assert (Selected_Record_Count (Outcome) = 1, "incremental stream NUL separator selection");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF & "hit" & ASCII.LF & "miss"),
            Next => 1,
            Chunk => 2,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Options.Mode := Greplib.Options.Count_Selected_Records;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Sink.Count_Events = 1, "incremental stream count-selected emits count event");
         Assert (Sink.Count_Value = 2, "incremental stream count-selected value");
      end;

      declare
         Span_List : Greplib.Patterns.Pattern_List;
         Span_Set : Greplib.Patterns.Compiled_Pattern_Set;
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("a a a"),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Greplib.Patterns.Append (Span_List, Greplib.Patterns.Fixed_String_Pattern ("a"));
         Span_Set := Greplib.Patterns.Compile (Span_List);
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Options.Spans := Greplib.Options.First_Span;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Span_Set, Options, Sink, Outcome);
         Assert
           (Match_Count_State (Outcome) = Greplib.Results.Lower_Bound,
            "incremental stream first-span makes match count lower bound");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit hit" & ASCII.LF),
            Next => 1,
            Chunk => 3,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Options.Mode := Greplib.Options.Count_Matches;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Sink.Count_Events = 1, "incremental stream count-matches emits count event");
         Assert (Sink.Count_Value = 2, "incremental stream count-matches value");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("miss" & ASCII.LF),
            Next => 1,
            Chunk => 2,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Binary_Detection := Greplib.Options.No_Binary_Detection;
         Options.Mode := Greplib.Options.Source_Names_Without_Matches;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Sink.Name_Events = 1, "incremental stream source-name without-match emits");
         Assert (not Sink.Name_Matched, "incremental stream source-name without-match flag");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & Character'Val (0) & "x" & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Records_Read (Outcome) = 1, "default stream binary search-as-text reads record");
         Assert (Selected_Record_Count (Outcome) = 1, "default stream binary search-as-text selects");
         Assert (Stream.Reads > 1, "default stream binary search-as-text uses short-read path");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF & "late" & ASCII.LF),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
      begin
         Options := (others => <>);
         Options.Mode := Greplib.Options.Source_Names_With_Matches;
         Sink := (others => <>);
         Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);
         Assert (Sink.Name_Events = 1, "incremental stream source-name with-match emits");
         Assert (Sink.Name_Matched, "incremental stream source-name with-match flag");
         Assert (Records_Read (Outcome) = 1, "incremental stream source-name with-match stops early");
         Assert (Sources_Completed (Outcome) = 1, "incremental stream source-name with-match completes source");
      end;
   end Test_Stream_Incremental_Modes_And_Metadata;

   procedure Test_Stream_Incremental_Context is
      type Event_Kind_Array is array (Positive range <>) of Greplib.Events.Event_Kind;
      type Record_Array is array (Positive range <>) of Greplib.Record_Number;
      type Group_Array is array (Positive range <>) of Greplib.Wide_Count;

      Expected_Kinds : constant Event_Kind_Array :=
        (Greplib.Events.Context_Record,
         Greplib.Events.Selected_Record,
         Greplib.Events.Context_Record,
         Greplib.Events.Context_Record,
         Greplib.Events.Selected_Record,
         Greplib.Events.Context_Record);
      Expected_Records : constant Record_Array := (1, 2, 3, 5, 6, 7);
      Expected_Groups : constant Group_Array := (1, 1, 1, 2, 2, 2);

      type Context_Sink is new Greplib.Events.Event_Sink with record
         Seen : Natural := 0;
         Strict : Boolean := True;
      end record;
      overriding procedure On_Event
        (Sink : in out Context_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Context_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) in Greplib.Events.Selected_Record | Greplib.Events.Context_Record then
            Sink.Seen := Sink.Seen + 1;
            if Sink.Strict then
               Assert (Sink.Seen <= Expected_Kinds'Length, "stream context emitted too many records");
               Assert (Greplib.Events.Kind (Event) = Expected_Kinds (Sink.Seen), "stream context event kind");
               Assert (Greplib.Events.Record_No (Event) = Expected_Records (Sink.Seen), "stream context record number");
               Assert (Greplib.Events.Group_Number (Event) = Expected_Groups (Sink.Seen), "stream context group");
            end if;
         end if;
      end On_Event;

      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : Context_Sink;
      Outcome : Greplib.Results.Search_Outcome;
      Stream : Short_Read_Stream :=
        (Ada.Streams.Root_Stream_Type with
         Text =>
           U.To_Unbounded_String
             ("a" & ASCII.LF &
              "hit" & ASCII.LF &
              "b" & ASCII.LF &
              "gap" & ASCII.LF &
              "c" & ASCII.LF &
              "hit" & ASCII.LF &
              "z"),
         Next => 1,
         Chunk => 1,
         Reads => 0,
         Fail_Read => 0);
   begin
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Options.Context.Before := 1;
      Options.Context.After := 1;

      Greplib.Files.Search_Stream (Stream, Set, Options, Sink, Outcome);

      Assert (Status (Outcome) = Greplib.Results.Completed, "stream context search completes");
      Assert (Sink.Seen = Expected_Kinds'Length, "stream context emits expected records");
      Assert (Selected_Record_Count (Outcome) = 2, "stream context selected count");

      declare
         Limit_Sink : Context_Sink := (Seen => 0, Strict => False);
         Limit_Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF & "after" & ASCII.LF & "hit" & ASCII.LF & "late"),
            Next => 1,
            Chunk => 1,
            Reads => 0,
            Fail_Read => 0);
         Limit_Options : Greplib.Options.Search_Options;
      begin
         Limit_Options.Context.After := 1;
         Limit_Options.Maximum_Selected_Records := 1;
         Greplib.Files.Search_Stream (Limit_Stream, Set, Limit_Options, Limit_Sink, Outcome);
         Assert (Selected_Record_Count (Outcome) = 1, "stream context selected limit count");
         Assert
           (Reason (Outcome) = Greplib.Results.Match_Limit_Reached,
            "stream context selected limit reason");
         Assert (Records_Read (Outcome) = 2, "stream context limit stops after trailing context");
         Assert (Sources_Completed (Outcome) = 1, "stream context selected limit completes source");
      end;
   end Test_Stream_Incremental_Context;

   procedure Test_Context_Groups is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Opts : Greplib.Options.Search_Options;
      Seen : Natural := 0;

      type Event_Kind_Array is array (Positive range <>) of Greplib.Events.Event_Kind;
      type Record_Array is array (Positive range <>) of Greplib.Record_Number;
      type Group_Array is array (Positive range <>) of Greplib.Wide_Count;

      Expected_Kinds : constant Event_Kind_Array :=
        (Greplib.Events.Context_Record,
         Greplib.Events.Selected_Record,
         Greplib.Events.Context_Record,
         Greplib.Events.Context_Record,
         Greplib.Events.Selected_Record,
         Greplib.Events.Context_Record);
      Expected_Records : constant Record_Array := (1, 2, 3, 5, 6, 7);
      Expected_Groups : constant Group_Array := (1, 1, 1, 2, 2, 2);
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);
      Opts.Context.Before := 1;
      Opts.Context.After := 1;
      Greplib.Collected.Search_String
        ("a" & ASCII.LF &
         "hit" & ASCII.LF &
         "b" & ASCII.LF &
         "gap" & ASCII.LF &
         "c" & ASCII.LF &
         "hit" & ASCII.LF &
         "z",
         Set, Opts, (others => <>), Result);

      for E of Result.Events loop
         if Greplib.Events.Kind (E) in Greplib.Events.Selected_Record | Greplib.Events.Context_Record then
            Seen := Seen + 1;
            Assert (Seen <= Expected_Kinds'Length, "too many record events");
            Assert (Greplib.Events.Kind (E) = Expected_Kinds (Seen), "context event kind");
            Assert (Greplib.Events.Record_No (E) = Expected_Records (Seen), "context record number");
            Assert (Greplib.Events.Group_Number (E) = Expected_Groups (Seen), "context group");
         end if;
      end loop;

      Assert (Seen = Expected_Kinds'Length, "all context records emitted");
      Assert (Selected_Record_Count (Result.Outcome) = 2, "two selected records counted");
   end Test_Context_Groups;

   procedure Test_Generated_Context_Model is
      subtype Slot is Positive range 1 .. 64;
      type Kind_Array is array (Slot) of Greplib.Events.Event_Kind;
      type Number_Array is array (Slot) of Greplib.Record_Number;
      type Group_Array is array (Slot) of Greplib.Wide_Count;
      type Boolean_Array is array (Positive range <>) of Boolean;

      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Opts : Greplib.Options.Search_Options;
      Collection : constant Greplib.Collected.Collection_Options :=
        (Maximum_Records => 1_000,
         Maximum_Bytes => Greplib.Default_Maximum_Collected_Bytes,
         Maximum_Events => 1_000,
         On_Limit => Greplib.Collected.Stop_And_Return_Partial);

      function Build_Subject (Length : Natural; Mask : Natural) return String is
         Text : String (1 .. Natural'Max (1, Length * 2)) := (others => ASCII.LF);
      begin
         if Length = 0 then
            return "";
         end if;

         for I in 1 .. Length loop
            Text ((I - 1) * 2 + 1) :=
              (if (Mask / (2 ** (I - 1))) mod 2 = 1 then 'x' else 'a');
            Text ((I - 1) * 2 + 2) := ASCII.LF;
         end loop;
         return Text (1 .. Length * 2);
      end Build_Subject;

      procedure Emit
        (Record_Index : Positive;
         Kind : Greplib.Events.Event_Kind;
         Context_Enabled : Boolean;
         Expected_Count : in out Natural;
         Expected_Kinds : in out Kind_Array;
         Expected_Numbers : in out Number_Array;
         Expected_Groups : in out Group_Array;
         Emitted : in out Boolean_Array;
         Last_Emitted : in out Natural;
         Group : in out Greplib.Wide_Count) is
      begin
         if Emitted (Record_Index) then
            return;
         end if;

         if Context_Enabled and then (Group = 0 or else Record_Index /= Last_Emitted + 1) then
            Group := Group + 1;
         end if;

         Expected_Count := Expected_Count + 1;
         Expected_Kinds (Expected_Count) := Kind;
         Expected_Numbers (Expected_Count) := Greplib.Record_Number (Record_Index);
         Expected_Groups (Expected_Count) := (if Context_Enabled then Group else 0);
         Emitted (Record_Index) := True;
         Last_Emitted := Record_Index;
      end Emit;

      procedure Build_Expected
        (Length : Natural;
         Mask : Natural;
         Before : Greplib.Wide_Count;
         After : Greplib.Wide_Count;
         Limit : Greplib.Wide_Count;
         Expected_Count : out Natural;
         Expected_Kinds : out Kind_Array;
         Expected_Numbers : out Number_Array;
         Expected_Groups : out Group_Array;
         Expected_Selected : out Greplib.Wide_Count) is
         Emitted : Boolean_Array (1 .. Natural'Max (1, Length)) := (others => False);
         Last_Emitted : Natural := 0;
         Group : Greplib.Wide_Count := 0;
         Remaining_After : Greplib.Wide_Count := 0;
         Matching : Boolean := True;
         Context_Enabled : constant Boolean := Before /= 0 or else After /= 0;
      begin
         Expected_Count := 0;
         Expected_Selected := 0;

         for I in 1 .. Length loop
            declare
               Selected : constant Boolean := (Mask / (2 ** (I - 1))) mod 2 = 1;
            begin
               if Matching and then Selected then
                  if Limit = 0 or else Expected_Selected < Limit then
                     declare
                        First_Before : constant Positive :=
                          Positive'Max
                            (1, I - Natural'Min (Natural (Before), I - 1));
                     begin
                        for J in First_Before .. I - 1 loop
                           Emit
                             (J, Greplib.Events.Context_Record, Context_Enabled, Expected_Count,
                              Expected_Kinds, Expected_Numbers, Expected_Groups,
                              Emitted, Last_Emitted, Group);
                        end loop;
                     end;

                     Emit
                       (I, Greplib.Events.Selected_Record, Context_Enabled, Expected_Count,
                        Expected_Kinds, Expected_Numbers, Expected_Groups,
                        Emitted, Last_Emitted, Group);
                     Expected_Selected := Expected_Selected + 1;
                     Remaining_After := After;
                     if Limit /= 0 and then Expected_Selected = Limit then
                        Matching := False;
                     end if;
                  end if;
               elsif Remaining_After > 0 then
                  Emit
                    (I, Greplib.Events.Context_Record, Context_Enabled, Expected_Count,
                     Expected_Kinds, Expected_Numbers, Expected_Groups,
                     Emitted, Last_Emitted, Group);
                  Remaining_After := Remaining_After - 1;
               elsif not Matching then
                  exit;
               end if;
            end;
         end loop;
      end Build_Expected;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("x"));
      Set := Greplib.Patterns.Compile (List);
      Assert (Greplib.Patterns.Is_Usable (Set), "generated context pattern compiles");

      for Length in 0 .. 10 loop
         for Mask in 0 .. 2 ** Length - 1 loop
            for Before in Greplib.Wide_Count range 0 .. 3 loop
               for After in Greplib.Wide_Count range 0 .. 3 loop
                  for Limit in Greplib.Wide_Count range 0 .. 4 loop
                     declare
                        Expected_Kinds : Kind_Array :=
                          (others => Greplib.Events.Source_Started);
                        Expected_Numbers : Number_Array := (others => 1);
                        Expected_Groups : Group_Array := (others => 0);
                        Expected_Count : Natural;
                        Expected_Selected : Greplib.Wide_Count;
                        Actual_Count : Natural := 0;
                        Scenario : constant String :=
                          " length=" & Natural'Image (Length) &
                          " mask=" & Natural'Image (Mask) &
                          " before=" & Greplib.Wide_Count'Image (Before) &
                          " after=" & Greplib.Wide_Count'Image (After) &
                          " limit=" & Greplib.Wide_Count'Image (Limit);

                        procedure Check (Condition : Boolean; Label : String) is
                        begin
                           if not Condition then
                              Ada.Text_IO.Put_Line ("generated context failure: " & Label & Scenario);
                           end if;
                           Assert (Condition, Label);
                        end Check;
                     begin
                        Build_Expected
                          (Length, Mask, Before, After, Limit, Expected_Count,
                           Expected_Kinds, Expected_Numbers, Expected_Groups,
                           Expected_Selected);

                        Opts := (others => <>);
                        Opts.Context.Before := Before;
                        Opts.Context.After := After;
                        Opts.Maximum_Selected_Records := Limit;
                        Greplib.Collected.Search_String
                          (Build_Subject (Length, Mask), Set, Opts, Collection, Result);

                        Check
                          (Selected_Record_Count (Result.Outcome) =
                           Expected_Selected,
                           "generated context selected count");
                        for E of Result.Events loop
                           if Greplib.Events.Kind (E)
                             in Greplib.Events.Selected_Record |
                                Greplib.Events.Context_Record
                           then
                              Actual_Count := Actual_Count + 1;
                              Check
                                (Actual_Count <= Expected_Count,
                                 "generated context extra record");
                              Check
                                (Greplib.Events.Kind (E) =
                                 Expected_Kinds (Actual_Count),
                                 "generated context event kind");
                              Check
                                (Greplib.Events.Record_No (E) =
                                 Expected_Numbers (Actual_Count),
                                 "generated context record number");
                              Check
                                (Greplib.Events.Group_Number (E) =
                                 Expected_Groups (Actual_Count),
                                 "generated context group number");
                           end if;
                        end loop;
                        Check
                          (Actual_Count = Expected_Count,
                           "generated context emitted record count");
                     end;
                  end loop;
               end loop;
            end loop;
         end loop;
      end loop;
   end Test_Generated_Context_Model;

   procedure Test_Selected_Record_Limit is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Opts : Greplib.Options.Search_Options;
      Selected_Events : Natural := 0;
      Context_Events : Natural := 0;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);
      Opts.Context.After := 1;
      Opts.Maximum_Selected_Records := 1;
      Greplib.Collected.Search_String
        ("hit" & ASCII.LF & "after" & ASCII.LF & "hit" & ASCII.LF & "late", Set, Opts, (others => <>), Result);

      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
            Selected_Events := Selected_Events + 1;
            Assert (Greplib.Events.Record_No (E) = 1, "selected limit emits first selected record");
         elsif Greplib.Events.Kind (E) = Greplib.Events.Context_Record then
            Context_Events := Context_Events + 1;
            Assert (Greplib.Events.Record_No (E) = 2, "selected limit emits trailing context only");
         end if;
      end loop;

      Assert (Selected_Events = 1, "selected limit caps selected events");
      Assert (Context_Events = 1, "selected limit keeps required trailing context");
      Assert (Selected_Record_Count (Result.Outcome) = 1, "selected limit caps summary count");
      Assert
        (Reason (Result.Outcome) = Greplib.Results.Match_Limit_Reached,
         "selected limit reports match-limit reason");
   end Test_Selected_Record_Limit;

   procedure Test_Binary_Policies is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Opts : Greplib.Options.Search_Options;
      Binary_Event_Count : Natural := 0;
      Record_Event_Count : Natural := 0;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);

      Greplib.Collected.Search_String ("a" & Character'Val (0) & "hit", Set, Opts, (others => <>), Result);
      Assert (Selected_Record_Count (Result.Outcome) = 1, "default binary policy searches as text");
      declare
         Summary : constant Greplib.Results.Source_Summary :=
           Greplib.Results.Element (Greplib.Results.Source_Summaries (Result.Outcome), 1);
      begin
         Assert (Greplib.Results.Binary (Summary) = Greplib.Results.Binary, "default binary source is classified");
      end;

      Opts.On_Binary := Greplib.Options.Skip_Source;
      Greplib.Collected.Search_String ("a" & Character'Val (0) & "hit", Set, Opts, (others => <>), Result);
      Assert (Records_Read (Result.Outcome) = 0, "skip binary source reads no records");
      Assert (Selected_Record_Count (Result.Outcome) = 0, "skip binary source selects no records");
      declare
         Summary : constant Greplib.Results.Source_Summary :=
           Greplib.Results.Element (Greplib.Results.Source_Summaries (Result.Outcome), 1);
      begin
         Assert (Greplib.Results.Binary (Summary) = Greplib.Results.Binary, "skip binary source is classified");
      end;

      Opts.On_Binary := Greplib.Options.Fail_Source;
      Greplib.Collected.Search_String ("a" & Character'Val (0) & "hit", Set, Opts, (others => <>), Result);
      Assert (Status (Result.Outcome) = Greplib.Results.Failed, "binary fail policy fails source");
      Assert (Natural (Diagnostics (Result.Outcome).Length) = 1, "binary fail keeps diagnostic");
      declare
         Summary : constant Greplib.Results.Source_Summary :=
           Greplib.Results.Element (Greplib.Results.Source_Summaries (Result.Outcome), 1);
      begin
         Assert (Greplib.Results.Binary (Summary) = Greplib.Results.Binary, "fail binary source is classified");
      end;

      Opts.On_Binary := Greplib.Options.Report_Match_Without_Record;
      Greplib.Collected.Search_String ("a" & Character'Val (0) & "hit", Set, Opts, (others => <>), Result);
      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Binary_Match then
            Binary_Event_Count := Binary_Event_Count + 1;
         elsif Greplib.Events.Kind (E) in Greplib.Events.Selected_Record | Greplib.Events.Context_Record then
            Record_Event_Count := Record_Event_Count + 1;
         end if;
      end loop;
      Assert (Binary_Event_Count = 1, "binary match event emitted");
      Assert (Record_Event_Count = 0, "binary match policy emits no record content");

      Opts.On_Binary := Greplib.Options.Skip_Source;
      Opts.Separator_Kind := Greplib.Options.NUL;
      Greplib.Collected.Search_String ("hit" & Character'Val (0) & "miss", Set, Opts, (others => <>), Result);
      Assert (Records_Read (Result.Outcome) = 2, "NUL separator is not binary");
      Assert (Selected_Record_Count (Result.Outcome) = 1, "NUL-separated source is searched");
      declare
         Summary : constant Greplib.Results.Source_Summary :=
           Greplib.Results.Element (Greplib.Results.Source_Summaries (Result.Outcome), 1);
      begin
         Assert (Greplib.Results.Binary (Summary) = Greplib.Results.Text_Like, "NUL-separated source is text-like");
      end;

      Opts.Binary_Detection := Greplib.Options.No_Binary_Detection;
      Opts.Separator_Kind := Greplib.Options.LF;
      Greplib.Collected.Search_String ("hit", Set, Opts, (others => <>), Result);
      declare
         Summary : constant Greplib.Results.Source_Summary :=
           Greplib.Results.Element (Greplib.Results.Source_Summaries (Result.Outcome), 1);
      begin
         Assert
           (Greplib.Results.Binary (Summary) = Greplib.Results.Not_Classified,
            "disabled binary detection leaves source unclassified");
      end;
   end Test_Binary_Policies;

   procedure Test_Source_Name_Modes is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Opts : Greplib.Options.Search_Options;
      Name_Events : Natural := 0;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);

      Opts.Mode := Greplib.Options.Source_Names_Without_Matches;
      Greplib.Collected.Search_String ("miss", Set, Opts, (others => <>), Result);
      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Source_Name_Result then
            Name_Events := Name_Events + 1;
            Assert (not Greplib.Events.Had_Match (E), "without-matches event reports no match");
         end if;
      end loop;
      Assert (Name_Events = 1, "without-matches emits source result");
      Assert (Sources_With_Results (Result.Outcome) = 1, "without-matches counts source result");
      Assert (Records_Read (Result.Outcome) = 1, "without-matches consumes complete one-record source");

      Name_Events := 0;
      Opts.Mode := Greplib.Options.Source_Names_With_Matches;
      Greplib.Collected.Search_String ("hit" & ASCII.LF & "miss" & ASCII.LF & "hit", Set, Opts, (others => <>), Result);
      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Source_Name_Result then
            Name_Events := Name_Events + 1;
            Assert (Greplib.Events.Had_Match (E), "with-matches event reports match");
         end if;
      end loop;
      Assert (Name_Events = 1, "with-matches emits source result");
      Assert (Sources_With_Results (Result.Outcome) = 1, "with-matches counts source result");
      Assert (Records_Read (Result.Outcome) = 1, "with-matches stops after first selected record");

      Name_Events := 0;
      Opts.Mode := Greplib.Options.Source_Names_Without_Matches;
      Greplib.Collected.Search_String ("miss" & ASCII.LF & "miss", Set, Opts, (others => <>), Result);
      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Source_Name_Result then
            Name_Events := Name_Events + 1;
         end if;
      end loop;
      Assert (Name_Events = 1, "without-matches emits after complete no-match source");
      Assert (Records_Read (Result.Outcome) = 2, "without-matches consumes complete no-match source");
   end Test_Source_Name_Modes;

   procedure Test_Count_And_Quiet_Modes is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Options : Greplib.Options.Search_Options;
      Count_Events : Natural := 0;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("a"));
      Set := Greplib.Patterns.Compile (List);

      Options.Mode := Greplib.Options.Count_Selected_Records;
      Greplib.Collected.Search_String ("a" & ASCII.LF & "b" & ASCII.LF & "a", Set, Options, (others => <>), Result);
      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Count_Result then
            Count_Events := Count_Events + 1;
            Assert (Greplib.Events.Count (E) = 2, "count-selected event value");
         end if;
      end loop;
      Assert (Count_Events = 1, "count-selected emits one count event");

      Count_Events := 0;
      Options.Mode := Greplib.Options.Count_Matches;
      Greplib.Collected.Search_String ("a a", Set, Options, (others => <>), Result);
      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Count_Result then
            Count_Events := Count_Events + 1;
            Assert (Greplib.Events.Count (E) = 2, "count-matches event value");
         end if;
      end loop;
      Assert (Count_Events = 1, "count-matches emits one count event");

      Options.Mode := Greplib.Options.Quiet;
      Greplib.Collected.Search_String ("a" & ASCII.LF & "a", Set, Options, (others => <>), Result);
      Assert (Reason (Result.Outcome) = Greplib.Results.Quiet_Match_Found, "quiet reports match reason");
      Assert (Sources_With_Results (Result.Outcome) = 1, "quiet match counts source result");
      Assert (Records_Read (Result.Outcome) = 1, "quiet stops after first selected record");
   end Test_Count_And_Quiet_Modes;

   procedure Test_Oversized_Record_Policies is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Opts : Greplib.Options.Search_Options;
      Record_Event_Count : Natural := 0;
      Diagnostic_Event_Count : Natural := 0;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);
      Opts.Maximum_Record_Size := 3;

      Greplib.Collected.Search_String ("toolong" & ASCII.LF & "hit", Set, Opts, (others => <>), Result);
      Assert
        (Status (Result.Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "report-and-skip completes with recoverable diagnostic");
      Assert (Records_Read (Result.Outcome) = 2, "oversized record is counted once");
      Assert (Selected_Record_Count (Result.Outcome) = 1, "later record is searched");
      Assert (Natural (Diagnostics (Result.Outcome).Length) = 1, "report-and-skip retains diagnostic");

      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
            Record_Event_Count := Record_Event_Count + 1;
            Assert (Greplib.Events.Record_No (E) = 2, "later record number is preserved");
         elsif Greplib.Events.Kind (E) = Greplib.Events.Diagnostic_Event then
            Diagnostic_Event_Count := Diagnostic_Event_Count + 1;
         end if;
      end loop;
      Assert (Record_Event_Count = 1, "only later selected record emitted");
      Assert (Diagnostic_Event_Count = 1, "oversized diagnostic event emitted");

      Opts.On_Oversized_Record := Greplib.Options.Skip_Record;
      Greplib.Collected.Search_String ("toolong" & ASCII.LF & "hit", Set, Opts, (others => <>), Result);
      Assert (Records_Read (Result.Outcome) = 2, "skip counts oversized record");
      Assert (Selected_Record_Count (Result.Outcome) = 1, "skip resynchronizes after record");
      Assert (Natural (Diagnostics (Result.Outcome).Length) = 0, "skip does not retain diagnostic");

      Opts.On_Oversized_Record := Greplib.Options.Fail_Source;
      Greplib.Collected.Search_String ("toolong" & ASCII.LF & "hit", Set, Opts, (others => <>), Result);
      Assert (Status (Result.Outcome) = Greplib.Results.Failed, "oversized fail-source fails");
      Assert (Records_Read (Result.Outcome) = 1, "fail-source stops at oversized record");
      Assert (Selected_Record_Count (Result.Outcome) = 0, "fail-source does not search later records");
   end Test_Oversized_Record_Policies;

   procedure Test_Diagnostic_Retention_Limit is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Options : Greplib.Options.Search_Options;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("x"));
      Set := Greplib.Patterns.Compile (List);
      Options.Maximum_Record_Size := 1;
      Options.Maximum_Retained_Diagnostics := 1;

      Greplib.Collected.Search_String ("long" & ASCII.LF & "wide", Set, Options, (others => <>), Result);

      Assert
        (Status (Result.Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "diagnostic retention limit keeps recoverable status");
      Assert (Diagnostic_Count (Result.Outcome) = 2, "all diagnostics counted beyond retention");
      Assert (Natural (Diagnostics (Result.Outcome).Length) = 1, "diagnostic retention is bounded");
      Assert (Diagnostics_Truncated (Result.Outcome), "diagnostic retention marks truncation");
   end Test_Diagnostic_Retention_Limit;

   procedure Test_Diagnostic_Code_Accessors is
      D : constant Greplib.Diagnostics.Diagnostic :=
        Greplib.Diagnostics.Make
          (Greplib.Diagnostics.Resource_Match_Span_Limit_Exceeded,
           Greplib.Diagnostics.Recoverable_Error,
           "span cap",
           Offset => 42);
      D2 : constant Greplib.Diagnostics.Diagnostic :=
        Greplib.Diagnostics.Make
          (Greplib.Diagnostics.Resource_Context_Buffer_Exceeded,
           Greplib.Diagnostics.Warning,
           "context cap",
           Path => "fixtures/input.txt",
           Filesystem_Operation => "read",
           Has_Record => True,
           Record_No => 7,
           Has_Native_Error => True,
           Native_Error => 13,
           Exception_Name => "ADA.IO_EXCEPTIONS.USE_ERROR",
           Exception_Message => "permission denied",
           Has_Numeric_Limit => True,
           Numeric_Limit => 1024,
           Has_Observed_Size => True,
           Observed_Size => 2048);
   begin
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (D)) =
         "resource.match_span_limit_exceeded",
         "diagnostic identifier accessor is stable");
      Assert
        (Greplib.Diagnostics.Domain (Greplib.Diagnostics.Code (D)) = Greplib.Diagnostics.Resource_Limit,
         "diagnostic domain accessor");
      Assert (Greplib.Diagnostics.Level (D) = Greplib.Diagnostics.Recoverable_Error, "diagnostic severity accessor");
      Assert (Greplib.Diagnostics.Message (D) = "span cap", "diagnostic message accessor");
      Assert
        (Greplib.Diagnostics.Debug_Image (D) =
         "resource.match_span_limit_exceeded: span cap",
         "diagnostic debug image includes identifier and message");
      Assert (not Greplib.Diagnostics.Has_Path (D), "diagnostic path defaults absent");
      Assert (Greplib.Diagnostics.Has_Path (D2), "diagnostic path presence accessor");
      Assert (Greplib.Diagnostics.Path (D2) = "fixtures/input.txt", "diagnostic path accessor");
      Assert
        (Greplib.Diagnostics.Has_Filesystem_Operation (D2)
         and then Greplib.Diagnostics.Filesystem_Operation (D2) = "read",
         "diagnostic filesystem operation accessor");
      Assert
        (Greplib.Diagnostics.Has_Record_Number (D2) and then Greplib.Diagnostics.Record_No (D2) = 7,
         "diagnostic record number accessor");
      Assert
        (Greplib.Diagnostics.Has_Native_Error (D2) and then Greplib.Diagnostics.Native_Error (D2) = 13,
         "diagnostic native error accessor");
      Assert
        (Greplib.Diagnostics.Has_Exception_Name (D2)
         and then Greplib.Diagnostics.Exception_Name (D2) = "ADA.IO_EXCEPTIONS.USE_ERROR",
         "diagnostic exception name accessor");
      Assert
        (Greplib.Diagnostics.Has_Exception_Message (D2)
         and then Greplib.Diagnostics.Exception_Message (D2) = "permission denied",
         "diagnostic exception message accessor");
      Assert
        (Greplib.Diagnostics.Has_Numeric_Limit (D2) and then Greplib.Diagnostics.Numeric_Limit (D2) = 1024,
         "diagnostic numeric limit accessor");
      Assert
        (Greplib.Diagnostics.Has_Observed_Size (D2) and then Greplib.Diagnostics.Observed_Size (D2) = 2048,
         "diagnostic observed size accessor");
   end Test_Diagnostic_Code_Accessors;

   procedure Test_Span_Controls is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Result : Greplib.Collected.Collected_Result;
      Opts : Greplib.Options.Search_Options;
      Saw_Selected : Boolean := False;
      Saw_Diagnostic : Boolean := False;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("a"));
      Set := Greplib.Patterns.Compile (List);

      Opts.Spans := Greplib.Options.First_Span;
      Greplib.Collected.Search_String ("a a a", Set, Opts, (others => <>), Result);
      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
            Assert (Natural (Greplib.Events.Spans (E).Length) = 1, "first-span keeps one span");
            Assert (not Greplib.Events.Spans_Complete (E), "first-span reports incomplete spans");
            Assert (Greplib.Events.Spans (E).Element (1).First_Byte = 0, "first-span start");
            Saw_Selected := True;
         end if;
      end loop;
      Assert (Saw_Selected, "first-span selected event observed");
      Assert
        (Match_Count_State (Result.Outcome) = Greplib.Results.Lower_Bound,
         "first-span makes summary match count a lower bound");
      declare
         Summary : constant Greplib.Results.Source_Summary :=
           Greplib.Results.Element (Greplib.Results.Source_Summaries (Result.Outcome), 1);
      begin
         Assert
           (Greplib.Results.Truncation (Summary).Match_Spans,
            "first-span records source span truncation");
      end;

      Opts.Spans := Greplib.Options.All_Spans;
      Opts.Maximum_Match_Spans_Per_Record := 2;
      Greplib.Collected.Search_String ("a a a", Set, Opts, (others => <>), Result);
      Saw_Selected := False;
      for E of Result.Events loop
         if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
            Assert (Natural (Greplib.Events.Spans (E).Length) = 2, "span limit keeps configured count");
            Assert (not Greplib.Events.Spans_Complete (E), "span limit reports incomplete spans");
            Saw_Selected := True;
         elsif Greplib.Events.Kind (E) = Greplib.Events.Diagnostic_Event then
            Saw_Diagnostic := True;
         end if;
      end loop;
      Assert (Saw_Selected, "span-limit selected event observed");
      Assert (Saw_Diagnostic, "span-limit diagnostic emitted");
      Assert (Natural (Diagnostics (Result.Outcome).Length) = 1, "span-limit diagnostic retained");
      Assert
        (Match_Count_State (Result.Outcome) = Greplib.Results.Lower_Bound,
         "span-limit makes match count a lower bound");
      Assert
        (Status (Result.Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "span-limit makes outcome recoverable");
      declare
         Summary : constant Greplib.Results.Source_Summary :=
           Greplib.Results.Element (Greplib.Results.Source_Summaries (Result.Outcome), 1);
      begin
         Assert
           (Greplib.Results.Truncation (Summary).Match_Spans,
            "span limit records source span truncation");
      end;

      Opts.Mode := Greplib.Options.Count_Matches;
      Greplib.Collected.Search_String ("a a a", Set, Opts, (others => <>), Result);
      Assert (Match_Count (Result.Outcome) = 2, "count-matches reports retained lower-bound count");
      Assert
        (Match_Count_State (Result.Outcome) = Greplib.Results.Lower_Bound,
         "count-matches span limit is lower bound");
      Assert
        (Status (Result.Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "count-matches span limit is recoverable");

      declare
         Mixed : Greplib.Patterns.Pattern_List;
         Mixed_Set : Greplib.Patterns.Compiled_Pattern_Set;
         Saw_Mixed : Boolean := False;
      begin
         Greplib.Patterns.Append (Mixed, Greplib.Patterns.Fixed_String_Pattern ("a"));
         Greplib.Patterns.Append (Mixed, Greplib.Patterns.Regular_Expression_Pattern ("a+"));
         Mixed_Set := Greplib.Patterns.Compile (Mixed);
         Opts := (others => <>);
         Opts.Spans := Greplib.Options.All_Spans;
         Greplib.Collected.Search_String ("aaa", Mixed_Set, Opts, (others => <>), Result);
         for E of Result.Events loop
            if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
               Assert (Natural (Greplib.Events.Spans (E).Length) = 1, "mixed patterns emit one arbitration span");
               Assert (Greplib.Events.Spans (E).Element (1).Pattern = 2, "mixed patterns choose longest span");
               Assert (Greplib.Events.Spans (E).Element (1).First_Byte = 0, "mixed longest span starts at zero");
               Assert
                 (Greplib.Events.Spans (E).Element (1).Last_Byte_Exclusive = 3,
                  "mixed longest span covers subject");
               Saw_Mixed := True;
            end if;
         end loop;
         Assert (Saw_Mixed, "mixed fixed-regex arbitration event observed");
      end;

      declare
         Duplicate : Greplib.Patterns.Pattern_List;
         Duplicate_Set : Greplib.Patterns.Compiled_Pattern_Set;
         Saw_Duplicate : Boolean := False;
      begin
         Greplib.Patterns.Append (Duplicate, Greplib.Patterns.Regular_Expression_Pattern ("a+"));
         Greplib.Patterns.Append (Duplicate, Greplib.Patterns.Fixed_String_Pattern ("aaa"));
         Duplicate_Set := Greplib.Patterns.Compile (Duplicate);
         Opts := (others => <>);
         Opts.Spans := Greplib.Options.All_Spans;
         Greplib.Collected.Search_String ("aaa", Duplicate_Set, Opts, (others => <>), Result);
         for E of Result.Events loop
            if Greplib.Events.Kind (E) = Greplib.Events.Selected_Record then
               Assert (Natural (Greplib.Events.Spans (E).Length) = 1, "duplicate range emits one span");
               Assert (Greplib.Events.Spans (E).Element (1).Pattern = 1, "duplicate range keeps lowest index");
               Saw_Duplicate := True;
            end if;
         end loop;
         Assert (Saw_Duplicate, "duplicate range arbitration event observed");
      end;
   end Test_Span_Controls;

   procedure Test_Generated_Resource_Boundaries is
      type Limit_Array is array (Positive range <>) of Greplib.Wide_Count;
      Limits : constant Limit_Array := (2, 3, 4);
      Result : Greplib.Collected.Collected_Result;
   begin
      for Limit of Limits loop
         declare
            Patterns : Greplib.Patterns.Pattern_List;
            Set : Greplib.Patterns.Compiled_Pattern_Set;
            Opts : Greplib.Options.Search_Options;
         begin
            Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
            Set := Greplib.Patterns.Compile (Patterns);
            Opts.Maximum_Record_Size := Greplib.Byte_Count (Limit);
            Greplib.Collected.Search_String ("hit", Set, Opts, (others => <>), Result);
            if Limit < 3 then
               Assert
                 (Status (Result.Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
                  "generated record-size below boundary is recoverable");
               Assert (Selected_Record_Count (Result.Outcome) = 0, "generated record-size below skips match");
               Assert (Diagnostic_Count (Result.Outcome) = 1, "generated record-size below diagnostic");
            else
               Assert (Status (Result.Outcome) = Greplib.Results.Completed, "generated record-size boundary completes");
               Assert (Selected_Record_Count (Result.Outcome) = 1, "generated record-size boundary selects");
               Assert (Diagnostic_Count (Result.Outcome) = 0, "generated record-size boundary no diagnostic");
            end if;
         end;
      end loop;

      for Limit of Limits loop
         declare
            Patterns : Greplib.Patterns.Pattern_List;
            Set : Greplib.Patterns.Compiled_Pattern_Set;
            Opts : Greplib.Options.Search_Options;
         begin
            Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("a"));
            Set := Greplib.Patterns.Compile (Patterns);
            Opts.Spans := Greplib.Options.All_Spans;
            Opts.Maximum_Match_Spans_Per_Record := Limit;
            Greplib.Collected.Search_String ("a a a", Set, Opts, (others => <>), Result);
            if Limit < 3 then
               Assert
                 (Status (Result.Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
                  "generated span-limit below boundary is recoverable");
               Assert
                 (Match_Count_State (Result.Outcome) = Greplib.Results.Lower_Bound,
                  "generated span-limit below lower-bound count");
               Assert (Diagnostic_Count (Result.Outcome) = 1, "generated span-limit below diagnostic");
            else
               Assert (Status (Result.Outcome) = Greplib.Results.Completed, "generated span-limit boundary completes");
               Assert
                 (Match_Count_State (Result.Outcome) = Greplib.Results.Exact,
                  "generated span-limit boundary exact count");
               Assert (Diagnostic_Count (Result.Outcome) = 0, "generated span-limit boundary no diagnostic");
            end if;
         end;
      end loop;

      for Limit in Greplib.Wide_Count range 0 .. 2 loop
         declare
            Patterns : Greplib.Patterns.Pattern_List;
            Set : Greplib.Patterns.Compiled_Pattern_Set;
            Opts : Greplib.Options.Search_Options;
         begin
            Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("x"));
            Set := Greplib.Patterns.Compile (Patterns);
            Opts.Maximum_Record_Size := 1;
            Opts.Maximum_Retained_Diagnostics := Limit;
            Greplib.Collected.Search_String ("long" & ASCII.LF & "wide", Set, Opts, (others => <>), Result);
            Assert
              (Status (Result.Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
               "generated diagnostic-retention boundary recoverable");
            Assert (Diagnostic_Count (Result.Outcome) = 2, "generated diagnostic-retention counts all");
            Assert
              (Greplib.Wide_Count (Diagnostics (Result.Outcome).Length) =
               Greplib.Wide_Count'Min (Limit, 2),
               "generated diagnostic-retention retained count");
            Assert
              (Diagnostics_Truncated (Result.Outcome) = (Limit < 2),
               "generated diagnostic-retention truncation flag");
         end;
      end loop;

      for Limit in Greplib.Wide_Count range 1 .. 3 loop
         declare
            Patterns : Greplib.Patterns.Pattern_List;
            Set : Greplib.Patterns.Compiled_Pattern_Set;
            Opts : Greplib.Options.Search_Options;
            Collection : Greplib.Collected.Collection_Options := (others => <>);
         begin
            Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
            Set := Greplib.Patterns.Compile (Patterns);
            Collection.Maximum_Records := Limit;
            Collection.Maximum_Bytes := Greplib.Default_Maximum_Collected_Bytes;
            Greplib.Collected.Search_String
              ("hit" & ASCII.LF & "hit", Set, Opts, Collection, Result);
            if Limit < 2 then
               Assert (Result.Truncated, "generated collected-record below boundary truncates");
               Assert
                 (Reason (Result.Outcome) = Greplib.Results.Result_Limit_Reached,
                  "generated collected-record below boundary reason");
            else
               Assert (not Result.Truncated, "generated collected-record boundary does not truncate");
               Assert
                 (Selected_Record_Count (Result.Outcome) = 2,
                  "generated collected-record boundary keeps selected count");
            end if;
         end;
      end loop;

      for Limit in Greplib.Wide_Count range 2 .. 4 loop
         declare
            Patterns : Greplib.Patterns.Pattern_List;
            Set : Greplib.Patterns.Compiled_Pattern_Set;
            Opts : Greplib.Options.Search_Options;
            Collection : Greplib.Collected.Collection_Options := (others => <>);
         begin
            Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
            Set := Greplib.Patterns.Compile (Patterns);
            Collection.Maximum_Records := Greplib.Default_Maximum_Collected_Records;
            Collection.Maximum_Bytes := Greplib.Default_Maximum_Collected_Bytes;
            Collection.Maximum_Events := Limit;
            Greplib.Collected.Search_String ("hit", Set, Opts, Collection, Result);

            if Limit < 3 then
               Assert (Result.Truncated, "generated collected-event below boundary truncates");
               Assert (Result.Truncation.Events, "generated collected-event below reports event reason");
               Assert (not Result.Truncation.Records, "generated collected-event below excludes record reason");
               Assert (not Result.Truncation.Bytes, "generated collected-event below excludes byte reason");
               Assert
                 (Reason (Result.Outcome) = Greplib.Results.Result_Limit_Reached,
                  "generated collected-event below boundary reason");
               Assert
                 (Greplib.Wide_Count (Result.Events.Length) = Limit,
                  "generated collected-event below retains limit count");
            else
               Assert (not Result.Truncated, "generated collected-event boundary does not truncate");
               Assert
                 (Greplib.Wide_Count (Result.Events.Length) = 3,
                  "generated collected-event boundary retains lifecycle events");
               Assert
                 (Selected_Record_Count (Result.Outcome) = 1,
                  "generated collected-event boundary keeps selected count");
            end if;
         end;
      end loop;

      for Limit in Greplib.Byte_Count range 218 .. 220 loop
         declare
            Patterns : Greplib.Patterns.Pattern_List;
            Set : Greplib.Patterns.Compiled_Pattern_Set;
            Opts : Greplib.Options.Search_Options;
            Collection : Greplib.Collected.Collection_Options := (others => <>);
         begin
            Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
            Set := Greplib.Patterns.Compile (Patterns);
            Collection.Maximum_Records := Greplib.Default_Maximum_Collected_Records;
            Collection.Maximum_Events := Greplib.Default_Maximum_Collected_Records;
            Collection.Maximum_Bytes := Limit;
            Greplib.Collected.Search_String ("hit", Set, Opts, Collection, Result);

            if Limit < 219 then
               Assert (Result.Truncated, "generated collected-byte below boundary truncates");
               Assert (Result.Truncation.Bytes, "generated collected-byte below reports byte reason");
               Assert (not Result.Truncation.Records, "generated collected-byte below excludes record reason");
               Assert (not Result.Truncation.Events, "generated collected-byte below excludes event reason");
               Assert
                 (Reason (Result.Outcome) = Greplib.Results.Result_Limit_Reached,
                  "generated collected-byte below boundary reason");
               Assert
                 (Natural (Result.Events.Length) = 2,
                  "generated collected-byte below retains events before overflow");
            else
               Assert (not Result.Truncated, "generated collected-byte boundary does not truncate");
               Assert
                 (Greplib.Wide_Count (Result.Events.Length) = 3,
                  "generated collected-byte boundary retains lifecycle events");
               Assert
                 (Selected_Record_Count (Result.Outcome) = 1,
                  "generated collected-byte boundary keeps selected count");
            end if;
         end;
      end loop;
   end Test_Generated_Resource_Boundaries;

   procedure Test_Callback_Stop_Current is
      type Stop_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         Completed : Natural := 0;
      end record;
      overriding procedure On_Event
        (Sink : in out Stop_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Stop_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
            Action := Greplib.Events.Stop_Current_Source;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Source_Completed then
            Sink.Completed := Sink.Completed + 1;
         end if;
      end On_Event;

      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Opts : Greplib.Options.Search_Options;
      Sink : Stop_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);

      Greplib.Search.Search_String
        ("hit" & ASCII.LF & "hit" & ASCII.LF & "hit", Set, Opts, Sink, Outcome);

      Assert (Sink.Selected = 1, "stop-current suppresses later selected callbacks");
      Assert (Sink.Completed = 0, "stop-current suppresses source-completed callback");
      Assert (Status (Outcome) = Greplib.Results.Completed, "stop-current returns completed outcome");
      Assert
        (Reason (Outcome) = Greplib.Results.Callback_Stopped_Source,
         "stop-current completion reason");
      Assert (Selected_Record_Count (Outcome) = 1, "stop-current summary reports delivered selection");
      Assert (Sources_Completed (Outcome) = 0, "stop-current source is partial");
   end Test_Callback_Stop_Current;

   procedure Test_Callback_Stop_All is
      type Stop_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         Completed : Natural := 0;
      end record;
      overriding procedure On_Event
        (Sink : in out Stop_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Stop_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
            Action := Greplib.Events.Stop_All_Search;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Source_Completed then
            Sink.Completed := Sink.Completed + 1;
         end if;
      end On_Event;

      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Opts : Greplib.Options.Search_Options;
      Sink : Stop_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);

      Greplib.Search.Search_String
        ("hit" & ASCII.LF & "hit" & ASCII.LF & "hit", Set, Opts, Sink, Outcome);

      Assert (Sink.Selected = 1, "stop-all suppresses later selected callbacks");
      Assert (Sink.Completed = 0, "stop-all suppresses source-completed callback");
      Assert (Status (Outcome) = Greplib.Results.Cancelled, "stop-all returns cancelled outcome");
      Assert
        (Reason (Outcome) = Greplib.Results.Callback_Stopped_Search,
         "stop-all completion reason");
      Assert (Selected_Record_Count (Outcome) = 1, "stop-all summary reports delivered selection");
      Assert (Sources_Completed (Outcome) = 0, "stop-all source is partial");
   end Test_Callback_Stop_All;

   procedure Test_Search_Option_Validation_No_Input is
      type Counting_Sink is new Greplib.Events.Event_Sink with record
         Events : Natural := 0;
      end record;
      overriding procedure On_Event
        (Sink : in out Counting_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Counting_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Sink.Events := Sink.Events + 1;
         Action := Greplib.Events.Continue_Search;
      end On_Event;

      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Opts : Greplib.Options.Search_Options;
      Sink : Counting_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);

      declare
         Search_Diagnostics : Greplib.Diagnostics.Diagnostic_List := Greplib.Search.Validate (Set, Opts);
      begin
         Assert (Search_Diagnostics.Is_Empty, "valid in-memory search options validate directly");
      end;

      Opts.Mode := Greplib.Options.Count_Matches;
      Opts.Invert_Match := True;
      Opts.Context.Before := 1;
      Opts.On_Binary := Greplib.Options.Report_Match_Without_Record;
      Opts.Read_Block_Size := 0;

      declare
         Search_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List := Greplib.Search.Validate (Set, Opts);
      begin
         Assert (Natural (Search_Diagnostics.Length) = 5, "direct search validation aggregates option errors");
         for I in 1 .. 5 loop
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Search_Diagnostics.Element (I))) =
               "configuration.invalid_option_combination",
               "direct search validation reports configuration diagnostics");
         end loop;
      end;

      Greplib.Search.Search_String ("hit", Set, Opts, Sink, Outcome);

      Assert (Status (Outcome) = Greplib.Results.Failed, "invalid search options fail validation");
      Assert (Diagnostic_Count (Outcome) = 5, "independent search option errors are retained");
      Assert (Natural (Diagnostics (Outcome).Length) = 5, "invalid search options retain diagnostics");
      Assert (Records_Read (Outcome) = 0, "invalid search options consume no records");
      Assert (Sink.Events = 0, "invalid search options emit no source events");

      Opts.Maximum_Retained_Diagnostics := 0;
      Sink := (Events => 0);
      Greplib.Search.Search_String ("hit", Set, Opts, Sink, Outcome);
      Assert (Diagnostic_Count (Outcome) = 5, "invalid search options zero-retention counts diagnostics");
      Assert (Natural (Diagnostics (Outcome).Length) = 0, "invalid search options zero-retention retains none");
      Assert (Diagnostics_Truncated (Outcome), "invalid search options zero-retention marks truncation");
      Assert (Sink.Events = 0, "invalid search options zero-retention emits no source events");

      declare
         Source : aliased Greplib.Cancellation.Cancellation_Source;
      begin
         Source.Request;
         Opts := (others => <>);
         Sink := (Events => 0);
         Greplib.Search.Search_String ("hit", Set, Opts, Sink, Outcome, Greplib.Cancellation.Token (Source));
         Assert (Status (Outcome) = Greplib.Results.Cancelled, "pre-cancelled string search is cancelled");
         Assert (Cancellation_Observed (Outcome), "pre-cancelled string search observes cancellation");
         Assert (Records_Read (Outcome) = 0, "pre-cancelled string search consumes no records");
         Assert (Sink.Events = 0, "pre-cancelled string search emits no source events");
      end;

      declare
         Bad_List : Greplib.Patterns.Pattern_List;
         Bad_Set : Greplib.Patterns.Compiled_Pattern_Set;
      begin
         Greplib.Patterns.Append (Bad_List, Greplib.Patterns.Regular_Expression_Pattern ("["));
         Bad_Set := Greplib.Patterns.Compile (Bad_List);
         Opts := (others => <>);
         declare
            Search_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
              Greplib.Search.Validate (Bad_Set, Opts);
         begin
            Assert (Natural (Search_Diagnostics.Length) = 1, "direct search validation counts unusable patterns");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Search_Diagnostics.Element (1))) =
               "configuration.invalid_option_combination",
               "direct search validation reports unusable pattern set");
         end;

         Opts.Read_Block_Size := 0;
         declare
            Search_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
              Greplib.Search.Validate (Bad_Set, Opts);
         begin
            Assert (Natural (Search_Diagnostics.Length) = 2, "direct search validation aggregates pattern/options");
            for I in 1 .. 2 loop
               Assert
                 (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Search_Diagnostics.Element (I))) =
                  "configuration.invalid_option_combination",
                  "direct search validation keeps stable diagnostic identifiers");
            end loop;
         end;

         Sink := (Events => 0);
         Greplib.Search.Search_String ("hit", Bad_Set, Opts, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Failed, "invalid pattern and options fail before input");
         Assert (Diagnostic_Count (Outcome) = 2, "invalid pattern and options both counted");
         Assert (Records_Read (Outcome) = 0, "invalid pattern and options consume no records");
         Assert (Sink.Events = 0, "invalid pattern and options emit no source events");
      end;
   end Test_Search_Option_Validation_No_Input;

   procedure Test_Collected_Limits is
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Greplib.Collected.Collection_Options;
      Result : Greplib.Collected.Collected_Result;

      function Retained_Record_Events return Natural is
         Count : Natural := 0;
      begin
         for E of Result.Events loop
            if Greplib.Events.Kind (E) in
              Greplib.Events.Selected_Record | Greplib.Events.Context_Record | Greplib.Events.Binary_Match
            then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Retained_Record_Events;

      procedure Local_Ensure_Directory (Name : String) is
      begin
         if not PF.Directory_Exists (Name) then
            Ada.Directories.Create_Directory (Name);
         end if;
      end Local_Ensure_Directory;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);

      declare
         Collection_Diagnostics : Greplib.Diagnostics.Diagnostic_List :=
           Greplib.Collected.Validate (Collection);
      begin
         Assert (Collection_Diagnostics.Is_Empty, "default collection options validate directly");
      end;

      Collection.Maximum_Records := 1;
      Collection.On_Limit := Greplib.Collected.Stop_And_Return_Partial;
      Greplib.Collected.Search_String
        ("hit" & ASCII.LF & "hit" & ASCII.LF & "hit", Set, Search_Options, Collection, Result);
      Assert (Result.Truncated, "stop-and-return collection reports truncation");
      Assert (Result.Truncation.Records, "stop-and-return collection records record-limit reason");
      Assert (not Result.Truncation.Bytes, "record-limit collection does not report byte-limit reason");
      Assert (not Result.Truncation.Events, "record-limit collection does not report event-limit reason");
      Assert (Retained_Record_Events = 1, "stop-and-return retains configured record count");
      Assert (Status (Result.Outcome) = Greplib.Results.Completed, "collection stop is not external cancellation");
      Assert
        (Reason (Result.Outcome) = Greplib.Results.Result_Limit_Reached,
         "collection stop reports result limit");
      Assert (not Cancellation_Observed (Result.Outcome), "collection stop clears cancellation marker");
      declare
         Summary : constant Greplib.Results.Source_Summary :=
           Greplib.Results.Element (Greplib.Results.Source_Summaries (Result.Outcome), 1);
      begin
         Assert
           (Greplib.Results.Reason (Summary) = Greplib.Results.Result_Limit_Reached,
            "collection stop source summary reports result limit");
      end;

      Collection.On_Limit := Greplib.Collected.Continue_Without_Collecting;
      Greplib.Collected.Search_String
        ("hit" & ASCII.LF & "hit" & ASCII.LF & "hit", Set, Search_Options, Collection, Result);
      Assert (Result.Truncated, "continue-without-collecting reports truncation");
      Assert (Result.Truncation.Records, "continue-without-collecting records record-limit reason");
      Assert (Retained_Record_Events = 1, "continue-without-collecting retains configured record count");
      Assert (Status (Result.Outcome) = Greplib.Results.Completed, "continued collection limit completes search");
      Assert
        (Reason (Result.Outcome) = Greplib.Results.Result_Limit_Reached,
         "continued collection limit reports result limit");
      Assert (Selected_Record_Count (Result.Outcome) = 3, "continued collection limit completes summaries");
      declare
         Summary : constant Greplib.Results.Source_Summary :=
           Greplib.Results.Element (Greplib.Results.Source_Summaries (Result.Outcome), 1);
      begin
         Assert
           (Greplib.Results.Reason (Summary) = Greplib.Results.Result_Limit_Reached,
            "continued collection source summary reports result limit");
      end;

      Collection := (others => <>);
      Collection.Maximum_Records := 0;
      declare
         Collection_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
           Greplib.Collected.Validate (Collection);
      begin
         Assert
           (Natural (Collection_Diagnostics.Length) = 1,
            "direct collection validation counts zero record limit");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Collection_Diagnostics.Element (1))) =
            "configuration.invalid_option_combination",
            "direct collection validation reports invalid option combination");
      end;
      Greplib.Collected.Search_String ("hit", Set, Search_Options, Collection, Result);
      Assert (Status (Result.Outcome) = Greplib.Results.Failed, "zero collection records fails validation");
      Assert (Natural (Result.Events.Length) = 0, "zero collection records retains no events");
      Assert (not Result.Truncated, "invalid collection limits are validation errors, not truncation");
      Assert (Records_Read (Result.Outcome) = 0, "zero collection records consumes no input");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Result.Outcome).Element (1))) =
         "configuration.invalid_option_combination",
         "zero collection records diagnostic identifier");

      Collection := (others => <>);
      Collection.Maximum_Bytes := 0;
      Greplib.Collected.Search_String ("hit", Set, Search_Options, Collection, Result);
      Assert (Status (Result.Outcome) = Greplib.Results.Failed, "zero collection bytes fails validation");

      Collection := (others => <>);
      Collection.Maximum_Records := 0;
      Collection.Maximum_Bytes := 0;
      Collection.Maximum_Events := 0;
      declare
         Collection_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
           Greplib.Collected.Validate (Collection);
      begin
         Assert
           (Natural (Collection_Diagnostics.Length) = 3,
            "direct collection validation aggregates independent zero limits");
         for I in 1 .. 3 loop
            Assert
              (Greplib.Diagnostics.Identifier
                 (Greplib.Diagnostics.Code (Collection_Diagnostics.Element (I))) =
               "configuration.invalid_option_combination",
               "direct collection validation keeps stable diagnostic identifiers");
         end loop;
      end;
      Greplib.Collected.Search_String ("hit", Set, Search_Options, Collection, Result);
      Assert (Diagnostic_Count (Result.Outcome) = 3, "collected search reports all invalid collection limits");
      Assert (Records_Read (Result.Outcome) = 0, "multi-invalid collection options consume no input");

      declare
         Bad_List : Greplib.Patterns.Pattern_List;
         Bad_Set : Greplib.Patterns.Compiled_Pattern_Set;
         Combined : Greplib.Diagnostics.Diagnostic_List;
      begin
         Greplib.Patterns.Append (Bad_List, Greplib.Patterns.Regular_Expression_Pattern ("["));
         Bad_Set := Greplib.Patterns.Compile (Bad_List);
         Search_Options := (others => <>);
         Collection := (others => <>);
         Collection.Maximum_Records := 0;
         Combined := Greplib.Collected.Validate (Bad_Set, Search_Options, Collection);
         Assert (Natural (Combined.Length) = 2, "collected validation aggregates collection and search errors");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Combined.Element (1))) =
            "configuration.invalid_option_combination",
            "collected validation reports collection limit first");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Combined.Element (2))) =
            "configuration.invalid_option_combination",
            "collected validation reports unusable pattern second");

         Greplib.Collected.Search_String ("hit", Bad_Set, Search_Options, Collection, Result);
         Assert (Status (Result.Outcome) = Greplib.Results.Failed, "collected composed validation fails early");
         Assert (Diagnostic_Count (Result.Outcome) = 2, "collected composed validation retains both diagnostics");
         Assert (Records_Read (Result.Outcome) = 0, "collected composed validation consumes no records");
      end;

      Collection := (others => <>);
      Collection.Maximum_Bytes := 1;
      Greplib.Collected.Search_String ("hit", Set, Search_Options, Collection, Result);
      Assert (Result.Truncated, "collection byte limit accounts for event overhead");
      Assert (Result.Truncation.Bytes, "collection byte limit records byte-limit reason");
      Assert (not Result.Truncation.Records, "byte-limit collection does not report record-limit reason");
      Assert (not Result.Truncation.Events, "byte-limit collection does not report event-limit reason");
      Assert (Natural (Result.Events.Length) = 0, "event overhead can exceed byte limit before first event");
      Assert
        (Reason (Result.Outcome) = Greplib.Results.Result_Limit_Reached,
         "event-overhead byte limit reports result limit");

      Collection := (others => <>);
      Collection.Maximum_Events := 0;
      Greplib.Collected.Search_String ("hit", Set, Search_Options, Collection, Result);
      Assert (Status (Result.Outcome) = Greplib.Results.Failed, "zero collection events fails validation");

      declare
         Binary_Options : Greplib.Options.Search_Options;
      begin
         Binary_Options.On_Binary := Greplib.Options.Report_Match_Without_Record;
         Collection := (others => <>);
         Collection.Maximum_Bytes := 1_000;
         Greplib.Collected.Search_String
           ("hit" & Character'Val (0), Set, Binary_Options, Collection, Result);
         Assert (not Result.Truncated, "binary match fits ordinary collection byte limit");

         Collection.Maximum_Bytes := 1;
         Greplib.Collected.Search_String
           ("hit" & Character'Val (0), Set, Binary_Options, Collection, Result);
         Assert (Result.Truncated, "binary match event overhead is byte-accounted");
         Assert (Result.Truncation.Bytes, "binary match byte limit records byte-limit reason");
      end;

      Collection := (others => <>);
      Collection.Maximum_Events := 1;
      Greplib.Collected.Search_String ("hit", Set, Search_Options, Collection, Result);
      Assert (Result.Truncated, "collection event limit reports truncation");
      Assert (Result.Truncation.Events, "collection event limit records event-limit reason");
      Assert (not Result.Truncation.Records, "event-limit collection does not report record-limit reason");
      Assert (not Result.Truncation.Bytes, "event-limit collection does not report byte-limit reason");

      declare
         Bytes : constant Ada.Streams.Stream_Element_Array (1 .. 3) :=
           (1 => Character'Pos ('h'), 2 => Character'Pos ('i'), 3 => Character'Pos ('t'));
      begin
         Collection := (others => <>);
         Greplib.Collected.Search_Bytes (Bytes, Set, Search_Options, Collection, Result);
         Assert (Status (Result.Outcome) = Greplib.Results.Completed, "collected byte search completes");
         Assert (Selected_Record_Count (Result.Outcome) = 1, "collected byte search finds match");
      end;

      declare
         Stream : Short_Read_Stream :=
           (Ada.Streams.Root_Stream_Type with
            Text => U.To_Unbounded_String ("hit" & ASCII.LF & "miss"), Next => 1, Chunk => 1,
            Reads => 0, Fail_Read => 0);
      begin
         Greplib.Collected.Search_Stream (Stream, Set, Search_Options, Collection, Result);
         Assert (Status (Result.Outcome) = Greplib.Results.Completed, "collected stream search completes");
         Assert (Selected_Record_Count (Result.Outcome) = 1, "collected stream search finds match");
         Assert (Stream.Reads > 1, "collected stream search uses borrowed stream reads");
      end;

      declare
         Root : constant String := "generated/collected_overloads";
         Roots : Greplib.Paths.Path_List;
         Directory_Options : Greplib.Directories.Directory_Search_Options;
      begin
         Local_Ensure_Directory ("generated");
         Local_Ensure_Directory (Root);
         PF.Write_Raw_File (Root & "/one.txt", "hit");
         PF.Write_Raw_File (Root & "/two.txt", "miss");

         Greplib.Collected.Search_File
           (Greplib.Paths.To_Path (Root & "/one.txt"), Set, Search_Options, Collection, Result);
         Assert (Status (Result.Outcome) = Greplib.Results.Completed, "collected file search completes");
         Assert (Selected_Record_Count (Result.Outcome) = 1, "collected file search finds match");

         Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
         Greplib.Collected.Search_Paths
           (Roots, Set, Search_Options, Directory_Options, Collection, Result);
         Assert (Status (Result.Outcome) = Greplib.Results.Completed, "collected directory search completes");
         Assert (Sources_Considered (Result.Outcome) >= 2, "collected directory search considers files");
         Assert (Selected_Record_Count (Result.Outcome) >= 1, "collected directory search finds match");

         declare
            Rules : Greplib.Path_Filters.Filter_List;
            Filters : Greplib.Path_Filters.Compiled_Filter_Set;
            Diagnostics : Greplib.Diagnostics.Diagnostic_List;
            Empty_Roots : Greplib.Paths.Path_List;
         begin
            Greplib.Path_Filters.Append
              (Rules,
               Greplib.Path_Filters.Rule
                 (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
                  Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Regular_Expression, "["));
            Filters := Greplib.Path_Filters.Compile (Rules);
            Collection := (others => <>);
            Collection.Maximum_Events := 0;
            Diagnostics :=
              Greplib.Collected.Validate_Paths
                (Empty_Roots, Set, Filters, Search_Options, Directory_Options, Collection);
            Assert
              (Natural (Diagnostics.Length) = 3,
               "collected filtered validation aggregates collection roots and filters");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics.Element (1))) =
               "configuration.invalid_option_combination",
               "collected filtered validation reports collection error first");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics.Element (2))) =
               "configuration.empty_root_list",
               "collected filtered validation reports empty roots second");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics.Element (3))) =
               "path_filter.invalid_pattern",
               "collected filtered validation reports filter diagnostic third");

            Greplib.Collected.Search_Paths
              (Empty_Roots, Set, Filters, Search_Options, Directory_Options, Collection, Result);
            Assert (Status (Result.Outcome) = Greplib.Results.Failed, "collected filtered validation fails early");
            Assert (Diagnostic_Count (Result.Outcome) = 3, "collected filtered validation retains diagnostics");
            Assert (Sources_Considered (Result.Outcome) = 0, "collected filtered validation consumes no sources");
         end;
      end;
   end Test_Collected_Limits;

   procedure Write_File (Name : String; Text : String) is
   begin
      PF.Write_Raw_File (Name, Text);
   end Write_File;

   procedure Ensure_Directory (Name : String) is
   begin
      if not PF.Directory_Exists (Name) then
         Ada.Directories.Create_Directory (Name);
      end if;
   end Ensure_Directory;

   procedure Test_File_Source_Path is
      type Path_Sink is new Greplib.Events.Event_Sink with record
         Saw_Selected : Boolean := False;
         Selected_Path : Greplib.Paths.Path;
         Selected_Sequence : Greplib.Source_Sequence := 1;
         Selected_Source : Greplib.Sources.Source_Descriptor;
      end record;
      type Mutating_Sink is new Greplib.Events.Event_Sink with record
         Target : U.Unbounded_String;
         Mutated : Boolean := False;
      end record;
      overriding procedure On_Event
        (Sink : in out Path_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Mutating_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);

      function C_Truncate
        (Path : Interfaces.C.Strings.chars_ptr;
         Length : Interfaces.C.long) return Interfaces.C.int;
      pragma Import (C, C_Truncate, "truncate");

      overriding procedure On_Event
        (Sink : in out Path_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Saw_Selected := True;
            Sink.Selected_Path := Greplib.Events.Source_Path (Event);
            Sink.Selected_Sequence := Greplib.Events.Source_No (Event);
            Sink.Selected_Source := Greplib.Events.Source (Event);
         end if;
      end On_Event;
      overriding procedure On_Event
        (Sink : in out Mutating_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record and then not Sink.Mutated then
            declare
               Path_C : Interfaces.C.Strings.chars_ptr :=
                 Interfaces.C.Strings.New_String (U.To_String (Sink.Target));
               Result : Interfaces.C.int;
            begin
               Result := C_Truncate (Path_C, 0);
               Interfaces.C.Strings.Free (Path_C);
               Sink.Mutated := Result = 0;
            end;
         end if;
      end On_Event;

      Name : constant String := "generated/source_path_fixture.txt";
      Mutating_Name : constant String := "generated/source_changed_fixture.txt";
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Opts : Greplib.Options.Search_Options;
      Sink : Path_Sink;
      Mutator : Mutating_Sink := (Target => U.To_Unbounded_String (Mutating_Name), Mutated => False);
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Ensure_Directory ("generated");
      Write_File (Name, "hit" & ASCII.LF & "miss");
      Write_File (Mutating_Name, "hit" & ASCII.LF);

      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);

      Greplib.Files.Search_File
        (Greplib.Paths.To_Path (Name), Set, Opts, Sink, Outcome);

      Assert (Status (Outcome) = Greplib.Results.Completed, "file search completed");
      Assert (Sink.Saw_Selected, "file selected event observed");
      Assert (Greplib.Paths.Image (Sink.Selected_Path) = Name, "file event keeps caller path spelling");
      Assert (Sink.Selected_Sequence = 1, "standalone file event sequence defaults to one");
      Assert (Greplib.Sources.Kind (Sink.Selected_Source) = Greplib.Sources.File_Source, "file source kind");
      Assert (Greplib.Sources.Sequence (Sink.Selected_Source) = Sink.Selected_Sequence, "file descriptor sequence");
      Assert
        (Greplib.Paths.Image (Greplib.Sources.Path (Sink.Selected_Source)) = Name,
         "file descriptor path keeps caller spelling");
      declare
         Summaries : constant Greplib.Results.Source_Summary_List := Greplib.Results.Source_Summaries (Outcome);
         Summary : constant Greplib.Results.Source_Summary := Greplib.Results.Element (Summaries, 1);
      begin
         Assert (Greplib.Results.Length (Summaries) = 1, "file retains one source summary");
         Assert (Greplib.Results.Records_Read (Summary) = 2, "file source summary records read");
         Assert (Greplib.Results.Selected_Record_Count (Summary) = 1, "file source summary selected count");
         Assert
           (Greplib.Sources.Kind (Greplib.Results.Source (Summary)) = Greplib.Sources.File_Source,
            "file source summary kind");
         Assert
           (Greplib.Paths.Image (Greplib.Sources.Path (Greplib.Results.Source (Summary))) = Name,
            "file source summary path");
      end;

      Greplib.Files.Search_File
        (Greplib.Paths.To_Path (Mutating_Name), Set, Opts, Mutator, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "file mutation search completed");
      Assert (Mutator.Mutated, "file mutation callback ran");
      Assert
        (Sources_Changed_During_Search (Outcome) = 1,
         "file mutation metadata is reflected in summary");
      declare
         Summaries : constant Greplib.Results.Source_Summary_List := Greplib.Results.Source_Summaries (Outcome);
         Summary : constant Greplib.Results.Source_Summary := Greplib.Results.Element (Summaries, 1);
      begin
         Assert
           (Greplib.Results.Source_Changed_During_Search (Summary),
            "file mutation metadata is reflected in source summary");
      end;
   end Test_File_Source_Path;

   procedure Test_File_Open_Failure is
      type Diagnostic_Sink is new Greplib.Events.Event_Sink with record
         Started : Natural := 0;
         Diagnostics : Natural := 0;
         Completed : Natural := 0;
      end record;
      overriding procedure On_Event
        (Sink : in out Diagnostic_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Diagnostic_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Source_Started then
            Sink.Started := Sink.Started + 1;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Diagnostic_Event then
            Sink.Diagnostics := Sink.Diagnostics + 1;
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Greplib.Events.Diagnostic (Event))) =
               "filesystem.open_failed",
               "missing file emits filesystem.open_failed");
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Source_Completed then
            Sink.Completed := Sink.Completed + 1;
         end if;
      end On_Event;

      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Opts : Greplib.Options.Search_Options;
      Sink : Diagnostic_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);

      declare
         File_Diagnostics : Greplib.Diagnostics.Diagnostic_List := Greplib.Files.Validate (Set, Opts);
      begin
         Assert (File_Diagnostics.Is_Empty, "valid file options produce no direct validation diagnostics");
      end;

      Greplib.Files.Search_File
        (Greplib.Paths.To_Path ("generated/does-not-exist.txt"), Set, Opts, Sink, Outcome);

      Assert (Status (Outcome) = Greplib.Results.Failed, "missing file fails structurally");
      Assert (Sources_Considered (Outcome) = 1, "missing file source is considered");
      Assert (Sources_Opened (Outcome) = 0, "missing file is not opened");
      Assert (Diagnostic_Count (Outcome) = 1, "missing file diagnostic counted");
      Assert (Natural (Diagnostics (Outcome).Length) = 1, "missing file diagnostic retained");
      Assert (Sink.Started = 1, "missing file source-started event emitted");
      Assert (Sink.Diagnostics = 1, "missing file diagnostic event emitted");
      Assert (Sink.Completed = 1, "missing file source-completed event emitted");

      Opts.Maximum_Retained_Diagnostics := 0;
      Sink := (Started => 0, Diagnostics => 0, Completed => 0);
      Greplib.Files.Search_File
        (Greplib.Paths.To_Path ("generated/does-not-exist.txt"), Set, Opts, Sink, Outcome);
      Assert (Diagnostic_Count (Outcome) = 1, "missing file zero-retention diagnostic counted");
      Assert (Natural (Diagnostics (Outcome).Length) = 0, "missing file zero-retention keeps no diagnostic");
      Assert (Diagnostics_Truncated (Outcome), "missing file zero-retention marks truncation");
      Assert (Sink.Diagnostics = 1, "missing file zero-retention still emits diagnostic event");

      declare
         Source : aliased Greplib.Cancellation.Cancellation_Source;
      begin
         Source.Request;
         Opts := (others => <>);
         Sink := (Started => 0, Diagnostics => 0, Completed => 0);
         Greplib.Files.Search_File
           (Greplib.Paths.To_Path ("generated/does-not-exist.txt"),
            Set, Opts, Sink, Outcome, Greplib.Cancellation.Token (Source));
         Assert (Status (Outcome) = Greplib.Results.Cancelled, "pre-cancelled file search is cancelled");
         Assert (Sources_Opened (Outcome) = 0, "pre-cancelled file search opens no file");
         Assert (Cancellation_Observed (Outcome), "pre-cancelled file search observes cancellation");
         Assert (Sink.Started = 0, "pre-cancelled file search emits no source-started event");
         Assert (Sink.Diagnostics = 0, "pre-cancelled file search emits no diagnostic event");
      end;

      Opts := (others => <>);
      Opts.Read_Block_Size := 0;
      declare
         File_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List := Greplib.Files.Validate (Set, Opts);
      begin
         Assert (Natural (File_Diagnostics.Length) = 1, "direct file validation counts invalid read block size");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (File_Diagnostics.Element (1))) =
            "configuration.invalid_option_combination",
            "direct file validation reports invalid option combination");
      end;

      Sink := (Started => 0, Diagnostics => 0, Completed => 0);
      Greplib.Files.Search_File
        (Greplib.Paths.To_Path ("generated/does-not-exist.txt"), Set, Opts, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Failed, "invalid file options fail before open");
      Assert (Sources_Considered (Outcome) = 1, "invalid file options still consider source");
      Assert (Sources_Opened (Outcome) = 0, "invalid file options do not open missing file");
      Assert (Diagnostic_Count (Outcome) = 1, "invalid file options count diagnostic");
      Assert (Sink.Started = 0, "invalid file options emit no source-started event");
      Assert (Sink.Diagnostics = 0, "invalid file options emit no diagnostic callback");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
         "configuration.invalid_option_combination",
         "invalid file options diagnostic identifier");

      Opts := (others => <>);
      Opts.Read_Block_Size := 0;
      Opts.Maximum_Retained_Diagnostics := 0;
      Sink := (Started => 0, Diagnostics => 0, Completed => 0);
      Greplib.Files.Search_File
        (Greplib.Paths.To_Path ("generated/does-not-exist.txt"), Set, Opts, Sink, Outcome);
      Assert (Diagnostic_Count (Outcome) = 1, "invalid file options zero-retention counts diagnostic");
      Assert (Natural (Diagnostics (Outcome).Length) = 0, "invalid file options zero-retention retains no diagnostic");
      Assert (Diagnostics_Truncated (Outcome), "invalid file options zero-retention marks truncation");
      Assert (Sink.Started = 0, "invalid file options zero-retention emits no source events");

      declare
         Bad_List : Greplib.Patterns.Pattern_List;
         Bad_Set : Greplib.Patterns.Compiled_Pattern_Set;
      begin
         Greplib.Patterns.Append (Bad_List, Greplib.Patterns.Regular_Expression_Pattern ("["));
         Bad_Set := Greplib.Patterns.Compile (Bad_List);
         Opts := (others => <>);
         declare
            File_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
              Greplib.Files.Validate (Bad_Set, Opts);
         begin
            Assert (Natural (File_Diagnostics.Length) = 1, "direct file validation counts unusable pattern set");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (File_Diagnostics.Element (1))) =
               "configuration.invalid_option_combination",
               "direct file validation reports unusable pattern set");
         end;

         Opts.Read_Block_Size := 0;
         declare
            File_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
              Greplib.Files.Validate (Bad_Set, Opts);
         begin
            Assert (Natural (File_Diagnostics.Length) = 2, "direct file validation aggregates independent errors");
            for I in 1 .. 2 loop
               Assert
                 (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (File_Diagnostics.Element (I))) =
                  "configuration.invalid_option_combination",
                  "direct file validation preserves structural diagnostic identifiers");
            end loop;
         end;

         Opts := (others => <>);
         Sink := (Started => 0, Diagnostics => 0, Completed => 0);
         Greplib.Files.Search_File
           (Greplib.Paths.To_Path ("generated/does-not-exist.txt"), Bad_Set, Opts, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Failed, "unusable file pattern set fails before open");
         Assert (Sources_Opened (Outcome) = 0, "unusable file pattern set does not open missing file");
         Assert (Sink.Started = 0, "unusable file pattern set emits no source-started event");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
            "configuration.invalid_option_combination",
            "unusable file pattern set diagnostic identifier");
      end;
   end Test_File_Open_Failure;

   procedure Test_File_Callback_Exception_Propagates is
      Callback_Failure : exception;
      type Raising_Sink is new Greplib.Events.Event_Sink with null record;
      overriding procedure On_Event
        (Sink : in out Raising_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Raising_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            raise Callback_Failure;
         end if;
      end On_Event;

      Name : constant String := "generated/callback_exception_fixture.txt";
      List : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Opts : Greplib.Options.Search_Options;
      Sink : Raising_Sink;
      Outcome : Greplib.Results.Search_Outcome;
      Propagated : Boolean := False;
   begin
      Ensure_Directory ("generated");
      Write_File (Name, "hit");
      Greplib.Patterns.Append (List, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (List);

      begin
         Greplib.Files.Search_File
           (Greplib.Paths.To_Path (Name), Set, Opts, Sink, Outcome);
      exception
         when Callback_Failure =>
            Propagated := True;
      end;

      Assert (Propagated, "file search propagates callback exceptions unchanged");
   end Test_File_Callback_Exception_Propagates;

   procedure Test_Directory_Path_Filters is
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

      Root : constant String := "generated/path_filter_fixture";
      Sub : constant String := Root & "/sub";
      Pruned : constant String := Root & "/pruned";
      Roots : Greplib.Paths.Path_List;
      Rules : Greplib.Path_Filters.Filter_List;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Sink : Null_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);
      Ensure_Directory (Sub);
      Ensure_Directory (Pruned);

      Write_File (Root & "/keep.txt", "hit");
      Write_File (Root & "/drop.tmp", "hit");
      Write_File (Sub & "/revive.tmp", "hit");
      Write_File (Pruned & "/hidden.txt", "hit");

      Greplib.Path_Filters.Append
        (Rules,
         Greplib.Path_Filters.Rule
           (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
            Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Glob_Pattern, "*.tmp"));
      Greplib.Path_Filters.Append
        (Rules,
         Greplib.Path_Filters.Rule
           (Greplib.Path_Filters.Include, Greplib.Path_Filters.Files_Only,
            Greplib.Path_Filters.Relative_Path, Greplib.Path_Filters.Exact_Name, "sub/revive.tmp"));
      Greplib.Path_Filters.Append
        (Rules,
         Greplib.Path_Filters.Rule
           (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Directories_Only,
            Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Exact_Name, "pruned"));
      Filters := Greplib.Path_Filters.Compile (Rules);

      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
      Directory_Options.Recursive := True;
      Search_Options.Mode := Greplib.Options.Count_Selected_Records;

      Greplib.Directories.Search_Paths
        (Roots, Set, Filters, Search_Options, Directory_Options, Sink, Outcome);

      Assert (Status (Outcome) = Greplib.Results.Completed, "filtered directory search completed");
      Assert (Sources_Considered (Outcome) = 2, "filters accepted two files");
      Assert (Selected_Record_Count (Outcome) = 2, "accepted files were searched");
      Assert (Roots_Considered (Outcome) = 1, "directory summary counts roots");
      Assert (Directories_Visited (Outcome) = 2, "directory summary counts visited directories");
      Assert (Directories_Skipped (Outcome) = 1, "directory summary counts pruned directories");
      Assert (Entries_Examined (Outcome) >= 5, "directory summary counts examined entries");
      Assert (Files_Accepted (Outcome) = 2, "directory summary counts accepted files");
      Assert (Files_Filtered (Outcome) = 1, "directory summary counts filtered files");
   end Test_Directory_Path_Filters;

   procedure Test_Directory_File_Type_Policies is
      type Null_Sink is new Greplib.Events.Event_Sink with record
         Events : Natural := 0;
      end record;
      overriding procedure On_Event
        (Sink : in out Null_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Null_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
         pragma Unreferenced (Event);
      begin
         Sink.Events := Sink.Events + 1;
         Action := Greplib.Events.Continue_Search;
      end On_Event;

      Root : constant String := "generated/directory_file_type_policy";
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Sink : Null_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);
      Write_File (Root & "/one.txt", "hit");

      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
      Search_Options.Mode := Greplib.Options.Count_Selected_Records;

      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "default file-type policy completes");
      Assert (Files_Accepted (Outcome) >= 1, "default file-type policy accepts ordinary files");
      Assert (Sources_Considered (Outcome) >= 1, "default file-type policy searches ordinary files");
      Assert (Selected_Record_Count (Outcome) >= 1, "default file-type policy finds ordinary file match");

      Directory_Options.Search_Regular_Files := False;
      Sink := (Events => 0);
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "disabled regular-file policy completes");
      Assert (Files_Accepted (Outcome) = 0, "disabled regular-file policy accepts no ordinary files");
      Assert (Files_Filtered (Outcome) >= 1, "disabled regular-file policy filters ordinary files");
      Assert (Sources_Considered (Outcome) = 0, "disabled regular-file policy opens no sources");
      Assert (Selected_Record_Count (Outcome) = 0, "disabled regular-file policy finds no matches");
   end Test_Directory_File_Type_Policies;

   procedure Test_Path_Filter_Compilation is
      Rules : Greplib.Path_Filters.Filter_List;
      Set : Greplib.Path_Filters.Compiled_Filter_Set;
   begin
      declare
         Empty_Diagnostics : Greplib.Diagnostics.Diagnostic_List := Greplib.Path_Filters.Validate (Rules);
      begin
         Assert (Empty_Diagnostics.Is_Empty, "empty path filter list validates directly");
      end;

      Greplib.Path_Filters.Append
        (Rules,
         Greplib.Path_Filters.Rule
           (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
            Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Exact_Name, "before.tmp"));
      declare
         Exact_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
           Greplib.Path_Filters.Validate (Rules);
      begin
         Assert (Exact_Diagnostics.Is_Empty, "exact path filter validates directly");
      end;

      Greplib.Path_Filters.Append
        (Rules,
         Greplib.Path_Filters.Rule
           (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
            Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Glob_Pattern, "bad\"));
      declare
         Glob_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
           Greplib.Path_Filters.Validate (Rules);
      begin
         Assert (Natural (Glob_Diagnostics.Length) = 1, "direct path filter validation counts malformed glob");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Glob_Diagnostics.Element (1))) =
            "path_filter.invalid_pattern",
            "direct path filter validation reports malformed glob");
      end;

      Set := Greplib.Path_Filters.Compile (Rules);
      Assert (not Greplib.Path_Filters.Is_Usable (Set), "malformed glob filter is unusable");
      Assert (Natural (Greplib.Path_Filters.Diagnostics (Set).Length) = 1, "malformed glob diagnostic retained");
      Assert
        (Greplib.Path_Filters.Included (Set, "before.tmp", "before.tmp", False),
         "failed glob filter compile exposes no partial rules");
      Assert
        (Greplib.Diagnostics.Identifier
           (Greplib.Diagnostics.Code (Greplib.Path_Filters.Diagnostics (Set).Element (1))) =
         "path_filter.invalid_pattern",
         "malformed glob diagnostic identifier");

      declare
         Regex_Rules : Greplib.Path_Filters.Filter_List;
         Regex_Set : Greplib.Path_Filters.Compiled_Filter_Set;
      begin
         Greplib.Path_Filters.Append
           (Regex_Rules,
            Greplib.Path_Filters.Rule
              (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
               Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Regular_Expression, "["));
         declare
            Regex_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
              Greplib.Path_Filters.Validate (Regex_Rules);
         begin
            Assert (Natural (Regex_Diagnostics.Length) = 1, "direct path filter validation counts malformed regex");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Regex_Diagnostics.Element (1))) =
               "path_filter.invalid_pattern",
               "direct path filter validation reports malformed regex");
         end;

         Regex_Set := Greplib.Path_Filters.Compile (Regex_Rules);
         Assert (not Greplib.Path_Filters.Is_Usable (Regex_Set), "malformed regex filter is unusable");
         Assert
           (Greplib.Diagnostics.Identifier
              (Greplib.Diagnostics.Code (Greplib.Path_Filters.Diagnostics (Regex_Set).Element (1))) =
            "path_filter.invalid_pattern",
            "malformed regex filter diagnostic identifier");
      end;
   end Test_Path_Filter_Compilation;

   procedure Test_Directory_Hidden_And_Cancellation is
      type Null_Sink is new Greplib.Events.Event_Sink with null record;
      overriding procedure On_Event
        (Sink : in out Null_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      type Cancelling_Sink is new Greplib.Events.Event_Sink with record
         Source : access Greplib.Cancellation.Cancellation_Source;
         Completed : Natural := 0;
      end record;
      overriding procedure On_Event
        (Sink : in out Cancelling_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Null_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
      end On_Event;
      overriding procedure On_Event
        (Sink : in out Cancelling_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Source_Completed then
            Sink.Completed := Sink.Completed + 1;
            if Sink.Source /= null then
               Sink.Source.Request;
            end if;
         end if;
      end On_Event;

      Root : constant String := "generated/directory_hidden";
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Sink : Null_Sink;
      Outcome : Greplib.Results.Search_Outcome;
      Source : aliased Greplib.Cancellation.Cancellation_Source;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);
      Write_File (Root & "/visible.txt", "hit");
      Write_File (Root & "/.hidden.txt", "hit");
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
      Search_Options.Mode := Greplib.Options.Count_Selected_Records;

      Directory_Options.Include_Hidden := False;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Sources_Considered (Outcome) = 1, "hidden file excluded when disabled");
      Assert (Selected_Record_Count (Outcome) = 1, "visible file still searched");

      Source.Request;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome, Greplib.Cancellation.Token (Source));
      Assert (Status (Outcome) = Greplib.Results.Cancelled, "pre-requested directory cancellation cancels");
      Assert (Cancellation_Observed (Outcome), "directory cancellation is observed");
      Assert
        (Reason (Outcome) = Greplib.Results.Cancellation_Requested,
         "directory cancellation reason");
      Assert (Sources_Considered (Outcome) = 0, "cancelled directory consumes no sources");

      declare
         Callback_Source : aliased Greplib.Cancellation.Cancellation_Source;
         Callback_Sink : Cancelling_Sink := (Source => Callback_Source'Unchecked_Access, Completed => 0);
      begin
         Directory_Options.Include_Hidden := True;
         Greplib.Directories.Search_Paths
           (Roots, Set, Search_Options, Directory_Options, Callback_Sink, Outcome,
            Greplib.Cancellation.Token (Callback_Source));
         Assert (Status (Outcome) = Greplib.Results.Cancelled, "directory observes callback-requested cancellation");
         Assert
           (Reason (Outcome) = Greplib.Results.Cancellation_Requested,
            "directory callback cancellation reason");
         Assert (Sources_Considered (Outcome) = 1, "directory callback cancellation stops after first source");
         Assert (Callback_Sink.Completed = 1, "directory callback cancellation delivered one completed source");
      end;
   end Test_Directory_Hidden_And_Cancellation;

   procedure Test_Directory_Error_Aggregation is
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
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Empty_Roots : Greplib.Paths.Path_List;
      Roots : Greplib.Paths.Path_List;
      Sink : Null_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);

      Greplib.Directories.Search_Paths
        (Empty_Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Failed, "empty root list fails validation");
      Assert (Reason (Outcome) = Greplib.Results.Fatal_Error, "empty root list reports fatal reason");
      Assert (Diagnostic_Count (Outcome) = 1, "empty root diagnostic counted");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
         "configuration.empty_root_list",
         "empty root list uses stable diagnostic identifier");

      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("generated/missing-directory-root"));
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert
        (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "missing directory root is recoverable");
      Assert (Diagnostic_Count (Outcome) = 1, "missing root diagnostic counted");
      Assert (Natural (Diagnostics (Outcome).Length) = 1, "missing root diagnostic retained");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
         "filesystem.open_failed",
         "missing root reports filesystem.open_failed");

      Greplib.Paths.Clear (Roots);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("generated/missing-directory-root"));
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("generated"));
      Directory_Options.Traversal_Errors := Greplib.Directories.Fail_Search;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Failed, "fail-search missing root fails operation");
      Assert (Reason (Outcome) = Greplib.Results.Source_Error, "fail-search missing root reports source error");
      Assert (Sources_Considered (Outcome) = 0, "fail-search missing root stops before later root");
      Assert
        (Greplib.Diagnostics.Level (Diagnostics (Outcome).Element (1)) = Greplib.Diagnostics.Fatal_Error,
         "fail-search missing root emits fatal diagnostic");

      Greplib.Paths.Clear (Roots);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("generated/missing-directory-root"));
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("generated"));
      Directory_Options := (others => <>);
      Directory_Options.Traversal_Errors := Greplib.Directories.Fail_Root;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert
        (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "fail-root missing root remains recoverable");
      Assert (Diagnostic_Count (Outcome) = 1, "fail-root missing root diagnostic counted");
      Assert
        (Greplib.Diagnostics.Level (Diagnostics (Outcome).Element (1)) = Greplib.Diagnostics.Recoverable_Error,
         "fail-root missing root emits recoverable diagnostic");
      Assert (Sources_Considered (Outcome) > 0, "fail-root continues with later root");

      Greplib.Paths.Clear (Roots);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("generated/missing-directory-root"));
      Directory_Options := (others => <>);
      Directory_Options.Worker_Count := 0;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Failed, "invalid directory worker count fails validation");
      Assert (Diagnostic_Count (Outcome) = 1, "invalid directory worker count diagnostic counted");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
         "configuration.invalid_option_combination",
         "invalid directory worker count reports invalid option combination");
      Assert (Sources_Considered (Outcome) = 0, "invalid directory options consume no roots");

      Greplib.Paths.Clear (Roots);
      declare
         Directory_Diagnostics : Greplib.Diagnostics.Diagnostic_List;
      begin
         Directory_Options := (others => <>);
         Directory_Options.Worker_Count := Greplib.Default_Maximum_Worker_Count;
         Directory_Options.Maximum_In_Flight_Sources := Greplib.Default_Maximum_Worker_Count;
         Directory_Options.Maximum_Queued_Sources := Greplib.Default_Maximum_Worker_Count;
         Directory_Diagnostics := Greplib.Directories.Validate (Roots, Set, Search_Options, Directory_Options);
         Assert
           (Natural (Directory_Diagnostics.Length) = 1,
            "maximum worker count reports only empty-root diagnostic");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Directory_Diagnostics.Element (1))) =
            "configuration.empty_root_list",
            "maximum worker count does not add invalid-option diagnostic");

         Directory_Options := (others => <>);
         Directory_Options.Worker_Count := Greplib.Default_Maximum_Worker_Count + 1;
         Directory_Options.Maximum_In_Flight_Sources := Directory_Options.Worker_Count;
         Directory_Options.Maximum_Queued_Sources := Directory_Options.Worker_Count;
         Directory_Diagnostics := Greplib.Directories.Validate (Roots, Set, Search_Options, Directory_Options);
         Assert
           (Natural (Directory_Diagnostics.Length) = 2,
            "above maximum worker count diagnostic counted independently");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Directory_Diagnostics.Element (2))) =
            "configuration.invalid_option_combination",
            "above maximum worker count reports invalid option combination");
      end;

      declare
         Directory_Diagnostics : Greplib.Diagnostics.Diagnostic_List;
      begin
         Directory_Options := (others => <>);
         Directory_Options.Maximum_Path_Bytes := 0;
         Directory_Options.Maximum_Directory_Entries := 0;
         Directory_Options.Maximum_Queued_Sources := 0;
         Directory_Options.Maximum_In_Flight_Sources := 0;
         Directory_Options.Maximum_Queued_Events_Per_Source := 0;
         Directory_Options.Maximum_Queued_Event_Bytes_Per_Source := 0;
         Directory_Diagnostics := Greplib.Directories.Validate (Roots, Set, Search_Options, Directory_Options);
         Assert
           (Natural (Directory_Diagnostics.Length) = 9,
            "directory validation reports independent configuration errors");
         Assert
           (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Directory_Diagnostics.Element (1))) =
            "configuration.empty_root_list",
            "directory validation keeps empty-root diagnostic first");
         for I in 2 .. 9 loop
            Assert
              (Greplib.Diagnostics.Identifier
                 (Greplib.Diagnostics.Code (Directory_Diagnostics.Element (I))) =
               "configuration.invalid_option_combination",
               "directory validation reports invalid option combination");
         end loop;
      end;

      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("generated/missing-directory-root"));
      Directory_Options := (others => <>);
      Directory_Options.Maximum_Directory_Entries := 0;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Failed, "zero directory entry limit fails validation");
      Assert (Diagnostic_Count (Outcome) = 1, "zero directory entry limit diagnostic counted");
      Assert (Sources_Considered (Outcome) = 0, "zero directory entry limit consumes no roots");

      Directory_Options := (others => <>);
      Directory_Options.Worker_Count := 2;
      Directory_Options.Maximum_In_Flight_Sources := 1;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Failed, "worker/in-flight mismatch fails validation");
      Assert (Diagnostic_Count (Outcome) = 1, "worker/in-flight mismatch diagnostic counted");
      Assert (Sources_Considered (Outcome) = 0, "worker/in-flight mismatch consumes no roots");

      Directory_Options := (others => <>);
      Directory_Options.Worker_Count := 2;
      Directory_Options.Maximum_Queued_Sources := 1;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Failed, "worker/queue mismatch fails validation");
      Assert (Diagnostic_Count (Outcome) = 1, "worker/queue mismatch diagnostic counted");
      Assert (Sources_Considered (Outcome) = 0, "worker/queue mismatch consumes no roots");

      Directory_Options := (others => <>);
      Directory_Options.Maximum_Queued_Events_Per_Source := 0;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Failed, "zero queued event limit fails validation");
      Assert (Diagnostic_Count (Outcome) = 1, "zero queued event limit diagnostic counted");
      Assert (Sources_Considered (Outcome) = 0, "zero queued event limit consumes no roots");

      Directory_Options := (others => <>);
      Directory_Options.Maximum_Queued_Event_Bytes_Per_Source := 0;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Failed, "zero queued event byte limit fails validation");
      Assert (Diagnostic_Count (Outcome) = 1, "zero queued event byte limit diagnostic counted");
      Assert (Sources_Considered (Outcome) = 0, "zero queued event byte limit consumes no roots");

      Directory_Options := (others => <>);
      Directory_Options.Stay_On_Starting_Filesystem := True;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert
        (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "filesystem boundary option reports unavailable root identity structurally");
      Assert (Diagnostic_Count (Outcome) = 1, "filesystem boundary diagnostic counted");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
         "filesystem.open_failed",
         "filesystem boundary diagnostic identifier");
      Assert (Sources_Considered (Outcome) = 0, "filesystem boundary unavailable root opens no sources");

   end Test_Directory_Error_Aggregation;

   procedure Test_Directory_Symlink_Policies is
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

      function C_Symlink
        (Target : Interfaces.C.Strings.chars_ptr;
         Link_Name : Interfaces.C.Strings.chars_ptr) return Interfaces.C.int;
      pragma Import (C, C_Symlink, "symlink");

      function Make_Link (Target : String; Link_Name : String) return Boolean is
         Target_C : Interfaces.C.Strings.chars_ptr := Interfaces.C.Strings.New_String (Target);
         Link_C : Interfaces.C.Strings.chars_ptr := Interfaces.C.Strings.New_String (Link_Name);
         Result : Interfaces.C.int;
      begin
         Result := C_Symlink (Target_C, Link_C);
         Interfaces.C.Strings.Free (Target_C);
         Interfaces.C.Strings.Free (Link_C);
         return Result = 0;
      end Make_Link;

      Root : constant String := "generated/directory_symlink_policy";
      Target : constant String := Root & "/target";
      Link_Name : constant String := Root & "/linked";
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Sink : Null_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);
      Ensure_Directory (Target);
      Write_File (Target & "/hit.txt", "hit");

      if not Ada.Directories.Exists (Link_Name) and then not Make_Link ("target", Link_Name) then
         return;
      end if;

      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Search_Options.Mode := Greplib.Options.Count_Selected_Records;
      Directory_Options.Recursive := True;

      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "default symlink policy completes");
      Assert (Sources_Considered (Outcome) = 1, "default policy skips traversal symlink");
      Assert (Links_Encountered (Outcome) = 1, "default policy counts encountered symlink");
      Assert (Links_Followed (Outcome) = 0, "default policy does not follow traversal symlink");

      Directory_Options.Symbolic_Links := Greplib.Directories.Follow_All;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "follow-all symlink policy completes");
      Assert (Sources_Considered (Outcome) = 2, "follow-all searches linked directory path");
      Assert (Selected_Record_Count (Outcome) = 2, "follow-all counts linked directory matches");
      Assert (Links_Followed (Outcome) = 1, "follow-all counts followed symlink");

      Greplib.Paths.Clear (Roots);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Link_Name));
      Directory_Options.Symbolic_Links := Greplib.Directories.Never_Follow;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "never-follow explicit symlink root completes");
      Assert (Sources_Considered (Outcome) = 0, "never-follow skips explicit symlink root");
      Assert (Links_Encountered (Outcome) = 1, "never-follow counts explicit symlink root");
   end Test_Directory_Symlink_Policies;

   procedure Test_Directory_Match_Count_Completeness is
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

      Root : constant String := "generated/directory_count_completeness";
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Sink : Null_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);
      Write_File (Root & "/many.txt", "a a a");
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("a"));
      Set := Greplib.Patterns.Compile (Patterns);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
      Search_Options.Mode := Greplib.Options.Count_Matches;
      Search_Options.Maximum_Match_Spans_Per_Record := 2;

      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);

      Assert
        (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "directory preserves recoverable source status");
      Assert (Match_Count (Outcome) = 2, "directory aggregates lower-bound match count");
      Assert
        (Match_Count_State (Outcome) = Greplib.Results.Lower_Bound,
         "directory preserves lower-bound match count state");
      Assert (Diagnostic_Count (Outcome) = 1, "directory aggregates span-limit diagnostic count");
   end Test_Directory_Match_Count_Completeness;

   procedure Test_Directory_Resource_Limits is
      type Null_Sink is new Greplib.Events.Event_Sink with null record;
      type Order_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         First : Greplib.Paths.Path;
         Second : Greplib.Paths.Path;
         Third : Greplib.Paths.Path;
         First_Sequence : Greplib.Source_Sequence := 1;
         Second_Sequence : Greplib.Source_Sequence := 1;
         Third_Sequence : Greplib.Source_Sequence := 1;
      end record;
      overriding procedure On_Event
        (Sink : in out Null_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Order_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Null_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
      end On_Event;
      overriding procedure On_Event
        (Sink : in out Order_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
            if Sink.Selected = 1 then
               Sink.First := Greplib.Events.Source_Path (Event);
               Sink.First_Sequence := Greplib.Events.Source_No (Event);
            elsif Sink.Selected = 2 then
               Sink.Second := Greplib.Events.Source_Path (Event);
               Sink.Second_Sequence := Greplib.Events.Source_No (Event);
            elsif Sink.Selected = 3 then
               Sink.Third := Greplib.Events.Source_Path (Event);
               Sink.Third_Sequence := Greplib.Events.Source_No (Event);
            end if;
         end if;
      end On_Event;

      Root : constant String := "generated/directory_resource_limits";
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Sink : Null_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);
      Ensure_Directory (Root & "/deep");
      Write_File (Root & "/a.txt", "hit");
      Write_File (Root & "/b.txt", "hit");
      Write_File (Root & "/deep/c.txt", "hit");
      Write_File (Root & "/deep/d.txt", "hit");

      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Search_Options.Mode := Greplib.Options.Count_Selected_Records;

      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
      Directory_Options.Maximum_Path_Bytes := 1;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert
        (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "path limit is recoverable");
      Assert (Sources_Considered (Outcome) = 0, "path limit skips root before file search");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
         "resource.path_limit_exceeded",
         "path limit diagnostic identifier");

      Directory_Options := (others => <>);
      Directory_Options.Maximum_Directory_Entries := 1;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert
        (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "directory entry limit is recoverable");
      Assert (Sources_Considered (Outcome) = 0, "entry limit skips oversized directory");
      Assert (Diagnostic_Count (Outcome) = 1, "entry limit diagnostic counted");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
         "resource.directory_entry_limit_exceeded",
         "entry limit diagnostic identifier");

      Directory_Options := (others => <>);
      Directory_Options.Recursive := True;
      Directory_Options.Maximum_Depth := 1;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert
        (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "depth limit is recoverable");
      Assert (Diagnostic_Count (Outcome) = 1, "depth limit diagnostic counted");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
         "traversal.maximum_depth_exceeded",
         "depth limit diagnostic identifier");

      Directory_Options := (others => <>);
      Directory_Options.Maximum_Depth := 0;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "maximum depth zero still considers root directory");
      Assert (Sources_Considered (Outcome) = 2, "maximum depth zero searches direct file children");
      Assert (Selected_Record_Count (Outcome) = 2, "maximum depth zero searches root children");

      Directory_Options := (others => <>);
      Directory_Options.Recursive := True;
      Directory_Options.Stay_On_Starting_Filesystem := True;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "same-filesystem traversal completes");
      Assert (Sources_Considered (Outcome) = 4, "same-filesystem traversal searches all fixture files");
      Assert (Selected_Record_Count (Outcome) = 4, "same-filesystem traversal retains matches");
      Assert
        (Filesystem_Boundaries_Skipped (Outcome) = 0,
         "same-filesystem traversal reports no boundary skips");

      Directory_Options := (others => <>);
         Directory_Options.Recursive := True;
         Directory_Options.Maximum_Sources := 1;
         Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "source limit completes structurally");
      Assert
        (Reason (Outcome) = Greplib.Results.Source_Limit_Reached,
         "source limit reports source-limit reason");
      Assert (Files_Accepted (Outcome) = 1, "source limit accepts exactly one file");
      Assert (Sources_Considered (Outcome) = 1, "source limit searches exactly one source");
         Assert (Selected_Record_Count (Outcome) = 1, "source limit counts searched source");

      Greplib.Paths.Clear (Roots);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root & "/a.txt"));
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root & "/a.txt"));
      Directory_Options := (others => <>);
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "duplicate file roots complete");
      Assert (Sources_Considered (Outcome) = 2, "duplicate file roots are searched independently");
      Assert (Selected_Record_Count (Outcome) = 2, "duplicate file roots retain duplicate results");

      declare
         Ordered : Order_Sink;
      begin
         Greplib.Paths.Clear (Roots);
         Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
         Search_Options := (others => <>);
         Directory_Options := (others => <>);
         Greplib.Directories.Search_Paths
           (Roots, Set, Search_Options, Directory_Options, Ordered, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Completed, "deterministic directory event order completes");
         Assert (Ordered.Selected >= 2, "deterministic directory event order emits selected records");
         Assert
           (Greplib.Paths.Image (Ordered.First) < Greplib.Paths.Image (Ordered.Second),
            "deterministic directory event order is lexicographic");
         Assert (Ordered.First_Sequence = 1, "first deterministic directory event has sequence one");
         Assert (Ordered.Second_Sequence = 2, "second deterministic directory event has sequence two");
      end;

      declare
         Ordered : Order_Sink;
      begin
         Greplib.Paths.Clear (Roots);
         Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
         Search_Options := (others => <>);
         Directory_Options := (others => <>);
         Directory_Options.Recursive := True;
         Directory_Options.Worker_Count := 2;
         Directory_Options.Maximum_Queued_Sources := 2;
         Greplib.Directories.Search_Paths
           (Roots, Set, Search_Options, Directory_Options, Ordered, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Completed, "live concurrent directory search completes");
         Assert (Ordered.Selected >= 4, "live concurrent directory search emits all selected records");
         Assert (Ordered.First_Sequence = 1, "live concurrent first source sequence");
         Assert (Ordered.Second_Sequence = 2, "live concurrent second source sequence");
         Assert (Ordered.Third_Sequence = 3, "live concurrent sequence continues past queue capacity");
         Assert (Sources_Considered (Outcome) = 4, "bounded source queue drains more files than capacity");
      end;
   end Test_Directory_Resource_Limits;

   procedure Test_Directory_Retention_And_Validation is
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
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Sink : Null_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);

      Search_Options.Maximum_Retained_Diagnostics := 1;
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("generated/missing-retention-a"));
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("generated/missing-retention-b"));
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("generated/missing-retention-c"));
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert
        (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "multiple missing roots remain recoverable");
      Assert (Diagnostic_Count (Outcome) = 3, "directory counts diagnostics beyond retention");
      Assert (Natural (Diagnostics (Outcome).Length) = 1, "directory retains only configured diagnostics");
      Assert (Diagnostics_Truncated (Outcome), "directory marks retained diagnostics truncated");

      Greplib.Paths.Clear (Roots);
      Ensure_Directory ("generated");
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("generated"));
      Search_Options := (others => <>);
      Search_Options.Mode := Greplib.Options.Count_Matches;
      Search_Options.Invert_Match := True;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Failed, "invalid search options fail before traversal");
      Assert (Reason (Outcome) = Greplib.Results.Fatal_Error, "invalid search options report fatal reason");
      Assert (Sources_Considered (Outcome) = 0, "invalid search options consume no sources");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
         "configuration.invalid_option_combination",
         "invalid search option diagnostic is retained");

      declare
         Rules : Greplib.Path_Filters.Filter_List;
         Filters : Greplib.Path_Filters.Compiled_Filter_Set;
         Empty_Roots : Greplib.Paths.Path_List;
      begin
         Greplib.Path_Filters.Append
           (Rules,
            Greplib.Path_Filters.Rule
              (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
               Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Regular_Expression, "["));
         Filters := Greplib.Path_Filters.Compile (Rules);
         Search_Options := (others => <>);
         declare
            Filtered_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
              Greplib.Directories.Validate (Roots, Set, Filters, Search_Options, Directory_Options);
         begin
            Assert (Natural (Filtered_Diagnostics.Length) = 1, "filtered directory validation counts filters");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Filtered_Diagnostics.Element (1))) =
               "path_filter.invalid_pattern",
               "filtered directory validation retains filter diagnostic");
         end;

         Search_Options.Maximum_Retained_Diagnostics := 0;
         Greplib.Directories.Search_Paths
           (Roots, Set, Filters, Search_Options, Directory_Options, Sink, Outcome);
         Assert (Status (Outcome) = Greplib.Results.Failed, "unusable filters fail before traversal");
         Assert (Reason (Outcome) = Greplib.Results.Fatal_Error, "unusable filters report fatal reason");
         Assert (Diagnostic_Count (Outcome) = 1, "unusable filter diagnostic counted");
         Assert (Natural (Diagnostics (Outcome).Length) = 0, "zero retention keeps no filter diagnostic");
         Assert (Diagnostics_Truncated (Outcome), "zero retention marks filter diagnostic truncated");

         Search_Options := (others => <>);
         declare
            Combined_Diagnostics : constant Greplib.Diagnostics.Diagnostic_List :=
              Greplib.Directories.Validate (Empty_Roots, Set, Filters, Search_Options, Directory_Options);
         begin
            Assert (Natural (Combined_Diagnostics.Length) = 2, "filtered validation aggregates empty roots");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Combined_Diagnostics.Element (1))) =
               "configuration.empty_root_list",
               "filtered validation reports empty root first");
            Assert
              (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Combined_Diagnostics.Element (2))) =
               "path_filter.invalid_pattern",
               "filtered validation reports unusable filter second");
         end;

         Greplib.Directories.Search_Paths
           (Empty_Roots, Set, Filters, Search_Options, Directory_Options, Sink, Outcome);
         Assert
           (Diagnostic_Count (Outcome) = 2,
            "empty roots and unusable filters report independent diagnostics");
         Assert (Natural (Diagnostics (Outcome).Length) = 2, "combined pre-traversal diagnostics retained");
      end;
   end Test_Directory_Retention_And_Validation;

   procedure Test_Directory_Quiet_Stops_After_First_Match is
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

      Root : constant String := "generated/directory_quiet";
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Sink : Null_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);
      Write_File (Root & "/a.txt", "hit");
      Write_File (Root & "/b.txt", "hit");
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
      Search_Options.Mode := Greplib.Options.Quiet;

      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);

      Assert (Status (Outcome) = Greplib.Results.Completed, "directory quiet mode completes after match");
      Assert
        (Reason (Outcome) = Greplib.Results.Quiet_Match_Found,
         "directory quiet reports quiet match reason");
      Assert (Sources_Considered (Outcome) = 1, "directory quiet searches only first matching source");
      Assert (Sources_With_Results (Outcome) = 1, "directory quiet records source result");
   end Test_Directory_Quiet_Stops_After_First_Match;

   procedure Test_Directory_Concurrent_Deterministic_Delivery is
      Expected_Task : constant Ada.Task_Identification.Task_Id :=
        Ada.Task_Identification.Current_Task;

      type Order_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         Names : U.Unbounded_String;
      end record;

      overriding procedure On_Event
        (Sink : in out Order_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);

      overriding procedure On_Event
        (Sink : in out Order_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         Assert
           (Ada.Task_Identification.Current_Task = Expected_Task,
            "concurrent directory callbacks run on caller task");

         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
            U.Append (Sink.Names, Greplib.Paths.Image (Greplib.Events.Source_Path (Event)));
            U.Append (Sink.Names, Character'Val (10));
         end if;
      end On_Event;

      Root : constant String := "generated/directory_concurrent";
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Sequential_Options : Greplib.Directories.Directory_Search_Options;
      Concurrent_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Sequential_Sink : Order_Sink;
      Concurrent_Sink : Order_Sink;
      Sequential_Outcome : Greplib.Results.Search_Outcome;
      Concurrent_Outcome : Greplib.Results.Search_Outcome;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);

      Write_File (Root & "/c.txt", "hit");
      Write_File (Root & "/a.txt", "hit");
      Write_File (Root & "/b.txt", "hit");

      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));

      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Sequential_Options, Sequential_Sink, Sequential_Outcome);

      Concurrent_Options.Worker_Count := 2;
      Concurrent_Options.Maximum_Queued_Events_Per_Source := 1;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Concurrent_Options, Concurrent_Sink, Concurrent_Outcome);

      Assert (Status (Sequential_Outcome) = Greplib.Results.Completed, "sequential directory search completes");
      Assert (Status (Concurrent_Outcome) = Greplib.Results.Completed, "concurrent directory search completes");
      Assert (Sequential_Sink.Selected = 3, "sequential directory emits three selected records");
      Assert (Concurrent_Sink.Selected = 3, "concurrent directory emits three selected records");
      Assert
        (U.To_String (Concurrent_Sink.Names) = U.To_String (Sequential_Sink.Names),
         "concurrent deterministic delivery matches sequential delivery");
      Assert
        (Selected_Record_Count (Concurrent_Outcome) =
         Selected_Record_Count (Sequential_Outcome),
         "concurrent summary selected count matches sequential summary");
      declare
         Summaries : constant Greplib.Results.Source_Summary_List :=
           Greplib.Results.Source_Summaries (Concurrent_Outcome);
      begin
         Assert (Greplib.Results.Length (Summaries) = 3, "concurrent outcome retains source summaries");
         for I in 1 .. 3 loop
            declare
               Summary : constant Greplib.Results.Source_Summary := Greplib.Results.Element (Summaries, I);
               Expected_Path : constant String :=
                 Root & "/" & (case I is when 1 => "a.txt", when 2 => "b.txt", when others => "c.txt");
            begin
               Assert
                 (Greplib.Sources.Sequence (Greplib.Results.Source (Summary)) = Greplib.Source_Sequence (I),
                  "concurrent source summary sequence follows traversal order");
               Assert
                 (Greplib.Paths.Image (Greplib.Sources.Path (Greplib.Results.Source (Summary))) = Expected_Path,
                  "concurrent source summary path follows deterministic order");
            end;
         end loop;
      end;
   end Test_Directory_Concurrent_Deterministic_Delivery;

   procedure Test_Directory_Concurrent_Completion_Order is
      Expected_Task : constant Ada.Task_Identification.Task_Id :=
        Ada.Task_Identification.Current_Task;

      type Counting_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
      end record;

      overriding procedure On_Event
        (Sink : in out Counting_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);

      overriding procedure On_Event
        (Sink : in out Counting_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         Assert
           (Ada.Task_Identification.Current_Task = Expected_Task,
            "completion-order callbacks run on caller task");

         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
         end if;
      end On_Event;

      Root : constant String := "generated/directory_completion_order";
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Sink : Counting_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);

      Write_File (Root & "/c.txt", "hit");
      Write_File (Root & "/a.txt", "hit");
      Write_File (Root & "/b.txt", "hit");

      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));

      Search_Options.Order := Greplib.Options.Completion_Order;
      Directory_Options.Worker_Count := 2;
      Directory_Options.Maximum_Queued_Events_Per_Source := 1;

      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);

      Assert (Status (Outcome) = Greplib.Results.Completed, "completion-order concurrent directory search completes");
      Assert (Sink.Selected = 3, "completion-order concurrent directory emits three selected records");
      Assert (Selected_Record_Count (Outcome) = 3, "completion-order summary selected count is exact");
      Assert (Sources_Considered (Outcome) = 3, "completion-order considers every accepted file");
   end Test_Directory_Concurrent_Completion_Order;

   procedure Test_Generated_Concurrent_Directory_Matrix is
      type Matrix_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         Last_Sequence : Greplib.Source_Sequence := 1;
         Have_Sequence : Boolean := False;
         Enforce_Order : Boolean := False;
      end record;

      overriding procedure On_Event
        (Sink : in out Matrix_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);

      overriding procedure On_Event
        (Sink : in out Matrix_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
            if Sink.Enforce_Order and then Sink.Have_Sequence then
               Assert
                 (Greplib.Events.Source_No (Event) >= Sink.Last_Sequence,
                  "generated concurrent deterministic sequence order");
            end if;
            Sink.Last_Sequence := Greplib.Events.Source_No (Event);
            Sink.Have_Sequence := True;
         end if;
      end On_Event;

      type Wide_Array is array (Positive range <>) of Greplib.Wide_Count;
      Workers : constant Wide_Array := (2, 3);
      Queue_Limits : constant Wide_Array := (2, 3);
      In_Flight_Limits : constant Wide_Array := (2, 3);
      Event_Limits : constant Wide_Array := (1, 2);
      Orders : constant array (Positive range 1 .. 2) of Greplib.Options.Result_Order :=
        (Greplib.Options.Deterministic, Greplib.Options.Completion_Order);

      Root : constant String := "generated/directory_concurrent_matrix";
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Roots : Greplib.Paths.Path_List;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);
      for I in 1 .. 5 loop
         Write_File (Root & "/file" & Natural'Image (I) & ".txt", "hit");
      end loop;

      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));

      for Repeat in 1 .. 2 loop
         for Worker_Count of Workers loop
            for Queue_Limit of Queue_Limits loop
               for In_Flight of In_Flight_Limits loop
                  for Event_Limit of Event_Limits loop
                     if Worker_Count <= Queue_Limit and then Worker_Count <= In_Flight then
                        for Order of Orders loop
                           declare
                              Search_Options : Greplib.Options.Search_Options;
                              Directory_Options : Greplib.Directories.Directory_Search_Options;
                              Sink : Matrix_Sink :=
                                (Selected => 0,
                                 Last_Sequence => 1,
                                 Have_Sequence => False,
                                 Enforce_Order => Order = Greplib.Options.Deterministic);
                              Outcome : Greplib.Results.Search_Outcome;
                              Scenario : constant String :=
                                "repeat=" & Natural'Image (Repeat) &
                                " workers=" & Greplib.Wide_Count'Image (Worker_Count) &
                                " queue=" & Greplib.Wide_Count'Image (Queue_Limit) &
                                " inflight=" & Greplib.Wide_Count'Image (In_Flight) &
                                " events=" & Greplib.Wide_Count'Image (Event_Limit);
                           begin
                              Search_Options.Order := Order;
                              Directory_Options.Worker_Count := Worker_Count;
                              Directory_Options.Maximum_Queued_Sources := Queue_Limit;
                              Directory_Options.Maximum_In_Flight_Sources := In_Flight;
                              Directory_Options.Maximum_Queued_Events_Per_Source := Event_Limit;

                              Greplib.Directories.Search_Paths
                                (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);

                              Assert (Status (Outcome) = Greplib.Results.Completed, Scenario & " completed");
                              Assert (Sources_Considered (Outcome) = 5, Scenario & " sources considered");
                              Assert (Selected_Record_Count (Outcome) = 5, Scenario & " selected count");
                              Assert (Sink.Selected = 5, Scenario & " selected events");
                              Assert (Sources_Completed (Outcome) = 5, Scenario & " sources completed");
                           end;
                        end loop;
                     end if;
                  end loop;
               end loop;
            end loop;
         end loop;
      end loop;
   end Test_Generated_Concurrent_Directory_Matrix;

   procedure Test_Directory_Concurrent_Callback_Stops is
      type Stop_Current_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         Completed : Natural := 0;
      end record;
      type Stop_All_Sink is new Greplib.Events.Event_Sink with record
         Selected : Natural := 0;
         Completed : Natural := 0;
      end record;
      type Cancelling_Sink is new Greplib.Events.Event_Sink with record
         Source : access Greplib.Cancellation.Cancellation_Source;
         Selected : Natural := 0;
      end record;

      overriding procedure On_Event
        (Sink : in out Stop_Current_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Stop_All_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Cancelling_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);

      overriding procedure On_Event
        (Sink : in out Stop_Current_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
            Action := Greplib.Events.Stop_Current_Source;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Source_Completed then
            Sink.Completed := Sink.Completed + 1;
         end if;
      end On_Event;

      overriding procedure On_Event
        (Sink : in out Stop_All_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
            Action := Greplib.Events.Stop_All_Search;
         elsif Greplib.Events.Kind (Event) = Greplib.Events.Source_Completed then
            Sink.Completed := Sink.Completed + 1;
         end if;
      end On_Event;

      overriding procedure On_Event
        (Sink : in out Cancelling_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            Sink.Selected := Sink.Selected + 1;
            if Sink.Source /= null then
               Sink.Source.Request;
            end if;
         end if;
      end On_Event;

      Root : constant String := "generated/directory_concurrent_callback_stops";
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Current_Sink : Stop_Current_Sink;
      All_Sink : Stop_All_Sink;
      Cancel_Source : aliased Greplib.Cancellation.Cancellation_Source;
      Cancel_Sink : Cancelling_Sink := (Source => Cancel_Source'Unchecked_Access, Selected => 0);
      Current_Outcome : Greplib.Results.Search_Outcome;
      All_Outcome : Greplib.Results.Search_Outcome;
      Cancel_Outcome : Greplib.Results.Search_Outcome;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);

      Write_File (Root & "/a.txt", "hit" & ASCII.LF & "hit");
      Write_File (Root & "/b.txt", "hit");

      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));
      Directory_Options.Worker_Count := 2;
      Directory_Options.Maximum_Queued_Sources := 2;

      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Current_Sink, Current_Outcome);
      Assert (Current_Sink.Selected >= 1, "concurrent stop-current delivers a selected record");
      Assert (Current_Sink.Completed = 0, "concurrent stop-current suppresses completed callbacks");
      Assert (Status (Current_Outcome) = Greplib.Results.Completed, "concurrent stop-current remains completed");
      Assert
        (Reason (Current_Outcome) = Greplib.Results.Callback_Stopped_Source,
         "concurrent stop-current summary reason");
      Assert
        (Selected_Record_Count (Current_Outcome) = Greplib.Wide_Count (Current_Sink.Selected),
         "concurrent stop-current counts delivered selected records");

      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, All_Sink, All_Outcome);
      Assert (All_Sink.Selected = 1, "concurrent stop-all suppresses later selected callbacks");
      Assert (All_Sink.Completed = 0, "concurrent stop-all suppresses completed callbacks");
      Assert (Status (All_Outcome) = Greplib.Results.Cancelled, "concurrent stop-all returns cancelled outcome");
      Assert
        (Reason (All_Outcome) = Greplib.Results.Callback_Stopped_Search,
         "concurrent stop-all summary reason");
      Assert
        (Selected_Record_Count (All_Outcome) = 1,
         "concurrent stop-all counts delivered selected records");

      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Cancel_Sink, Cancel_Outcome,
         Greplib.Cancellation.Token (Cancel_Source));
      Assert
        (Status (Cancel_Outcome) in Greplib.Results.Completed | Greplib.Results.Cancelled,
         "concurrent external cancellation returns a coherent outcome");
      Assert
        (Sources_Considered (Cancel_Outcome) >= 1,
         "concurrent external cancellation does not strand source channels");
   end Test_Directory_Concurrent_Callback_Stops;

   procedure Test_Directory_Callback_Exception_Propagates is
      Callback_Failure : exception;
      type Raising_Sink is new Greplib.Events.Event_Sink with null record;
      overriding procedure On_Event
        (Sink : in out Raising_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action);
      overriding procedure On_Event
        (Sink : in out Raising_Sink;
         Event : Greplib.Events.Search_Event;
         Action : out Greplib.Events.Event_Action) is
      begin
         Action := Greplib.Events.Continue_Search;
         if Greplib.Events.Kind (Event) = Greplib.Events.Selected_Record then
            raise Callback_Failure;
         end if;
      end On_Event;

      Root : constant String := "generated/directory_callback_exception";
      Patterns : Greplib.Patterns.Pattern_List;
      Set : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Sink : Raising_Sink;
      Outcome : Greplib.Results.Search_Outcome;
      Propagated : Boolean := False;
   begin
      Ensure_Directory ("generated");
      Ensure_Directory (Root);
      Write_File (Root & "/match.txt", "hit");
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path (Root));

      begin
         Greplib.Directories.Search_Paths
           (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      exception
         when Callback_Failure =>
            Propagated := True;
      end;

      Assert (Propagated, "directory search propagates callback exceptions unchanged");
   end Test_Directory_Callback_Exception_Propagates;

   procedure Test_Path_Filter_Glob_Semantics is
      Rules : Greplib.Path_Filters.Filter_List;
      Set : Greplib.Path_Filters.Compiled_Filter_Set;
   begin
      Greplib.Path_Filters.Append
        (Rules,
         Greplib.Path_Filters.Rule
           (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
            Greplib.Path_Filters.Relative_Path, Greplib.Path_Filters.Glob_Pattern, "*.tmp"));
      Set := Greplib.Path_Filters.Compile (Rules);
      Assert
        (not Greplib.Path_Filters.Included (Set, "a.tmp", "a.tmp", False),
         "star matches basename-like relative path");
      Assert
        (Greplib.Path_Filters.Included (Set, "b.tmp", "dir/b.tmp", False),
         "star does not cross separators");

      Greplib.Path_Filters.Append
        (Rules,
         Greplib.Path_Filters.Rule
           (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
            Greplib.Path_Filters.Relative_Path, Greplib.Path_Filters.Glob_Pattern, "**/*.tmp"));
      Set := Greplib.Path_Filters.Compile (Rules);
      Assert
        (not Greplib.Path_Filters.Included (Set, "b.tmp", "dir/b.tmp", False),
         "double-star crosses separators");

      Greplib.Path_Filters.Append
        (Rules,
         Greplib.Path_Filters.Rule
           (Greplib.Path_Filters.Include, Greplib.Path_Filters.Files_Only,
            Greplib.Path_Filters.Relative_Path, Greplib.Path_Filters.Exact_Name, "dir/b.tmp"));
      Set := Greplib.Path_Filters.Compile (Rules);
      Assert
        (Greplib.Path_Filters.Included (Set, "b.tmp", "dir/b.tmp", False),
         "later include wins");

      declare
         Escape_Rules : Greplib.Path_Filters.Filter_List;
         Escape_Set : Greplib.Path_Filters.Compiled_Filter_Set;
      begin
         Greplib.Path_Filters.Append
           (Escape_Rules,
            Greplib.Path_Filters.Rule
              (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
               Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Glob_Pattern, "a\*b"));
         Escape_Set := Greplib.Path_Filters.Compile (Escape_Rules);
         Assert
           (not Greplib.Path_Filters.Included (Escape_Set, "a*b", "a*b", False),
            "escaped star matches literal star");
         Assert
           (Greplib.Path_Filters.Included (Escape_Set, "axxb", "axxb", False),
            "escaped star is not a wildcard");
      end;

      declare
         Exact_Rules : Greplib.Path_Filters.Filter_List;
         Exact_Set : Greplib.Path_Filters.Compiled_Filter_Set;
      begin
         Greplib.Path_Filters.Append
           (Exact_Rules,
            Greplib.Path_Filters.Rule
              (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
               Greplib.Path_Filters.Relative_Path, Greplib.Path_Filters.Exact_Name, "dir\file.txt"));
         Exact_Set := Greplib.Path_Filters.Compile (Exact_Rules);
         Assert
           (not Greplib.Path_Filters.Included (Exact_Set, "file.txt", "dir/file.txt", False),
            "exact relative filter normalizes pattern separators");
         Assert
           (not Greplib.Path_Filters.Included (Exact_Set, "file.txt", "dir\file.txt", False),
            "exact relative filter normalizes subject separators");
      end;

      declare
         Regex_Rules : Greplib.Path_Filters.Filter_List;
         Regex_Set : Greplib.Path_Filters.Compiled_Filter_Set;
      begin
         Greplib.Path_Filters.Append
           (Regex_Rules,
            Greplib.Path_Filters.Rule
              (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
               Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Regular_Expression, ".*[.]tmp"));
         Regex_Set := Greplib.Path_Filters.Compile (Regex_Rules);
         Assert (Greplib.Path_Filters.Is_Usable (Regex_Set), "regex filter compiles once");
         Assert
           (not Greplib.Path_Filters.Included (Regex_Set, "x.tmp", "x.tmp", False),
            "compiled regex filter excludes matching file");
         Assert
           (Greplib.Path_Filters.Included (Regex_Set, "x.txt", "x.txt", False),
            "compiled regex filter leaves nonmatching file");
      end;

      declare
         Relative_Regex_Rules : Greplib.Path_Filters.Filter_List;
         Relative_Regex_Set : Greplib.Path_Filters.Compiled_Filter_Set;
      begin
         Greplib.Path_Filters.Append
           (Relative_Regex_Rules,
            Greplib.Path_Filters.Rule
              (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
               Greplib.Path_Filters.Relative_Path, Greplib.Path_Filters.Regular_Expression, "dir/file[.]txt"));
         Relative_Regex_Set := Greplib.Path_Filters.Compile (Relative_Regex_Rules);
         Assert
           (not Greplib.Path_Filters.Included
              (Relative_Regex_Set, "file.txt", "dir\file.txt", False),
            "relative regex filter normalizes subject separators");
      end;
   end Test_Path_Filter_Glob_Semantics;

   procedure Test_Generated_Path_Filter_Model is
      type Rule_Model is record
         Action : Greplib.Path_Filters.Filter_Action;
         Target : Greplib.Path_Filters.Filter_Target;
         Basis : Greplib.Path_Filters.Filter_Basis;
         Kind : Greplib.Path_Filters.Filter_Kind;
         Pattern : U.Unbounded_String;
      end record;
      type Rule_Model_Array is array (Positive range <>) of Rule_Model;
      type Subject_Model is record
         Base : U.Unbounded_String;
         Relative : U.Unbounded_String;
         Directory : Boolean := False;
      end record;
      type Subject_Array is array (Positive range <>) of Subject_Model;

      Subjects : constant Subject_Array :=
        ((U.To_Unbounded_String ("a.tmp"), U.To_Unbounded_String ("a.tmp"), False),
         (U.To_Unbounded_String ("b.txt"), U.To_Unbounded_String ("dir/b.txt"), False),
         (U.To_Unbounded_String ("c.tmp"), U.To_Unbounded_String ("dir/c.tmp"), False),
         (U.To_Unbounded_String ("keep.tmp"), U.To_Unbounded_String ("a/keep.tmp"), False),
         (U.To_Unbounded_String ("pruned"), U.To_Unbounded_String ("pruned"), True),
         (U.To_Unbounded_String ("sub"), U.To_Unbounded_String ("a/sub"), True),
         (U.To_Unbounded_String ("a*b"), U.To_Unbounded_String ("literal/a*b"), False),
         (U.To_Unbounded_String ("axb"), U.To_Unbounded_String ("literal/axb"), False));

      function Normalize (Text : String) return String is
         Result : String := Text;
      begin
         for C of Result loop
            if C = '\' then
               C := '/';
            end if;
         end loop;
         return Result;
      end Normalize;

      function Glob_Reference (Text : String; Pattern : String) return Boolean is
         function Match (T : Natural; P : Natural) return Boolean is
         begin
            if P > Pattern'Length then
               return T > Text'Length;
            elsif Pattern (Pattern'First + P - 1) = '\' then
               return P < Pattern'Length
                 and then T <= Text'Length
                 and then Text (Text'First + T - 1) = Pattern (Pattern'First + P)
                 and then Match (T + 1, P + 2);
            elsif Pattern (Pattern'First + P - 1) = '*' then
               if P < Pattern'Length and then Pattern (Pattern'First + P) = '*' then
                  return Match (T, P + 2) or else (T <= Text'Length and then Match (T + 1, P));
               else
                  return Match (T, P + 1)
                    or else
                      (T <= Text'Length
                       and then Text (Text'First + T - 1) /= '/'
                       and then Match (T + 1, P));
               end if;
            elsif Pattern (Pattern'First + P - 1) = '?' then
               return T <= Text'Length
                 and then Text (Text'First + T - 1) /= '/'
                 and then Match (T + 1, P + 1);
            else
               return T <= Text'Length
                 and then Text (Text'First + T - 1) = Pattern (Pattern'First + P - 1)
                 and then Match (T + 1, P + 1);
            end if;
         end Match;
      begin
         return Match (1, 1);
      end Glob_Reference;

      function Expected (Rules : Rule_Model_Array; Subject : Subject_Model) return Boolean is
         Result : Boolean := True;
      begin
         for Rule of Rules loop
            if Rule.Target = Greplib.Path_Filters.Any_Entry
              or else (Rule.Target = Greplib.Path_Filters.Files_Only and then not Subject.Directory)
              or else (Rule.Target = Greplib.Path_Filters.Directories_Only and then Subject.Directory)
            then
               declare
                  Raw_Subject : constant String :=
                    (if Rule.Basis = Greplib.Path_Filters.Base_Name
                     then U.To_String (Subject.Base)
                     else Normalize (U.To_String (Subject.Relative)));
                  Pattern : constant String :=
                    (if Rule.Basis = Greplib.Path_Filters.Relative_Path
                       and then Rule.Kind = Greplib.Path_Filters.Exact_Name
                     then Normalize (U.To_String (Rule.Pattern))
                     else U.To_String (Rule.Pattern));
                  Hit : Boolean := False;
               begin
                  case Rule.Kind is
                     when Greplib.Path_Filters.Exact_Name =>
                        Hit := Raw_Subject = Pattern;
                     when Greplib.Path_Filters.Glob_Pattern =>
                        Hit := Glob_Reference (Raw_Subject, Pattern);
                     when Greplib.Path_Filters.Regular_Expression =>
                        Hit := False;
                  end case;
                  if Hit then
                     Result := Rule.Action = Greplib.Path_Filters.Include;
                  end if;
               end;
            end if;
         end loop;
         return Result;
      end Expected;

      procedure Check_Rules (Name : String; Rules : Rule_Model_Array) is
         List : Greplib.Path_Filters.Filter_List;
         Set : Greplib.Path_Filters.Compiled_Filter_Set;
      begin
         for Rule of Rules loop
            Greplib.Path_Filters.Append
              (List,
               Greplib.Path_Filters.Rule
                 (Rule.Action, Rule.Target, Rule.Basis, Rule.Kind, U.To_String (Rule.Pattern)));
         end loop;
         Set := Greplib.Path_Filters.Compile (List);
         Assert (Greplib.Path_Filters.Is_Usable (Set), Name & " compiles");

         for Subject of Subjects loop
            declare
               Base : constant String := U.To_String (Subject.Base);
               Relative : constant String := U.To_String (Subject.Relative);
            begin
               Assert
                 (Greplib.Path_Filters.Included (Set, Base, Relative, Subject.Directory) =
                  Expected (Rules, Subject),
                  Name & " subject " & Relative);
            end;
         end loop;
      end Check_Rules;
   begin
      Check_Rules
        ("generated basename glob",
         (1 =>
            Rule_Model'
              (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
               Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Glob_Pattern,
               U.To_Unbounded_String ("*.tmp"))));
      Check_Rules
        ("generated last-rule wins",
         (Rule_Model'
            (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
             Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Glob_Pattern,
             U.To_Unbounded_String ("*.tmp")),
          Rule_Model'
            (Greplib.Path_Filters.Include, Greplib.Path_Filters.Files_Only,
             Greplib.Path_Filters.Relative_Path, Greplib.Path_Filters.Exact_Name,
             U.To_Unbounded_String ("a/keep.tmp"))));
      Check_Rules
        ("generated directory target",
         (Rule_Model'
            (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Directories_Only,
             Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Exact_Name,
             U.To_Unbounded_String ("pruned")),
          Rule_Model'
            (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
             Greplib.Path_Filters.Relative_Path, Greplib.Path_Filters.Glob_Pattern,
             U.To_Unbounded_String ("**/*.tmp"))));
      Check_Rules
        ("generated glob escaping",
         (Rule_Model'
            (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
             Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Glob_Pattern,
             U.To_Unbounded_String ("a\*b")),
          Rule_Model'
            (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
             Greplib.Path_Filters.Relative_Path, Greplib.Path_Filters.Glob_Pattern,
             U.To_Unbounded_String ("literal/a?b"))));
   end Test_Generated_Path_Filter_Model;

   procedure Test_Internal_Fake_Filesystem_Traversal is
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
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Roots : Greplib.Paths.Path_List;
      Sink : Null_Sink;
      Outcome : Greplib.Results.Search_Outcome;
   begin
      Greplib.Patterns.Append (Patterns, Greplib.Patterns.Fixed_String_Pattern ("hit"));
      Set := Greplib.Patterns.Compile (Patterns);
      Greplib.Paths.Append (Roots, Greplib.Paths.To_Path ("fake-root"));

      Greplib.Internal.Filesystem.Clear_Fake;
      Greplib.Internal.Filesystem.Add_Fake_Entry
        ("fake-root", Greplib.Internal.Filesystem.Directory, Identity => "dir:root");
      Greplib.Internal.Filesystem.Add_Fake_Entry
        ("fake-root/a.txt", Greplib.Internal.Filesystem.Ordinary_File,
         Content => "hit" & ASCII.LF & "miss", Has_Content => True);
      Greplib.Internal.Filesystem.Add_Fake_Entry
        ("fake-root/.hidden", Greplib.Internal.Filesystem.Ordinary_File,
         Content => "hit", Has_Content => True);

      Directory_Options.Include_Hidden := False;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "fake file content searches without host open");
      Assert (Directories_Visited (Outcome) = 1, "fake root directory visited");
      Assert (Entries_Examined (Outcome) = 2, "fake hidden child is examined");
      Assert (Files_Accepted (Outcome) = 1, "fake hidden child is filtered before search");
      Assert (Sources_Considered (Outcome) = 1, "fake accepted file consumes a source");
      Assert (Selected_Record_Count (Outcome) = 1, "fake file content produces selected record count");

      Greplib.Internal.Filesystem.Clear_Fake;
      Greplib.Internal.Filesystem.Add_Fake_Entry
        ("fake-root", Greplib.Internal.Filesystem.Directory, Fail_Children => True);
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert
        (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "fake child enumeration failure is recoverable");
      Assert (Files_Accepted (Outcome) = 0, "fake child failure accepts no files");
      Assert (Diagnostic_Count (Outcome) = 1, "fake child failure records diagnostic");

      Greplib.Internal.Filesystem.Clear_Fake;
      Greplib.Internal.Filesystem.Add_Fake_Entry
        ("fake-root", Greplib.Internal.Filesystem.Directory);
      Greplib.Internal.Filesystem.Add_Fake_Entry
        ("fake-root/one.txt", Greplib.Internal.Filesystem.Ordinary_File);
      Greplib.Internal.Filesystem.Add_Fake_Entry
        ("fake-root/two.txt", Greplib.Internal.Filesystem.Ordinary_File);
      Directory_Options.Maximum_Directory_Entries := 1;
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert
        (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "fake entry limit is recoverable");
      Assert (Files_Accepted (Outcome) = 0, "fake entry limit skips accepted files");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
         "resource.directory_entry_limit_exceeded",
         "fake entry limit diagnostic identifier");

      Greplib.Internal.Filesystem.Clear_Fake;
      Greplib.Internal.Filesystem.Add_Fake_Entry
        ("fake-root", Greplib.Internal.Filesystem.Directory);
      Greplib.Internal.Filesystem.Add_Fake_Entry
        ("fake-root/bad.txt", Greplib.Internal.Filesystem.Ordinary_File, Fail_Kind => True);
      Directory_Options := (others => <>);
      Greplib.Directories.Search_Paths
        (Roots, Set, Search_Options, Directory_Options, Sink, Outcome);
      Assert
        (Status (Outcome) = Greplib.Results.Completed_With_Recoverable_Errors,
         "fake kind failure is recoverable");
      Assert (Files_Accepted (Outcome) = 0, "fake kind failure skips file");
      Assert (Diagnostic_Count (Outcome) = 1, "fake kind failure records diagnostic");

      Greplib.Internal.Filesystem.Clear_Fake;
      Greplib.Internal.Filesystem.Add_Fake_Entry
        ("fake-file", Greplib.Internal.Filesystem.Ordinary_File,
         Content => "hit" & ASCII.LF & "hit", Has_Content => True);
      Greplib.Files.Search_File
        (Greplib.Paths.To_Path ("fake-file"), Set, Search_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Completed, "direct fake file search completes");
      Assert (Sources_Opened (Outcome) = 1, "direct fake file search opens logical source");
      Assert (Selected_Record_Count (Outcome) = 2, "direct fake file search reads fake content");

      Greplib.Internal.Filesystem.Clear_Fake;
      Greplib.Internal.Filesystem.Add_Fake_Entry
        ("fake-read-fails", Greplib.Internal.Filesystem.Ordinary_File,
         Content => "hit" & ASCII.LF & "tail", Has_Content => True, Fail_Read_After => 2);
      Greplib.Files.Search_File
        (Greplib.Paths.To_Path ("fake-read-fails"), Set, Search_Options, Sink, Outcome);
      Assert (Status (Outcome) = Greplib.Results.Failed, "fake read failure fails source");
      Assert (Diagnostic_Count (Outcome) = 1, "fake read failure emits diagnostic");
      Assert
        (Greplib.Diagnostics.Identifier (Greplib.Diagnostics.Code (Diagnostics (Outcome).Element (1))) =
         "stream.read_failed",
         "fake read failure diagnostic identifier");

      Greplib.Internal.Filesystem.Use_Host;
   exception
      when others =>
         Greplib.Internal.Filesystem.Use_Host;
         raise;
   end Test_Internal_Fake_Filesystem_Traversal;

   procedure Test_Fake_Filesystem_Reference_Traversal is
      type Fake_Kind is (Fake_File, Fake_Directory, Fake_Symlink);
      type Fake_Node is record
         Path : U.Unbounded_String;
         Parent : U.Unbounded_String;
         Base : U.Unbounded_String;
         Kind : Fake_Kind := Fake_File;
         Hidden : Boolean := False;
         Filesystem : Natural := 1;
         Object : Natural := 0;
         Target : Natural := 0;
      end record;
      package Fake_Node_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Fake_Node);
      package Local_String_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, String);

      Nodes : Fake_Node_Vectors.Vector;
      Accepted : Local_String_Vectors.Vector;
      Ancestors : Local_String_Vectors.Vector;
      Rules : Greplib.Path_Filters.Filter_List;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Directories_Skipped : Natural := 0;
      Filesystem_Boundaries : Natural := 0;
      Cycles : Natural := 0;
      use type Ada.Containers.Count_Type;

      procedure Add
        (Path : String;
         Parent : String;
         Base : String;
         Kind : Fake_Kind;
         Object : Natural;
         Hidden : Boolean := False;
         Filesystem : Natural := 1;
         Target : Natural := 0) is
      begin
         Nodes.Append
           (Fake_Node'
              (Path => U.To_Unbounded_String (Path),
               Parent => U.To_Unbounded_String (Parent),
               Base => U.To_Unbounded_String (Base),
               Kind => Kind,
               Hidden => Hidden,
               Filesystem => Filesystem,
               Object => Object,
               Target => Target));
      end Add;

      function Node_By_Object (Object : Natural) return Fake_Node is
      begin
         for Node of Nodes loop
            if Node.Object = Object then
               return Node;
            end if;
         end loop;
         raise Program_Error;
      end Node_By_Object;

      function Contains (Items : Local_String_Vectors.Vector; Value : String) return Boolean is
      begin
         for Item of Items loop
            if Item = Value then
               return True;
            end if;
         end loop;
         return False;
      end Contains;

      procedure Sort (Items : in out Local_String_Vectors.Vector) is
      begin
         if Items.Length < 2 then
            return;
         end if;

         for I in Items.First_Index .. Items.Last_Index loop
            for J in I + 1 .. Items.Last_Index loop
               if Items.Element (J) < Items.Element (I) then
                  declare
                     Hold : constant String := Items.Element (I);
                  begin
                     Items.Replace_Element (I, Items.Element (J));
                     Items.Replace_Element (J, Hold);
                  end;
               end if;
            end loop;
         end loop;
      end Sort;

      function Relative (Path : String) return String is
         Prefix : constant String := "root/";
      begin
         if Path = "root" then
            return "";
         elsif Path'Length > Prefix'Length
           and then Path (Path'First .. Path'First + Prefix'Length - 1) = Prefix
         then
            return Path (Path'First + Prefix'Length .. Path'Last);
         else
            return Path;
         end if;
      end Relative;

      procedure Walk (Node : Fake_Node; Depth : Natural) is
         Effective : Fake_Node := Node;
         Child_Paths : Local_String_Vectors.Vector;
      begin
         if Node.Kind = Fake_Symlink then
            Effective := Node_By_Object (Node.Target);
         end if;

         if Effective.Kind = Fake_File then
            if Greplib.Path_Filters.Included
              (Filters, U.To_String (Node.Base), Relative (U.To_String (Node.Path)), False)
            then
               Accepted.Append (U.To_String (Node.Path));
            end if;
            return;
         end if;

         if Depth > 0
           and then not Greplib.Path_Filters.Included
             (Filters, U.To_String (Node.Base), Relative (U.To_String (Node.Path)), True)
         then
            Directories_Skipped := Directories_Skipped + 1;
            return;
         end if;

         if Effective.Filesystem /= 1 then
            Directories_Skipped := Directories_Skipped + 1;
            Filesystem_Boundaries := Filesystem_Boundaries + 1;
            return;
         end if;

         if Contains (Ancestors, Natural'Image (Effective.Object)) then
            Cycles := Cycles + 1;
            Directories_Skipped := Directories_Skipped + 1;
            return;
         end if;

         Ancestors.Append (Natural'Image (Effective.Object));
         for Child of Nodes loop
            if U.To_String (Child.Parent) = U.To_String (Node.Path) and then not Child.Hidden then
               Child_Paths.Append (U.To_String (Child.Path));
            end if;
         end loop;
         Sort (Child_Paths);

         for Child_Path of Child_Paths loop
            for Child of Nodes loop
               if U.To_String (Child.Path) = Child_Path then
                  Walk (Child, Depth + 1);
               end if;
            end loop;
         end loop;
         Ancestors.Delete_Last;
      end Walk;
   begin
      Greplib.Path_Filters.Append
        (Rules,
         Greplib.Path_Filters.Rule
           (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Files_Only,
            Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Glob_Pattern, "*.tmp"));
      Greplib.Path_Filters.Append
        (Rules,
         Greplib.Path_Filters.Rule
           (Greplib.Path_Filters.Include, Greplib.Path_Filters.Files_Only,
            Greplib.Path_Filters.Relative_Path, Greplib.Path_Filters.Exact_Name, "a/keep.tmp"));
      Greplib.Path_Filters.Append
        (Rules,
         Greplib.Path_Filters.Rule
           (Greplib.Path_Filters.Exclude, Greplib.Path_Filters.Directories_Only,
            Greplib.Path_Filters.Base_Name, Greplib.Path_Filters.Exact_Name, "pruned"));
      Filters := Greplib.Path_Filters.Compile (Rules);

      Add ("root", "", "root", Fake_Directory, 1);
      Add ("root/.hidden.txt", "root", ".hidden.txt", Fake_File, 2, Hidden => True);
      Add ("root/a", "root", "a", Fake_Directory, 3);
      Add ("root/a/hit.txt", "root/a", "hit.txt", Fake_File, 4);
      Add ("root/a/keep.tmp", "root/a", "keep.tmp", Fake_File, 5);
      Add ("root/b.txt", "root", "b.txt", Fake_File, 6);
      Add ("root/boundary", "root", "boundary", Fake_Directory, 7, Filesystem => 2);
      Add ("root/boundary/out.txt", "root/boundary", "out.txt", Fake_File, 8, Filesystem => 2);
      Add ("root/loop", "root", "loop", Fake_Symlink, 9, Target => 1);
      Add ("root/pruned", "root", "pruned", Fake_Directory, 10);
      Add ("root/pruned/revive.txt", "root/pruned", "revive.txt", Fake_File, 11);

      Walk (Nodes.Element (1), 0);

      Assert (Accepted.Length = 3, "fake traversal accepts three files");
      Assert (Accepted.Element (1) = "root/a/hit.txt", "fake traversal preserves lexicographic order");
      Assert (Accepted.Element (2) = "root/a/keep.tmp", "fake traversal applies last-rule-wins include");
      Assert (Accepted.Element (3) = "root/b.txt", "fake traversal skips hidden, boundary, cycle, and pruned files");
      Assert (Directories_Skipped = 3, "fake traversal counts pruned, boundary, and cycle directories");
      Assert (Filesystem_Boundaries = 1, "fake traversal counts filesystem boundary directories separately");
      Assert (Cycles = 1, "fake traversal detects symlink cycle by object identity");
   end Test_Fake_Filesystem_Reference_Traversal;

   type Test_Procedure is access procedure;

   Mode : U.Unbounded_String := U.To_Unbounded_String ("fast");
   Suite_Filter : U.Unbounded_String;
   Test_Filter : U.Unbounded_String;
   Seed_Text : U.Unbounded_String;
   Repeat_Count : Positive := 1;
   Repeat_Set : Boolean := False;
   List_Only : Boolean := False;
   Keep_Temporary_Files : Boolean := False;
   Executed : Natural := 0;

   function Has_Prefix (Text : String; Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Has_Prefix;

   function Contains (Text : String; Fragment : String) return Boolean is
   begin
      if Fragment = "" then
         return True;
      end if;

      if Fragment'Length > Text'Length then
         return False;
      end if;

      for I in Text'First .. Text'Last - Fragment'Length + 1 loop
         if Text (I .. I + Fragment'Length - 1) = Fragment then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Usage is
   begin
      Ada.Text_IO.Put_Line
        ("usage: greplib_tests [--mode=fast|full|stress|release] [--suite=name] [--test=substring] " &
         "[--seed=integer] [--repeat=count] [--keep-temporary-files] [--list-tests]");
   end Usage;

   procedure Parse_Arguments (Valid : out Boolean) is
   begin
      Valid := True;
      for I in 1 .. Ada.Command_Line.Argument_Count loop
         declare
            Arg : constant String := Ada.Command_Line.Argument (I);
         begin
            if Has_Prefix (Arg, "--mode=") then
               Mode := U.To_Unbounded_String (Arg (Arg'First + 7 .. Arg'Last));
               if U.To_String (Mode) not in "fast" | "full" | "stress" | "release" then
                  Ada.Text_IO.Put_Line ("invalid --mode: " & U.To_String (Mode));
                  Valid := False;
               end if;
            elsif Has_Prefix (Arg, "--suite=") then
               Suite_Filter := U.To_Unbounded_String (Arg (Arg'First + 8 .. Arg'Last));
            elsif Has_Prefix (Arg, "--test=") then
               Test_Filter := U.To_Unbounded_String (Arg (Arg'First + 7 .. Arg'Last));
            elsif Has_Prefix (Arg, "--seed=") then
               Seed_Text := U.To_Unbounded_String (Arg (Arg'First + 7 .. Arg'Last));
            elsif Has_Prefix (Arg, "--repeat=") then
               begin
                  Repeat_Count := Positive'Value (Arg (Arg'First + 9 .. Arg'Last));
                  Repeat_Set := True;
               exception
                  when Constraint_Error =>
                     Ada.Text_IO.Put_Line ("invalid --repeat: " & Arg (Arg'First + 9 .. Arg'Last));
                     Valid := False;
               end;
            elsif Arg = "--keep-temporary-files" then
               Keep_Temporary_Files := True;
            elsif Arg = "--list-tests" then
               List_Only := True;
            else
               Ada.Text_IO.Put_Line ("unknown option: " & Arg);
               Valid := False;
            end if;
         end;
      end loop;

      if U.To_String (Mode) = "stress" and then not Repeat_Set then
         Repeat_Count := 3;
      end if;
   end Parse_Arguments;

   function Selected (Name : String) return Boolean is
   begin
      return Contains (Name, U.To_String (Suite_Filter)) and then Contains (Name, U.To_String (Test_Filter));
   end Selected;

   procedure Run_Test (Name : String; Test : Test_Procedure) is
   begin
      if not Selected (Name) then
         return;
      end if;

      if List_Only then
         Ada.Text_IO.Put_Line (Name);
      else
         for Pass in 1 .. Repeat_Count loop
            begin
               Test.all;
               Executed := Executed + 1;
            exception
               when others =>
                  Ada.Text_IO.Put_Line ("failed test: " & Name);
                  raise;
            end;
         end loop;
      end if;
   end Run_Test;

   procedure Run_All_Tests is
   begin
      Run_Test ("foundational_value_types", Test_Foundational_Value_Types'Access);
      Run_Test ("fixed_string", Test_Fixed_String'Access);
      Run_Test ("generated_fixed_string_model", Test_Generated_Fixed_String_Model'Access);
      Run_Test ("generated_fixed_boundary_model", Test_Generated_Fixed_Boundary_Model'Access);
      Run_Test ("invert_and_count", Test_Invert_And_Count'Access);
      Run_Test ("regex_adapter_whole_subject", Test_Regex_Adapter_Whole_Subject'Access);
      Run_Test ("regexp_adapter_conformance", Test_Regexp_Adapter_Conformance'Access);
      Run_Test ("pattern_compilation_atomicity", Test_Pattern_Compilation_Atomicity'Access);
      Run_Test ("pattern_resource_boundary_matrix", Test_Pattern_Resource_Boundary_Matrix'Access);
      Run_Test ("internal_execution_plans", Test_Internal_Execution_Plans'Access);
      Run_Test ("boundary_modes", Test_Boundary_Modes'Access);
      Run_Test ("record_metadata", Test_Record_Metadata'Access);
      Run_Test ("search_bytes_parity", Test_Search_Bytes_Parity'Access);
      Run_Test ("stream_source_descriptor", Test_Stream_Source_Descriptor'Access);
      Run_Test ("callback_free_search_overloads", Test_Callback_Free_Search_Overloads'Access);
      Run_Test ("stream_incremental_search", Test_Stream_Incremental_Search'Access);
      Run_Test ("generated_stream_block_matrix", Test_Generated_Stream_Block_Matrix'Access);
      Run_Test ("stream_prefix_binary_policies", Test_Stream_Prefix_Binary_Policies'Access);
      Run_Test ("stream_full_binary_nonrecord_modes", Test_Stream_Full_Binary_Nonrecord_Modes'Access);
      Run_Test ("stream_full_binary_record_modes", Test_Stream_Full_Binary_Record_Modes'Access);
      Run_Test ("stream_incremental_modes_and_metadata", Test_Stream_Incremental_Modes_And_Metadata'Access);
      Run_Test ("stream_incremental_context", Test_Stream_Incremental_Context'Access);
      Run_Test ("context_groups", Test_Context_Groups'Access);
      Run_Test ("generated_context_model", Test_Generated_Context_Model'Access);
      Run_Test ("selected_record_limit", Test_Selected_Record_Limit'Access);
      Run_Test ("binary_policies", Test_Binary_Policies'Access);
      Run_Test ("source_name_modes", Test_Source_Name_Modes'Access);
      Run_Test ("count_and_quiet_modes", Test_Count_And_Quiet_Modes'Access);
      Run_Test ("oversized_record_policies", Test_Oversized_Record_Policies'Access);
      Run_Test ("diagnostic_retention_limit", Test_Diagnostic_Retention_Limit'Access);
      Run_Test ("diagnostic_code_accessors", Test_Diagnostic_Code_Accessors'Access);
      Run_Test ("span_controls", Test_Span_Controls'Access);
      Run_Test ("generated_resource_boundaries", Test_Generated_Resource_Boundaries'Access);
      Run_Test ("callback_stop_current", Test_Callback_Stop_Current'Access);
      Run_Test ("callback_stop_all", Test_Callback_Stop_All'Access);
      Run_Test ("search_option_validation_no_input", Test_Search_Option_Validation_No_Input'Access);
      Run_Test ("collected_limits", Test_Collected_Limits'Access);
      Run_Test ("file_source_path", Test_File_Source_Path'Access);
      Run_Test ("file_open_failure", Test_File_Open_Failure'Access);
      Run_Test ("file_callback_exception_propagates", Test_File_Callback_Exception_Propagates'Access);
      Run_Test ("directory_path_filters", Test_Directory_Path_Filters'Access);
      Run_Test ("directory_file_type_policies", Test_Directory_File_Type_Policies'Access);
      Run_Test ("path_filter_compilation", Test_Path_Filter_Compilation'Access);
      Run_Test ("directory_hidden_and_cancellation", Test_Directory_Hidden_And_Cancellation'Access);
      Run_Test ("directory_error_aggregation", Test_Directory_Error_Aggregation'Access);
      Run_Test ("directory_symlink_policies", Test_Directory_Symlink_Policies'Access);
      Run_Test ("directory_match_count_completeness", Test_Directory_Match_Count_Completeness'Access);
      Run_Test ("directory_resource_limits", Test_Directory_Resource_Limits'Access);
      Run_Test ("directory_retention_and_validation", Test_Directory_Retention_And_Validation'Access);
      Run_Test ("directory_quiet_stops_after_first_match", Test_Directory_Quiet_Stops_After_First_Match'Access);
      Run_Test
        ("directory_concurrent_deterministic_delivery", Test_Directory_Concurrent_Deterministic_Delivery'Access);
      Run_Test ("directory_concurrent_completion_order", Test_Directory_Concurrent_Completion_Order'Access);
      Run_Test ("generated_concurrent_directory_matrix", Test_Generated_Concurrent_Directory_Matrix'Access);
      Run_Test ("directory_concurrent_callback_stops", Test_Directory_Concurrent_Callback_Stops'Access);
      Run_Test ("directory_callback_exception_propagates", Test_Directory_Callback_Exception_Propagates'Access);
      Run_Test ("path_filter_glob_semantics", Test_Path_Filter_Glob_Semantics'Access);
      Run_Test ("generated_path_filter_model", Test_Generated_Path_Filter_Model'Access);
      Run_Test ("internal_fake_filesystem_traversal", Test_Internal_Fake_Filesystem_Traversal'Access);
      Run_Test ("fake_filesystem_reference_traversal", Test_Fake_Filesystem_Reference_Traversal'Access);
   end Run_All_Tests;

   Valid_Arguments : Boolean := True;
begin
   Parse_Arguments (Valid_Arguments);
   if not Valid_Arguments then
      Usage;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   if Keep_Temporary_Files then
      null;
   end if;
   if U.Length (Seed_Text) /= 0 then
      null;
   end if;

   Run_All_Tests;
   if List_Only then
      return;
   end if;
   if Executed = 0 then
      Ada.Text_IO.Put_Line ("greplib_tests: no tests matched");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;
   Ada.Text_IO.Put_Line ("greplib_tests:" & Natural'Image (Executed) & " tests passed");
end Greplib_Tests;
