pragma Ada_2022;

package body Greplib.Events is
   overriding procedure On_Event
     (Sink : in out No_Op_Sink;
      Event : Search_Event;
      Action : out Event_Action) is
      pragma Unreferenced (Sink, Event);
   begin
      Action := Continue_Search;
   end On_Event;

   function Kind (Event : Search_Event) return Event_Kind is (Event.K);
   function Source (Event : Search_Event) return Greplib.Sources.Source_Descriptor is (Event.Source);
   function Source_Path (Event : Search_Event) return Greplib.Paths.Path is (Greplib.Sources.Path (Event.Source));
   function Source_No (Event : Search_Event) return Source_Sequence is (Greplib.Sources.Sequence (Event.Source));
   function Group_Number (Event : Search_Event) return Wide_Count is (Event.Group);
   function Record_No (Event : Search_Event) return Record_Number is (Event.Number);
   function Record_Byte_Offset (Event : Search_Event) return Byte_Offset is (Event.Offset);
   function Logical_Content_Size (Event : Search_Event) return Byte_Count is (Event.Logical_Size);
   function Original_Content_Size (Event : Search_Event) return Byte_Count is (Event.Original_Size);
   function Separator_Size (Event : Search_Event) return Byte_Count is (Event.Separator_Bytes);
   function Separator_Present (Event : Search_Event) return Boolean is (Event.Has_Separator);
   function Carriage_Return_Stripped (Event : Search_Event) return Boolean is (Event.CR_Stripped);
   function Content (Event : Search_Event) return Greplib.Byte_Strings.Byte_String is (Event.Text);
   function Spans (Event : Search_Event) return Span_List is (Event.Match_Spans);
   function Spans_Complete (Event : Search_Event) return Boolean is (Event.Complete);
   function Diagnostic (Event : Search_Event) return Greplib.Diagnostics.Diagnostic is (Event.Diag);
   function Count (Event : Search_Event) return Wide_Count is (Event.Value);
   function Had_Match (Event : Search_Event) return Boolean is (Event.Match);

end Greplib.Events;
