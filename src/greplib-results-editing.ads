pragma Ada_2022;

with Greplib.Result_Authority;
with Greplib.Sources;

package Greplib.Results.Editing is
   --  @summary Internal mutation layer for private result values.
   --  Public callers receive immutable private outcomes and summaries through Greplib.Results accessors.

   type Wide_Field is
     (Sources_Considered_Field, Sources_Opened_Field, Sources_Completed_Field,
      Sources_With_Results_Field, Sources_Changed_During_Search_Field, Roots_Considered_Field,
      Directories_Visited_Field, Directories_Skipped_Field, Entries_Examined_Field,
      Files_Accepted_Field, Files_Filtered_Field, Links_Encountered_Field, Links_Followed_Field,
      Cycles_Detected_Field, Filesystem_Boundaries_Skipped_Field, Records_Read_Field,
      Selected_Record_Count_Field, Match_Count_Field, Diagnostic_Count_Field);

   function Status (Outcome : Search_Outcome) return Overall_Status;
   function Reason (Outcome : Search_Outcome) return Completion_Reason;
   function Match_Count_State (Outcome : Search_Outcome) return Count_Completeness;
   function Cancellation_Observed (Outcome : Search_Outcome) return Boolean;
   function Diagnostics_Truncated (Outcome : Search_Outcome) return Boolean;
   function Wide_Value (Outcome : Search_Outcome; Field : Wide_Field) return Wide_Count;
   function Bytes_Read (Outcome : Search_Outcome) return Byte_Count;
   function Retained_Diagnostic_Count (Outcome : Search_Outcome) return Wide_Count;
   function Retained_Diagnostic (Outcome : Search_Outcome; Index : Positive) return Greplib.Diagnostics.Diagnostic;

   procedure Reset (Authority : Greplib.Result_Authority.Token; Outcome : out Search_Outcome);
   procedure Set_Status
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Overall_Status);
   procedure Set_Reason
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Completion_Reason);
   procedure Set_Match_Count_State
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Count_Completeness);
   procedure Set_Cancellation_Observed
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Boolean);
   procedure Set_Diagnostics_Truncated
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Boolean);
   procedure Set_Wide
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Field : Wide_Field;
      Value : Wide_Count);
   procedure Add_Wide
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Field : Wide_Field;
      Value : Wide_Count := 1);
   procedure Set_Bytes_Read
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Byte_Count);
   procedure Add_Bytes_Read
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Byte_Count);
   procedure Append_Diagnostic
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Item : Greplib.Diagnostics.Diagnostic);
   procedure Append_Source_Summary
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Source : Greplib.Sources.Source_Descriptor;
      Context_Record_Count : Wide_Count := 0;
      Emitted_Result_Count : Wide_Count := 0;
      Binary : Binary_Classification := Not_Classified;
      Match_Spans_Truncated : Boolean := False;
      Context_Truncated : Boolean := False);
   procedure Mark_Last_Source_Changed
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome);
   procedure Set_Last_Source_Reason
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Value : Completion_Reason);
   procedure Add_Summary
     (Authority : Greplib.Result_Authority.Token;
      Outcome : in out Search_Outcome;
      Source : Search_Outcome);
end Greplib.Results.Editing;
