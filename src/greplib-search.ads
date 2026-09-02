pragma Ada_2022;

with Ada.Streams;
with Greplib.Cancellation;
with Greplib.Diagnostics;
with Greplib.Events;
with Greplib.Options;
with Greplib.Paths;
with Greplib.Patterns;
with Greplib.Results;
with Greplib.Sources;

package Greplib.Search is
   --  @summary In-memory grep-like search entry points.
   --  These operations borrow their input for the duration of the call, validate options before processing records,
   --  deliver callbacks synchronously on the caller task, and return structured outcomes instead of raising for
   --  expected search conditions. Byte offsets in emitted events are zero-based original input byte offsets.
   --  Match spans are zero-based half-open logical record byte ranges after configured CR handling. Public events
   --  own their content, so callbacks and collected results never retain dangling references into Subject or parser
   --  buffers.
   --  If Sink.On_Event raises, greplib performs operation cleanup and re-raises the original exception unchanged.

   --  Validate in-memory search configuration without consuming input, delivering callbacks, or observing cancellation.
   --  The returned diagnostics include search-option errors and unusable compiled pattern sets. Search_String and
   --  Search_Bytes run the same validation automatically before processing records.
   function Validate
     (Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options) return Greplib.Diagnostics.Diagnostic_List;

   --  Search a string using caller-provided source identity and source sequence.
   --  Subject bytes are interpreted as Ada Character code units. The operation does not retain references into
   --  Subject; event content is owned by event values. Cancellation is checked before processing and between records.
   --  Source_Path spelling is preserved in events and summaries. Invalid options or unusable pattern sets consume no
   --  input and return a failed structured outcome. Sequence is one-based and must identify the logical source chosen
   --  by the caller when composing multiple searches.
   procedure Search_String_With_Source
     (Subject : String;
      Source_Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1;
      Source_Kind : Greplib.Sources.Source_Kind := Greplib.Sources.Memory_Source);

   --  Search a string and deliver events to Sink. The source path is reported as <memory> and source sequence one.
   --  This overload has the same ownership, callback, cancellation, and offset semantics as Search_String_With_Source.
   procedure Search_String
     (Subject : String;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);

   --  Search a string without retaining events. Use this overload when only the structured outcome is needed.
   --  Internally this uses a no-op sink, so record content is not retained by the caller unless summaries require it.
   procedure Search_String
     (Subject : String;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);

   --  Search a stream-element array as bytes and deliver events to Sink. The source path is reported as <bytes>.
   --  Stream elements are copied into owned event byte strings as needed; offsets remain original byte offsets.
   procedure Search_Bytes
     (Subject : Ada.Streams.Stream_Element_Array;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);

   --  Search a stream-element array without retaining events. Cancellation is still observed before and between
   --  records.
   procedure Search_Bytes
     (Subject : Ada.Streams.Stream_Element_Array;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);
end Greplib.Search;
