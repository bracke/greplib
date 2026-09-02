pragma Ada_2022;

with Ada.Containers.Indefinite_Vectors;
with Ada.Strings.Unbounded;
with Greplib;

package Greplib.Diagnostics is
   --  @summary Structured diagnostics with stable identifier strings and bounded retention.
   --  Diagnostic_Code is private; callers should compare stable identifiers rather than representation fields.
   --  High-level category for a diagnostic code. Domains are stable API groupings.
   type Diagnostic_Domain is
     (Configuration, Pattern_Compilation, Path_Filter_Compilation, Input_Decoding, Stream_IO,
      Filesystem, Traversal, Resource_Limit, Cancellation, Concurrency, Internal);

   --  Severity of a diagnostic. Recoverable errors may still allow partial valid results.
   type Severity is (Information, Warning, Recoverable_Error, Fatal_Error);

   --  Stable diagnostic code value. The private representation must not be parsed by callers.
   type Diagnostic_Code is private;

   --  Configuration diagnostic emitted when a compiled pattern set has no usable patterns.
   Configuration_No_Patterns : constant Diagnostic_Code;
   --  Configuration diagnostic emitted when a directory search receives no roots.
   Configuration_Empty_Root_List : constant Diagnostic_Code;
   --  Configuration diagnostic emitted for invalid option combinations.
   Configuration_Invalid_Option_Combination : constant Diagnostic_Code;
   --  Pattern diagnostic emitted when regexp compilation fails.
   Pattern_Invalid_Regular_Expression : constant Diagnostic_Code;
   --  Pattern diagnostic emitted when regexp cannot provide requested case-insensitive matching.
   Pattern_Case_Insensitive_Unsupported : constant Diagnostic_Code;
   --  Path-filter diagnostic emitted when glob or regex filter compilation fails.
   Path_Filter_Invalid_Pattern : constant Diagnostic_Code;
   --  Input diagnostic emitted when binary classification affects source handling.
   Input_Binary_Detected : constant Diagnostic_Code;
   --  Input diagnostic emitted when a record exceeds configured record-size limits.
   Input_Record_Size_Limit_Exceeded : constant Diagnostic_Code;
   --  Stream diagnostic emitted for byte-preserving stream read failures.
   Stream_Read_Failed : constant Diagnostic_Code;
   --  Filesystem diagnostic emitted when a file cannot be opened or classified for search.
   Filesystem_Open_Failed : constant Diagnostic_Code;
   --  Traversal diagnostic emitted when a followed directory link would create a cycle.
   Traversal_Cycle_Detected : constant Diagnostic_Code;
   --  Traversal diagnostic emitted when recursive depth exceeds the configured limit.
   Traversal_Maximum_Depth_Exceeded : constant Diagnostic_Code;
   --  Traversal diagnostic emitted when filesystem-boundary policy skips a directory.
   Traversal_Filesystem_Boundary_Skipped : constant Diagnostic_Code;
   --  Resource diagnostic emitted when a path spelling exceeds the configured byte limit.
   Resource_Path_Limit_Exceeded : constant Diagnostic_Code;
   --  Resource diagnostic emitted when deterministic directory entry collection exceeds its limit.
   Resource_Directory_Entry_Limit_Exceeded : constant Diagnostic_Code;
   --  Resource diagnostic emitted when retained context bytes exceed the configured limit.
   Resource_Context_Buffer_Exceeded : constant Diagnostic_Code;
   --  Resource diagnostic emitted when match-span enumeration exceeds the configured limit.
   Resource_Match_Span_Limit_Exceeded : constant Diagnostic_Code;
   --  Internal diagnostic emitted when checked offset or count arithmetic overflows.
   Internal_Numeric_Overflow : constant Diagnostic_Code;
   --  Internal diagnostic emitted when a regexp or engine result violates greplib invariants.
   Internal_Invariant_Failure : constant Diagnostic_Code;

   --  Stable identifier such as "configuration.no_patterns". The identifier is not localized.
   function Identifier (Code : Diagnostic_Code) return String;

   --  Return the diagnostic domain associated with Code.
   function Domain (Code : Diagnostic_Code) return Diagnostic_Domain;

   --  Structured diagnostic event and retained-outcome item.
   --  The representation is private; use accessors for stable fields.
   type Diagnostic is private;

   --  Build a diagnostic with owned text and optional pattern and byte-offset fields.
   function Make
     (Code : Diagnostic_Code;
      Level : Severity;
      Message : String := "";
      Pattern : Pattern_Index := Pattern_Index'First;
      Offset : Byte_Offset := 0;
      Path : String := "";
      Filesystem_Operation : String := "";
      Has_Record : Boolean := False;
      Record_No : Record_Number := Record_Number'First;
      Has_Native_Error : Boolean := False;
      Native_Error : Integer := 0;
      Exception_Name : String := "";
      Exception_Message : String := "";
      Has_Numeric_Limit : Boolean := False;
      Numeric_Limit : Wide_Count := 0;
      Has_Observed_Size : Boolean := False;
      Observed_Size : Wide_Count := 0) return Diagnostic;

   --  Reconstruct the public code value for Item.
   function Code (Item : Diagnostic) return Diagnostic_Code;

   --  Return Item severity.
   function Level (Item : Diagnostic) return Severity;

   --  Return owned non-localized debug message text.
   function Message (Item : Diagnostic) return String;

   --  True when a source path is present.
   function Has_Path (Item : Diagnostic) return Boolean;

   --  Return the preserved source or filesystem path when present.
   function Path (Item : Diagnostic) return String;

   --  True when a filesystem operation name is present.
   function Has_Filesystem_Operation (Item : Diagnostic) return Boolean;

   --  Return a non-localized filesystem operation name such as "open" or "enumerate".
   function Filesystem_Operation (Item : Diagnostic) return String;

   --  True when a physical record number is present.
   function Has_Record_Number (Item : Diagnostic) return Boolean;

   --  Return the one-based physical record number when present.
   function Record_No (Item : Diagnostic) return Record_Number;

   --  True when a native error code is present.
   function Has_Native_Error (Item : Diagnostic) return Boolean;

   --  Return the native error code when present.
   function Native_Error (Item : Diagnostic) return Integer;

   --  True when exception identity text is present.
   function Has_Exception_Name (Item : Diagnostic) return Boolean;

   --  Return exception identity text when present.
   function Exception_Name (Item : Diagnostic) return String;

   --  True when exception message text is present.
   function Has_Exception_Message (Item : Diagnostic) return Boolean;

   --  Return exception message text when present.
   function Exception_Message (Item : Diagnostic) return String;

   --  True when a numeric limit is present.
   function Has_Numeric_Limit (Item : Diagnostic) return Boolean;

   --  Return a numeric limit associated with a resource diagnostic when present.
   function Numeric_Limit (Item : Diagnostic) return Wide_Count;

   --  True when an observed size or count is present.
   function Has_Observed_Size (Item : Diagnostic) return Boolean;

   --  Return observed size or count associated with a resource diagnostic when present.
   function Observed_Size (Item : Diagnostic) return Wide_Count;

   --  Return an implementation-oriented debug image. Applications must not parse this string.
   function Debug_Image (Item : Diagnostic) return String;

   --  Retained diagnostics. Total diagnostic counts may exceed this vector when truncation occurs.
   type Diagnostic_List is tagged private;

   --  Append Item to List.
   procedure Append (List : in out Diagnostic_List; Item : Diagnostic);

   --  Number of retained diagnostics in List.
   function Length (List : Diagnostic_List) return Ada.Containers.Count_Type;

   --  True when List contains no retained diagnostics.
   function Is_Empty (List : Diagnostic_List) return Boolean;

   --  Return the one-based retained diagnostic at Index.
   function Element (List : Diagnostic_List; Index : Positive) return Diagnostic;

   --  Remove every retained diagnostic from List.
   procedure Clear (List : in out Diagnostic_List);

private
   type Diagnostic_Code is record
      Id : Ada.Strings.Unbounded.Unbounded_String;
      Area : Diagnostic_Domain;
   end record;

   type Diagnostic is record
      Code_Id : Ada.Strings.Unbounded.Unbounded_String;
      Code_Area : Diagnostic_Domain;
      S : Severity;
      Text : Ada.Strings.Unbounded.Unbounded_String;
      Pattern : Pattern_Index := Pattern_Index'First;
      Offset : Byte_Offset := 0;
      Path_Text : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Text : Ada.Strings.Unbounded.Unbounded_String;
      Record_Set : Boolean := False;
      Record_Number_Value : Record_Number := Record_Number'First;
      Native_Error_Set : Boolean := False;
      Native_Error_Code : Integer := 0;
      Exception_Name_Text : Ada.Strings.Unbounded.Unbounded_String;
      Exception_Message_Text : Ada.Strings.Unbounded.Unbounded_String;
      Numeric_Limit_Set : Boolean := False;
      Numeric_Limit_Value : Wide_Count := 0;
      Observed_Size_Set : Boolean := False;
      Observed_Size_Value : Wide_Count := 0;
   end record;

   package Diagnostic_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Diagnostic);

   type Diagnostic_List is tagged record
      Items : Diagnostic_Vectors.Vector;
   end record;

   Configuration_No_Patterns : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("configuration.no_patterns"), Configuration);
   Configuration_Empty_Root_List : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("configuration.empty_root_list"), Configuration);
   Configuration_Invalid_Option_Combination : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("configuration.invalid_option_combination"), Configuration);
   Pattern_Invalid_Regular_Expression : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("pattern.invalid_regular_expression"), Pattern_Compilation);
   Pattern_Case_Insensitive_Unsupported : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("pattern.case_insensitive_unsupported"), Pattern_Compilation);
   Path_Filter_Invalid_Pattern : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("path_filter.invalid_pattern"), Path_Filter_Compilation);
   Input_Binary_Detected : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("input.binary_detected"), Input_Decoding);
   Input_Record_Size_Limit_Exceeded : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("input.record_size_limit_exceeded"), Input_Decoding);
   Stream_Read_Failed : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("stream.read_failed"), Stream_IO);
   Filesystem_Open_Failed : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("filesystem.open_failed"), Filesystem);
   Traversal_Cycle_Detected : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("traversal.cycle_detected"), Traversal);
   Traversal_Maximum_Depth_Exceeded : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("traversal.maximum_depth_exceeded"), Traversal);
   Traversal_Filesystem_Boundary_Skipped : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("traversal.filesystem_boundary_skipped"), Traversal);
   Resource_Path_Limit_Exceeded : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("resource.path_limit_exceeded"), Resource_Limit);
   Resource_Directory_Entry_Limit_Exceeded : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("resource.directory_entry_limit_exceeded"), Resource_Limit);
   Resource_Context_Buffer_Exceeded : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("resource.context_buffer_exceeded"), Resource_Limit);
   Resource_Match_Span_Limit_Exceeded : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("resource.match_span_limit_exceeded"), Resource_Limit);
   Internal_Numeric_Overflow : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("internal.numeric_overflow"), Internal);
   Internal_Invariant_Failure : constant Diagnostic_Code :=
     (Ada.Strings.Unbounded.To_Unbounded_String ("internal.invariant_failure"), Internal);
end Greplib.Diagnostics;
