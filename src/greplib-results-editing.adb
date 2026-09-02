pragma Ada_2022;

package body Greplib.Results.Editing is
   function Status (Outcome : Search_Outcome) return Overall_Status is (Outcome.Status);
   function Reason (Outcome : Search_Outcome) return Completion_Reason is (Outcome.Summary.Reason);
   function Match_Count_State (Outcome : Search_Outcome) return Count_Completeness is
      (Outcome.Summary.Match_Count_State);
   function Cancellation_Observed (Outcome : Search_Outcome) return Boolean is
      (Outcome.Summary.Cancellation_Observed);
   function Diagnostics_Truncated (Outcome : Search_Outcome) return Boolean is
      (Outcome.Summary.Diagnostics_Truncated);
   function Bytes_Read (Outcome : Search_Outcome) return Byte_Count is (Outcome.Summary.Bytes_Read);
   function Retained_Diagnostic_Count (Outcome : Search_Outcome) return Wide_Count is
      (Wide_Count (Outcome.Diagnostics.Length));
   function Retained_Diagnostic (Outcome : Search_Outcome; Index : Positive) return Greplib.Diagnostics.Diagnostic is
      (Outcome.Diagnostics.Element (Index));

   procedure Reset (Authority : Greplib.Result_Authority.Token; Outcome : out Search_Outcome) is
      pragma Unreferenced (Authority);
   begin
      Outcome := (Status => Completed, Summary => <>, Diagnostics => <>, Sources => <>);
   end Reset;

   function Wide_Value (Outcome : Search_Outcome; Field : Wide_Field) return Wide_Count is
   begin
      case Field is
         when Sources_Considered_Field => return Outcome.Summary.Sources_Considered;
         when Sources_Opened_Field => return Outcome.Summary.Sources_Opened;
         when Sources_Completed_Field => return Outcome.Summary.Sources_Completed;
         when Sources_With_Results_Field => return Outcome.Summary.Sources_With_Results;
         when Sources_Changed_During_Search_Field => return Outcome.Summary.Sources_Changed_During_Search;
         when Roots_Considered_Field => return Outcome.Summary.Roots_Considered;
         when Directories_Visited_Field => return Outcome.Summary.Directories_Visited;
         when Directories_Skipped_Field => return Outcome.Summary.Directories_Skipped;
         when Entries_Examined_Field => return Outcome.Summary.Entries_Examined;
         when Files_Accepted_Field => return Outcome.Summary.Files_Accepted;
         when Files_Filtered_Field => return Outcome.Summary.Files_Filtered;
         when Links_Encountered_Field => return Outcome.Summary.Links_Encountered;
         when Links_Followed_Field => return Outcome.Summary.Links_Followed;
         when Cycles_Detected_Field => return Outcome.Summary.Cycles_Detected;
         when Filesystem_Boundaries_Skipped_Field => return Outcome.Summary.Filesystem_Boundaries_Skipped;
         when Records_Read_Field => return Outcome.Summary.Records_Read;
         when Selected_Record_Count_Field => return Outcome.Summary.Selected_Record_Count;
         when Match_Count_Field => return Outcome.Summary.Match_Count;
         when Diagnostic_Count_Field => return Outcome.Summary.Diagnostic_Count;
      end case;
   end Wide_Value;

   procedure Set_Status
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Overall_Status) is
      pragma Unreferenced (Authority);
   begin
      Outcome.Status := Value;
   end Set_Status;

   procedure Set_Reason
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Completion_Reason) is
      pragma Unreferenced (Authority);
   begin
      Outcome.Summary.Reason := Value;
   end Set_Reason;

   procedure Set_Match_Count_State
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Count_Completeness) is
      pragma Unreferenced (Authority);
   begin
      Outcome.Summary.Match_Count_State := Value;
   end Set_Match_Count_State;

   procedure Set_Cancellation_Observed
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Boolean) is
      pragma Unreferenced (Authority);
   begin
      Outcome.Summary.Cancellation_Observed := Value;
   end Set_Cancellation_Observed;

   procedure Set_Diagnostics_Truncated
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Boolean) is
      pragma Unreferenced (Authority);
   begin
      Outcome.Summary.Diagnostics_Truncated := Value;
   end Set_Diagnostics_Truncated;

   procedure Set_Wide
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Field : Wide_Field;
      Value : Wide_Count) is
      pragma Unreferenced (Authority);
   begin
      case Field is
         when Sources_Considered_Field => Outcome.Summary.Sources_Considered := Value;
         when Sources_Opened_Field => Outcome.Summary.Sources_Opened := Value;
         when Sources_Completed_Field => Outcome.Summary.Sources_Completed := Value;
         when Sources_With_Results_Field => Outcome.Summary.Sources_With_Results := Value;
         when Sources_Changed_During_Search_Field => Outcome.Summary.Sources_Changed_During_Search := Value;
         when Roots_Considered_Field => Outcome.Summary.Roots_Considered := Value;
         when Directories_Visited_Field => Outcome.Summary.Directories_Visited := Value;
         when Directories_Skipped_Field => Outcome.Summary.Directories_Skipped := Value;
         when Entries_Examined_Field => Outcome.Summary.Entries_Examined := Value;
         when Files_Accepted_Field => Outcome.Summary.Files_Accepted := Value;
         when Files_Filtered_Field => Outcome.Summary.Files_Filtered := Value;
         when Links_Encountered_Field => Outcome.Summary.Links_Encountered := Value;
         when Links_Followed_Field => Outcome.Summary.Links_Followed := Value;
         when Cycles_Detected_Field => Outcome.Summary.Cycles_Detected := Value;
         when Filesystem_Boundaries_Skipped_Field => Outcome.Summary.Filesystem_Boundaries_Skipped := Value;
         when Records_Read_Field => Outcome.Summary.Records_Read := Value;
         when Selected_Record_Count_Field => Outcome.Summary.Selected_Record_Count := Value;
         when Match_Count_Field => Outcome.Summary.Match_Count := Value;
         when Diagnostic_Count_Field => Outcome.Summary.Diagnostic_Count := Value;
      end case;
   end Set_Wide;

   procedure Add_Wide
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Field : Wide_Field;
      Value : Wide_Count := 1) is
   begin
      Set_Wide (Authority, Outcome, Field, Wide_Value (Outcome, Field) + Value);
   end Add_Wide;

   procedure Set_Bytes_Read
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Byte_Count) is
      pragma Unreferenced (Authority);
   begin
      Outcome.Summary.Bytes_Read := Value;
   end Set_Bytes_Read;

   procedure Add_Bytes_Read
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Byte_Count) is
      pragma Unreferenced (Authority);
   begin
      Outcome.Summary.Bytes_Read := Outcome.Summary.Bytes_Read + Value;
   end Add_Bytes_Read;

   procedure Append_Diagnostic
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Item : Greplib.Diagnostics.Diagnostic) is
      pragma Unreferenced (Authority);
   begin
      Outcome.Diagnostics.Append (Item);
   end Append_Diagnostic;

   procedure Append_Source_Summary
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Source : Greplib.Sources.Source_Descriptor;
      Context_Record_Count : Wide_Count := 0;
      Emitted_Result_Count : Wide_Count := 0;
      Binary : Binary_Classification := Not_Classified;
      Match_Spans_Truncated : Boolean := False;
      Context_Truncated : Boolean := False) is
      pragma Unreferenced (Authority);
   begin
      Outcome.Sources.Items.Append
        (Source_Summary'
           (Source => Source,
            Records_Read => Outcome.Summary.Records_Read,
            Bytes_Read => Outcome.Summary.Bytes_Read,
            Selected_Record_Count => Outcome.Summary.Selected_Record_Count,
            Match_Count => Outcome.Summary.Match_Count,
            Match_Count_State => Outcome.Summary.Match_Count_State,
            Context_Record_Count => Context_Record_Count,
            Emitted_Result_Count => Emitted_Result_Count,
            Had_Selected_Record => Outcome.Summary.Sources_With_Results > 0,
            Binary => Binary,
            Truncation =>
              (Diagnostics => Outcome.Summary.Diagnostics_Truncated,
               Match_Spans => Match_Spans_Truncated,
               Context => Context_Truncated),
            Source_Changed_During_Search => Outcome.Summary.Sources_Changed_During_Search > 0,
            Diagnostic_Count => Outcome.Summary.Diagnostic_Count,
            Reason => Outcome.Summary.Reason));
   end Append_Source_Summary;

   procedure Mark_Last_Source_Changed
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome) is
      pragma Unreferenced (Authority);
      Last : Source_Summary;
   begin
      Outcome.Summary.Sources_Changed_During_Search := 1;
      if not Outcome.Sources.Items.Is_Empty then
         Last := Outcome.Sources.Items.Last_Element;
         Last.Source_Changed_During_Search := True;
         Outcome.Sources.Items.Replace_Element (Outcome.Sources.Items.Last_Index, Last);
      end if;
   end Mark_Last_Source_Changed;

   procedure Set_Last_Source_Reason
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Completion_Reason) is
      pragma Unreferenced (Authority);
      Last : Source_Summary;
   begin
      if not Outcome.Sources.Items.Is_Empty then
         Last := Outcome.Sources.Items.Last_Element;
         Last.Reason := Value;
         Outcome.Sources.Items.Replace_Element (Outcome.Sources.Items.Last_Index, Last);
      end if;
   end Set_Last_Source_Reason;

   procedure Add_Summary
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Source : Search_Outcome) is
      pragma Unreferenced (Authority);
   begin
      Outcome.Summary.Sources_Considered :=
        Outcome.Summary.Sources_Considered + Source.Summary.Sources_Considered;
      Outcome.Summary.Sources_Opened := Outcome.Summary.Sources_Opened + Source.Summary.Sources_Opened;
      Outcome.Summary.Sources_Completed :=
        Outcome.Summary.Sources_Completed + Source.Summary.Sources_Completed;
      Outcome.Summary.Sources_With_Results :=
        Outcome.Summary.Sources_With_Results + Source.Summary.Sources_With_Results;
      Outcome.Summary.Sources_Changed_During_Search :=
        Outcome.Summary.Sources_Changed_During_Search + Source.Summary.Sources_Changed_During_Search;
      Outcome.Summary.Roots_Considered := Outcome.Summary.Roots_Considered + Source.Summary.Roots_Considered;
      Outcome.Summary.Directories_Visited :=
        Outcome.Summary.Directories_Visited + Source.Summary.Directories_Visited;
      Outcome.Summary.Directories_Skipped :=
        Outcome.Summary.Directories_Skipped + Source.Summary.Directories_Skipped;
      Outcome.Summary.Entries_Examined := Outcome.Summary.Entries_Examined + Source.Summary.Entries_Examined;
      Outcome.Summary.Files_Accepted := Outcome.Summary.Files_Accepted + Source.Summary.Files_Accepted;
      Outcome.Summary.Files_Filtered := Outcome.Summary.Files_Filtered + Source.Summary.Files_Filtered;
      Outcome.Summary.Links_Encountered := Outcome.Summary.Links_Encountered + Source.Summary.Links_Encountered;
      Outcome.Summary.Links_Followed := Outcome.Summary.Links_Followed + Source.Summary.Links_Followed;
      Outcome.Summary.Cycles_Detected := Outcome.Summary.Cycles_Detected + Source.Summary.Cycles_Detected;
      Outcome.Summary.Filesystem_Boundaries_Skipped :=
        Outcome.Summary.Filesystem_Boundaries_Skipped + Source.Summary.Filesystem_Boundaries_Skipped;
      Outcome.Summary.Records_Read := Outcome.Summary.Records_Read + Source.Summary.Records_Read;
      Outcome.Summary.Bytes_Read := Outcome.Summary.Bytes_Read + Source.Summary.Bytes_Read;
      Outcome.Summary.Selected_Record_Count :=
        Outcome.Summary.Selected_Record_Count + Source.Summary.Selected_Record_Count;
      Outcome.Summary.Match_Count := Outcome.Summary.Match_Count + Source.Summary.Match_Count;
      Outcome.Summary.Diagnostic_Count :=
        Outcome.Summary.Diagnostic_Count + Source.Summary.Diagnostic_Count;

      for Item of Source.Sources.Items loop
         Outcome.Sources.Items.Append (Item);
      end loop;
   end Add_Summary;
end Greplib.Results.Editing;
