pragma Ada_2022;

with Greplib.Diagnostics;

package Greplib.Options is
   --  @summary Search-time options and validation for record parsing, result modes, binary policy, and limits.
   --  Cancellation state is intentionally separate from reusable Search_Options values.
   --  Controls whether selected-record events retain no spans, one accepted span, or all accepted spans.
   type Span_Requirement is (No_Spans, First_Span, All_Spans);

   --  Determines the execution plan and whether records, counts, source names, or quiet success are produced.
   type Result_Mode is
     (Emit_Selected_Records, Count_Selected_Records, Count_Matches, Source_Names_With_Matches,
      Source_Names_Without_Matches, Quiet);

   --  Single-byte record separator mode. Custom_Separator supplies the byte for Custom.
   type Record_Separator_Kind is (LF, NUL, Custom);

   --  Logical-content CR handling. Strip_Before_Line_Feed is invalid for NUL-separated records.
   type Carriage_Return_Policy is (Preserve, Strip_Before_Line_Feed);

   --  Policy applied when one logical record exceeds Maximum_Record_Size.
   type Oversized_Record_Policy is (Fail_Source, Skip_Record, Report_And_Skip);

   --  Binary classification strategy. Probe bytes are replayed through the normal parser.
   type Binary_Detection_Mode is (No_Binary_Detection, Detect_Null_Byte, Detect_Using_Prefix);

   --  Policy applied after a source is classified as binary.
   type Binary_Policy is (Search_As_Text, Skip_Source, Report_Match_Without_Record, Fail_Source);

   --  Event delivery order for directory searches with Worker_Count greater than one.
   type Result_Order is (Deterministic, Completion_Order);

   --  Context window sizes in physical records. Context is valid only for Emit_Selected_Records.
   type Context_Options is record
      --  Number of preceding non-selected records eligible for context delivery.
      Before : Wide_Count := 0;
      --  Number of following non-selected records eligible for context delivery.
      After : Wide_Count := 0;
   end record;

   --  Reusable search-time options. Validation runs before any public search operation reads input.
   type Search_Options is record
      --  Select records that do not have an accepted candidate after boundary filtering.
      Invert_Match : Boolean := False;
      --  Requested retained span detail for selected-record events.
      Spans : Span_Requirement := No_Spans;
      --  Result plan to execute. Count_Matches is invalid with Invert_Match.
      Mode : Result_Mode := Emit_Selected_Records;
      --  Before and after context settings. Nonzero values are invalid for count, quiet, and name modes.
      Context : Context_Options;
      --  Record separator selection.
      Separator_Kind : Record_Separator_Kind := LF;
      --  Separator byte used when Separator_Kind is Custom.
      Custom_Separator : Character := ASCII.LF;
      --  Logical CR policy applied before matching and span reporting.
      CR_Policy : Carriage_Return_Policy := Preserve;
      --  Maximum stream read buffer size in bytes. Search operations validate this before reading input.
      Read_Block_Size : Byte_Count := Default_Read_Block_Size;
      --  Maximum logical record bytes retained for matching before oversized-record policy is applied.
      Maximum_Record_Size : Byte_Count := Default_Maximum_Record_Size;
      --  Maximum retained before-context content bytes.
      Maximum_Context_Buffer_Bytes : Byte_Count := Default_Maximum_Context_Buffer_Bytes;
      --  Oversized-record behavior. Skipped records are never matched as partial fragments.
      On_Oversized_Record : Oversized_Record_Policy := Report_And_Skip;
      --  Maximum accepted spans emitted for a single record when spans are requested.
      Maximum_Match_Spans_Per_Record : Wide_Count := Default_Maximum_Match_Spans_Per_Record;
      --  Maximum diagnostics retained in an outcome. Total diagnostic counts continue after truncation.
      Maximum_Retained_Diagnostics : Wide_Count := Default_Maximum_Retained_Diagnostics;
      --  Zero means unlimited selected records; otherwise trailing context may continue after the limit.
      Maximum_Selected_Records : Wide_Count := 0;
      --  Binary detection mode. NUL-separated records do not classify separator NUL bytes as binary.
      Binary_Detection : Binary_Detection_Mode := Detect_Null_Byte;
      --  Binary policy. Report_Match_Without_Record is incompatible with context.
      On_Binary : Binary_Policy := Search_As_Text;
      --  Requested worker count for directory/file search. One uses the sequential reference path.
      Worker_Count : Wide_Count := 1;
      --  Delivery order for concurrent directory search.
      Order : Result_Order := Deterministic;
   end record;

   --  Return the single-byte separator selected by Options.
   function Separator (Options : Search_Options) return Character;

   --  Validation reports all independently detectable option errors and consumes no input.
   function Validate (Options : Search_Options) return Greplib.Diagnostics.Diagnostic_List;
end Greplib.Options;
