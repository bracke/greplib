pragma Ada_2022;

with Ada.Containers.Indefinite_Vectors;
with Ada.Streams;
with Greplib.Cancellation;
with Greplib.Diagnostics;
with Greplib.Directories;
with Greplib.Events;
with Greplib.Options;
with Greplib.Path_Filters;
with Greplib.Paths;
with Greplib.Patterns;
with Greplib.Results;

package Greplib.Collected is
   --  @summary Bounded collected-result API implemented as an event sink.
   --  Collection limits must be finite and positive; truncation is reported structurally in Collected_Result.
   use type Greplib.Events.Search_Event;

   --  Policy applied when a finite collection limit is reached.
   type Collection_Limit_Policy is (Stop_And_Return_Partial, Continue_Without_Collecting);

   --  Finite limits for retained public events. Search_Options still govern parser and span limits.
   type Collection_Options is record
      --  Maximum selected or context record events retained.
      Maximum_Records : Wide_Count := Default_Maximum_Collected_Records;
      --  Maximum retained event content bytes.
      Maximum_Bytes : Byte_Count := Default_Maximum_Collected_Bytes;
      --  Maximum total retained events, including diagnostics, counts, names, and structural events.
      Maximum_Events : Wide_Count := Default_Maximum_Collected_Records;
      --  Whether the search stops at the limit or continues while discarding later events.
      On_Limit : Collection_Limit_Policy := Stop_And_Return_Partial;
   end record;

   --  Exact collection limits that prevented retaining every delivered event.
   type Collection_Truncation is record
      --  True when Maximum_Records prevented retaining a selected, context, or binary-match event.
      Records : Boolean := False;
      --  True when Maximum_Bytes prevented retaining an event according to collection memory accounting.
      Bytes : Boolean := False;
      --  True when Maximum_Events prevented retaining another event of any kind.
      Events : Boolean := False;
   end record;

   --  Validate collection limits without starting a search, consuming input, delivering callbacks, or observing
   --  cancellation. Zero limits are rejected structurally because collected output must always be bounded by finite,
   --  positive record, byte, and event limits.
   function Validate (Collection : Collection_Options) return Greplib.Diagnostics.Diagnostic_List;

   --  Validate collected in-memory search configuration without consuming input or delivering callbacks.
   function Validate
     (Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options) return Greplib.Diagnostics.Diagnostic_List;

   --  Validate collected stream or file search configuration without reading streams or opening files.
   function Validate_File
     (Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options) return Greplib.Diagnostics.Diagnostic_List;

   --  Validate collected directory search without opening files, enumerating directories, or invoking callbacks.
   function Validate_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Collection : Collection_Options) return Greplib.Diagnostics.Diagnostic_List;

   --  Validate collected filtered directory search, including diagnostics from an unusable compiled filter set.
   function Validate_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Collection : Collection_Options) return Greplib.Diagnostics.Diagnostic_List;

   --  Owned retained event vector.
   package Event_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Greplib.Events.Search_Event);

   --  Result returned by collected APIs. Events are produced by the normal streaming engine.
   type Collected_Result is record
      --  Retained events in delivery order.
      Events : Event_Vectors.Vector;
      --  Structured outcome returned by the underlying search operation.
      Outcome : Greplib.Results.Search_Outcome;
      --  True when collection limits prevented retaining every delivered event.
      Truncated : Boolean := False;
      --  Exact collection-limit reasons observed during event delivery.
      Truncation : Collection_Truncation := (others => False);
   end record;

   --  Search an Ada String and collect bounded events.
   procedure Search_String
     (Subject : String;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result);

   --  Search a byte array and collect bounded events.
   procedure Search_Bytes
     (Subject : Ada.Streams.Stream_Element_Array;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result);

   --  Search a borrowed sequential stream and collect bounded events; the stream is not closed.
   procedure Search_Stream
     (Stream : in out Ada.Streams.Root_Stream_Type'Class;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);

   --  Search one file path and collect bounded events; the file handle is owned and closed internally.
   procedure Search_File
     (Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);

   --  Search path roots without filters and collect bounded events across all sources.
   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);

   --  Search path roots with compiled filters and collect bounded events across all sources.
   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Greplib.Directories.Directory_Search_Options;
      Collection : Collection_Options;
      Result : out Collected_Result;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);
end Greplib.Collected;
