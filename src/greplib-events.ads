pragma Ada_2022;

with Ada.Containers.Indefinite_Vectors;
with Greplib.Byte_Strings;
with Greplib.Diagnostics;
with Greplib.Paths;
with Greplib.Sources;

package Greplib.Events is
   --  @summary Streaming event model and callback sink interface.
   --  Event content is owned by the event value; callbacks execute synchronously on the public search caller task.
   --  Accessors for fields not meaningful for an event kind return the type's neutral default. Applications should use
   --  Kind before inspecting variant-specific payload. Search_Event values are safe to copy and retain after callback
   --  return; they do not borrow parser buffers, stream buffers, path traversal buffers, or regexp match results.
   --  Callback return action. Stop actions are cooperative and trigger cleanup before the public search returns.
   type Event_Action is (Continue_Search, Stop_Current_Source, Stop_All_Search);

   --  Event variant discriminator. Accessors return meaningful values for the corresponding event kinds.
   type Event_Kind is
     (Source_Started, Selected_Record, Context_Record, Binary_Match, Count_Result,
      Source_Name_Result, Diagnostic_Event, Source_Completed);

   --  Accepted non-overlapping match span using half-open logical record byte offsets: [First, Last).
   type Match_Span is record
      --  One-based declaration-stable pattern index responsible for the span.
      Pattern : Pattern_Index := Pattern_Index'First;
      --  First logical content byte in the span, zero-based relative to the record content.
      First_Byte : Byte_Offset := 0;
      --  First logical content byte after the span; equal to First_Byte for zero-length matches.
      Last_Byte_Exclusive : Byte_Offset := 0;
   end record;

   --  Owned list of accepted spans. Span offsets are logical record bytes after optional CR stripping.
   package Span_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Match_Span);

   --  Public span list type returned from events and collected results.
   subtype Span_List is Span_Vectors.Vector;

   --  Owned event value. All content can be retained by callers after On_Event returns.
   --  The representation is private; use accessors to inspect variant-specific payloads.
   type Search_Event is private;

   --  Limited callback interface. Implementations must not assume reentrant invocation. Concurrent directory searches
   --  serialize callbacks on the caller task; worker tasks never invoke this interface.
   type Event_Sink is limited interface;

   --  Synchronously deliver Event and return the desired action.
   --  If this operation raises, greplib cleans up operation-owned resources and re-raises unchanged.
   procedure On_Event
     (Sink : in out Event_Sink;
      Event : Search_Event;
      Action : out Event_Action) is abstract;

   --  Sink that requests Continue_Search for every event and retains nothing.
   type No_Op_Sink is new Event_Sink with null record;

   --  No-op event handler.
   overriding procedure On_Event
     (Sink : in out No_Op_Sink;
      Event : Search_Event;
      Action : out Event_Action);

   --  Return the event discriminator.
   function Kind (Event : Search_Event) return Event_Kind;
   --  Return the stable owned source descriptor. It preserves source kind, sequence, and caller-visible path spelling.
   function Source (Event : Search_Event) return Greplib.Sources.Source_Descriptor;
   --  Return the preserved source path or identity.
   function Source_Path (Event : Search_Event) return Greplib.Paths.Path;
   --  Return the one-based source sequence.
   function Source_No (Event : Search_Event) return Source_Sequence;
   --  Return the context group number, or zero when context grouping is disabled.
   function Group_Number (Event : Search_Event) return Wide_Count;
   --  Return the one-based physical record number.
   function Record_No (Event : Search_Event) return Record_Number;
   --  Return original byte offset of the first record content byte.
   function Record_Byte_Offset (Event : Search_Event) return Byte_Offset;
   --  Return logical content size in bytes after CR policy.
   function Logical_Content_Size (Event : Search_Event) return Byte_Count;
   --  Return original content size in bytes before CR policy.
   function Original_Content_Size (Event : Search_Event) return Byte_Count;
   --  Return separator size in original source bytes.
   function Separator_Size (Event : Search_Event) return Byte_Count;
   --  True when a separator was present after this record.
   function Separator_Present (Event : Search_Event) return Boolean;
   --  True when CR stripping changed this record's logical content.
   function Carriage_Return_Stripped (Event : Search_Event) return Boolean;
   --  Return owned logical content.
   function Content (Event : Search_Event) return Greplib.Byte_Strings.Byte_String;
   --  Return accepted half-open spans. Offsets are logical record byte offsets, not absolute source offsets.
   function Spans (Event : Search_Event) return Span_List;
   --  True when Spans contains the complete requested enumeration. False means truncation or a cheaper execution plan
   --  prevented exact span enumeration; counts and summaries expose completeness separately.
   function Spans_Complete (Event : Search_Event) return Boolean;
   --  Return structured diagnostic payload.
   function Diagnostic (Event : Search_Event) return Greplib.Diagnostics.Diagnostic;
   --  Return count payload for Count_Result.
   function Count (Event : Search_Event) return Wide_Count;
   --  Return source-name Boolean payload.
   function Had_Match (Event : Search_Event) return Boolean;

private
   type Search_Event is record
      K : Event_Kind := Source_Started;
      Source : Greplib.Sources.Source_Descriptor;
      Group : Wide_Count := 0;
      Number : Record_Number := 1;
      Offset : Byte_Offset := 0;
      Logical_Size : Byte_Count := 0;
      Original_Size : Byte_Count := 0;
      Separator_Bytes : Byte_Count := 0;
      Has_Separator : Boolean := False;
      CR_Stripped : Boolean := False;
      Text : Greplib.Byte_Strings.Byte_String;
      Match_Spans : Span_List;
      Complete : Boolean := True;
      Diag : Greplib.Diagnostics.Diagnostic :=
        Greplib.Diagnostics.Make
          (Greplib.Diagnostics.Internal_Invariant_Failure, Greplib.Diagnostics.Information);
      Value : Wide_Count := 0;
      Match : Boolean := False;
   end record;
end Greplib.Events;
