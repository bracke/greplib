pragma Ada_2022;

package body Greplib.Results is
   function Status (Outcome : Search_Outcome) return Overall_Status is (Outcome.Status);

   function Summary (Outcome : Search_Outcome) return Search_Summary is (Outcome.Summary);

   function Diagnostics (Outcome : Search_Outcome) return Greplib.Diagnostics.Diagnostic_List is
      (Outcome.Diagnostics);

   function Source_Summaries (Outcome : Search_Outcome) return Source_Summary_List is (Outcome.Sources);

   function Length (List : Source_Summary_List) return Natural is (Natural (List.Items.Length));

   function Element (List : Source_Summary_List; Index : Positive) return Source_Summary is
      (List.Items.Element (Index));

   function Source (Summary : Source_Summary) return Greplib.Sources.Source_Descriptor is (Summary.Source);

   function Records_Read (Summary : Source_Summary) return Wide_Count is (Summary.Records_Read);

   function Bytes_Read (Summary : Source_Summary) return Byte_Count is (Summary.Bytes_Read);

   function Selected_Record_Count (Summary : Source_Summary) return Wide_Count is
      (Summary.Selected_Record_Count);

   function Match_Count (Summary : Source_Summary) return Wide_Count is (Summary.Match_Count);

   function Match_Count_State (Summary : Source_Summary) return Count_Completeness is
      (Summary.Match_Count_State);

   function Context_Record_Count (Summary : Source_Summary) return Wide_Count is
      (Summary.Context_Record_Count);

   function Emitted_Result_Count (Summary : Source_Summary) return Wide_Count is
      (Summary.Emitted_Result_Count);

   function Had_Selected_Record (Summary : Source_Summary) return Boolean is
      (Summary.Had_Selected_Record);

   function Binary (Summary : Source_Summary) return Binary_Classification is (Summary.Binary);

   function Truncation (Summary : Source_Summary) return Source_Truncation is (Summary.Truncation);

   function Source_Changed_During_Search (Summary : Source_Summary) return Boolean is
      (Summary.Source_Changed_During_Search);

   function Diagnostic_Count (Summary : Source_Summary) return Wide_Count is
      (Summary.Diagnostic_Count);

   function Reason (Summary : Source_Summary) return Completion_Reason is (Summary.Reason);

   function Sources_Considered (Summary : Search_Summary) return Wide_Count is (Summary.Sources_Considered);

   function Sources_Opened (Summary : Search_Summary) return Wide_Count is (Summary.Sources_Opened);

   function Sources_Completed (Summary : Search_Summary) return Wide_Count is (Summary.Sources_Completed);

   function Sources_With_Results (Summary : Search_Summary) return Wide_Count is (Summary.Sources_With_Results);

   function Sources_Changed_During_Search (Summary : Search_Summary) return Wide_Count is
      (Summary.Sources_Changed_During_Search);

   function Roots_Considered (Summary : Search_Summary) return Wide_Count is (Summary.Roots_Considered);

   function Directories_Visited (Summary : Search_Summary) return Wide_Count is (Summary.Directories_Visited);

   function Directories_Skipped (Summary : Search_Summary) return Wide_Count is (Summary.Directories_Skipped);

   function Entries_Examined (Summary : Search_Summary) return Wide_Count is (Summary.Entries_Examined);

   function Files_Accepted (Summary : Search_Summary) return Wide_Count is (Summary.Files_Accepted);

   function Files_Filtered (Summary : Search_Summary) return Wide_Count is (Summary.Files_Filtered);

   function Links_Encountered (Summary : Search_Summary) return Wide_Count is (Summary.Links_Encountered);

   function Links_Followed (Summary : Search_Summary) return Wide_Count is (Summary.Links_Followed);

   function Cycles_Detected (Summary : Search_Summary) return Wide_Count is (Summary.Cycles_Detected);

   function Filesystem_Boundaries_Skipped (Summary : Search_Summary) return Wide_Count is
      (Summary.Filesystem_Boundaries_Skipped);

   function Records_Read (Summary : Search_Summary) return Wide_Count is (Summary.Records_Read);

   function Bytes_Read (Summary : Search_Summary) return Byte_Count is (Summary.Bytes_Read);

   function Selected_Record_Count (Summary : Search_Summary) return Wide_Count is
      (Summary.Selected_Record_Count);

   function Match_Count (Summary : Search_Summary) return Wide_Count is (Summary.Match_Count);

   function Match_Count_State (Summary : Search_Summary) return Count_Completeness is
      (Summary.Match_Count_State);

   function Diagnostic_Count (Summary : Search_Summary) return Wide_Count is (Summary.Diagnostic_Count);

   function Diagnostics_Truncated (Summary : Search_Summary) return Boolean is
      (Summary.Diagnostics_Truncated);

   function Cancellation_Observed (Summary : Search_Summary) return Boolean is
      (Summary.Cancellation_Observed);

   function Reason (Summary : Search_Summary) return Completion_Reason is (Summary.Reason);
end Greplib.Results;
