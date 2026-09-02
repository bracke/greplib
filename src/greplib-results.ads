pragma Ada_2022;

with Ada.Containers.Indefinite_Vectors;
with Greplib.Diagnostics;
with Greplib.Sources;

package Greplib.Results is
   --  @summary Structured operation outcomes, summaries, completion reasons, and count completeness.
   --  Partial facts are retained even when later diagnostics, cancellation, or limits affect completion status.
   --  Completeness attached to match counts. Lower_Bound means the count is known not to be overstated.
   type Count_Completeness is (Exact, Lower_Bound, Unavailable);

   --  Overall operation status after applying diagnostics, cancellation, and fatal failure precedence.
   type Overall_Status is (Completed, Completed_With_Recoverable_Errors, Cancelled, Failed);

   --  Primary completion reason. Confirmed per-source facts remain valid independently of this value.
   type Completion_Reason is
     (Input_Exhausted, Match_Limit_Reached, Source_Limit_Reached, Quiet_Match_Found,
      Callback_Stopped_Source, Callback_Stopped_Search, Cancellation_Requested,
      Result_Limit_Reached, Source_Error, Fatal_Error);

   --  Binary classification observed for a source.
   type Binary_Classification is (Not_Classified, Text_Like, Binary);

   --  Source-level truncation facts.
   type Source_Truncation is record
      --  True when retained diagnostics for this source reached the configured retention limit.
      Diagnostics : Boolean := False;
      --  True when requested match span enumeration was truncated or intentionally incomplete.
      Match_Spans : Boolean := False;
      --  True when context retention/delivery was truncated by configured context buffer limits.
      Context : Boolean := False;
   end record;

   --  Aggregate immutable summary returned in every outcome. Use accessors to inspect fields.
   type Search_Summary is private;

   --  Immutable summary for one assigned source. Record and byte counts use original source bytes.
   type Source_Summary is private;

   --  Owned source-summary list in source-sequence order where the operation can determine that order.
   type Source_Summary_List is private;

   --  Final structured outcome. Diagnostics retention is bounded by Search_Options.
   type Search_Outcome is private;

   --  Return the overall operation status.
   function Status (Outcome : Search_Outcome) return Overall_Status;

   --  Return the aggregate summary snapshot.
   function Summary (Outcome : Search_Outcome) return Search_Summary;

   --  Return retained diagnostics.
   function Diagnostics (Outcome : Search_Outcome) return Greplib.Diagnostics.Diagnostic_List;

   --  Return retained per-source summaries.
   function Source_Summaries (Outcome : Search_Outcome) return Source_Summary_List;

   --  Return the number of retained source summaries.
   function Length (List : Source_Summary_List) return Natural;

   --  Return one source summary by one-based index.
   function Element (List : Source_Summary_List; Index : Positive) return Source_Summary;

   --  Return stable identity for a source summary.
   function Source (Summary : Source_Summary) return Greplib.Sources.Source_Descriptor;

   --  Return physical records read for this source.
   function Records_Read (Summary : Source_Summary) return Wide_Count;

   --  Return original bytes read for this source.
   function Bytes_Read (Summary : Source_Summary) return Byte_Count;

   --  Return selected record count for this source.
   function Selected_Record_Count (Summary : Source_Summary) return Wide_Count;

   --  Return accepted match count for this source.
   function Match_Count (Summary : Source_Summary) return Wide_Count;

   --  Return match-count completeness for this source.
   function Match_Count_State (Summary : Source_Summary) return Count_Completeness;

   --  Return context record count retained or delivered for this source where known.
   function Context_Record_Count (Summary : Source_Summary) return Wide_Count;

   --  Return emitted selected, context, binary, count, or source-name result count where known.
   function Emitted_Result_Count (Summary : Source_Summary) return Wide_Count;

   --  True when this source had at least one selected record or source-level result.
   function Had_Selected_Record (Summary : Source_Summary) return Boolean;

   --  Return binary classification observed for this source.
   function Binary (Summary : Source_Summary) return Binary_Classification;

   --  Return source-level truncation facts.
   function Truncation (Summary : Source_Summary) return Source_Truncation;

   --  True when the source was reliably detected as changed during search.
   function Source_Changed_During_Search (Summary : Source_Summary) return Boolean;

   --  Return diagnostic count attributed to this source.
   function Diagnostic_Count (Summary : Source_Summary) return Wide_Count;

   --  Return this source's completion reason.
   function Reason (Summary : Source_Summary) return Completion_Reason;

   --  Return the number of sources assigned a sequence.
   function Sources_Considered (Summary : Search_Summary) return Wide_Count;

   --  Return the number of sources opened or otherwise made available for reading.
   function Sources_Opened (Summary : Search_Summary) return Wide_Count;

   --  Return the number of sources that reached a terminal summary state.
   function Sources_Completed (Summary : Search_Summary) return Wide_Count;

   --  Return the number of sources that produced results.
   function Sources_With_Results (Summary : Search_Summary) return Wide_Count;

   --  Return the number of sources reliably detected as changed during search.
   function Sources_Changed_During_Search (Summary : Search_Summary) return Wide_Count;

   --  Return the number of path roots considered by Search_Paths.
   function Roots_Considered (Summary : Search_Summary) return Wide_Count;

   --  Return the number of directories entered during traversal.
   function Directories_Visited (Summary : Search_Summary) return Wide_Count;

   --  Return the number of directories skipped by policy, filters, limits, or diagnostics.
   function Directories_Skipped (Summary : Search_Summary) return Wide_Count;

   --  Return the number of directory entries examined.
   function Entries_Examined (Summary : Search_Summary) return Wide_Count;

   --  Return the number of file sources accepted for search.
   function Files_Accepted (Summary : Search_Summary) return Wide_Count;

   --  Return the number of file entries rejected by filters or file-type policy.
   function Files_Filtered (Summary : Search_Summary) return Wide_Count;

   --  Return the number of symbolic links encountered.
   function Links_Encountered (Summary : Search_Summary) return Wide_Count;

   --  Return the number of symbolic links followed.
   function Links_Followed (Summary : Search_Summary) return Wide_Count;

   --  Return the number of traversal cycles detected and skipped.
   function Cycles_Detected (Summary : Search_Summary) return Wide_Count;

   --  Return the number of recursive directory descents skipped by filesystem-boundary policy.
   function Filesystem_Boundaries_Skipped (Summary : Search_Summary) return Wide_Count;

   --  Return the number of physical records read.
   function Records_Read (Summary : Search_Summary) return Wide_Count;

   --  Return original input bytes read.
   function Bytes_Read (Summary : Search_Summary) return Byte_Count;

   --  Return selected record count after inversion and boundary filtering.
   function Selected_Record_Count (Summary : Search_Summary) return Wide_Count;

   --  Return accepted match count.
   function Match_Count (Summary : Search_Summary) return Wide_Count;

   --  Return match-count completeness.
   function Match_Count_State (Summary : Search_Summary) return Count_Completeness;

   --  Return total diagnostics observed.
   function Diagnostic_Count (Summary : Search_Summary) return Wide_Count;

   --  True when retained diagnostics reached the configured limit.
   function Diagnostics_Truncated (Summary : Search_Summary) return Boolean;

   --  True when cancellation was observed by the operation.
   function Cancellation_Observed (Summary : Search_Summary) return Boolean;

   --  Return the primary completion reason.
   function Reason (Summary : Search_Summary) return Completion_Reason;
private
   type Source_Summary is record
      Source : Greplib.Sources.Source_Descriptor;
      Records_Read : Wide_Count := 0;
      Bytes_Read : Byte_Count := 0;
      Selected_Record_Count : Wide_Count := 0;
      Match_Count : Wide_Count := 0;
      Match_Count_State : Count_Completeness := Exact;
      Context_Record_Count : Wide_Count := 0;
      Emitted_Result_Count : Wide_Count := 0;
      Had_Selected_Record : Boolean := False;
      Binary : Binary_Classification := Not_Classified;
      Truncation : Source_Truncation := (others => False);
      Source_Changed_During_Search : Boolean := False;
      Diagnostic_Count : Wide_Count := 0;
      Reason : Completion_Reason := Input_Exhausted;
   end record;

   package Source_Summary_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Source_Summary);

   type Source_Summary_List is record
      Items : Source_Summary_Vectors.Vector;
   end record;

   type Search_Summary is record
      Sources_Considered : Wide_Count := 0;
      Sources_Opened : Wide_Count := 0;
      Sources_Completed : Wide_Count := 0;
      Sources_With_Results : Wide_Count := 0;
      Sources_Changed_During_Search : Wide_Count := 0;
      Roots_Considered : Wide_Count := 0;
      Directories_Visited : Wide_Count := 0;
      Directories_Skipped : Wide_Count := 0;
      Entries_Examined : Wide_Count := 0;
      Files_Accepted : Wide_Count := 0;
      Files_Filtered : Wide_Count := 0;
      Links_Encountered : Wide_Count := 0;
      Links_Followed : Wide_Count := 0;
      Cycles_Detected : Wide_Count := 0;
      Filesystem_Boundaries_Skipped : Wide_Count := 0;
      Records_Read : Wide_Count := 0;
      Bytes_Read : Byte_Count := 0;
      Selected_Record_Count : Wide_Count := 0;
      Match_Count : Wide_Count := 0;
      Match_Count_State : Count_Completeness := Exact;
      Diagnostic_Count : Wide_Count := 0;
      Diagnostics_Truncated : Boolean := False;
      Cancellation_Observed : Boolean := False;
      Reason : Completion_Reason := Input_Exhausted;
   end record;

   type Search_Outcome is record
      Status : Overall_Status := Completed;
      Summary : Search_Summary;
      Diagnostics : Greplib.Diagnostics.Diagnostic_List;
      Sources : Source_Summary_List;
   end record;
end Greplib.Results;
