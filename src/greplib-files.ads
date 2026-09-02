pragma Ada_2022;

with Ada.Streams;
with Greplib.Cancellation;
with Greplib.Diagnostics;
with Greplib.Events;
with Greplib.Options;
with Greplib.Paths;
with Greplib.Patterns;
with Greplib.Results;

package Greplib.Files is
   --  @summary Stream and file search entry points.
   --  Stream operations borrow the caller's stream and never close it. File operations open byte-preserving streams,
   --  own and close their file handles, and report expected filesystem or stream failures structurally. Event callbacks
   --  run synchronously on the caller task; worker tasks used by directory search do not invoke public callbacks.
   --  Record byte offsets and byte counts refer to original bytes read from the stream or file. Match spans are
   --  half-open logical record byte ranges after CR handling. Events own retained content; no event refers to reusable
   --  read buffers. Callback exceptions are re-raised unchanged after stream/file cleanup.

   --  Validate stream and file search configuration without reading a stream, opening a file, delivering callbacks, or
   --  observing cancellation. The returned diagnostics include search-option errors and unusable compiled pattern sets.
   --  Search_Stream and Search_File run the same validation automatically before consuming input.
   function Validate
     (Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options) return Greplib.Diagnostics.Diagnostic_List;

   --  Search a borrowed sequential Ada stream and deliver events. Sequence identifies the logical source in callbacks.
   --  The stream need not be seekable and is not rewound. Cancellation is checked after reads and between records, but
   --  an implementation-defined blocking Read call can delay cancellation observation.
   procedure Search_Stream
     (Stream : in out Ada.Streams.Root_Stream_Type'Class;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1);

   --  Search a borrowed sequential Ada stream without retaining events. The caller remains responsible for closing it.
   procedure Search_Stream
     (Stream : in out Ada.Streams.Root_Stream_Type'Class;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1);

   --  Search one filesystem path as a byte-preserving file source. The file handle is closed on every completion path.
   --  Open, read, metadata, and close failures are converted to diagnostics and summaries where they are expected
   --  operational conditions. Path spelling is preserved in source events and summaries.
   procedure Search_File
     (Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1);

   --  Search one filesystem path without retaining events. The same ownership and diagnostic rules as Search_File
   --  apply.
   procedure Search_File
     (Path : Greplib.Paths.Path;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Options : Greplib.Options.Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation;
      Sequence : Source_Sequence := 1);
end Greplib.Files;
