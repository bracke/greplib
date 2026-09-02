pragma Ada_2022;

with Ada.Text_IO;
with Greplib.Cancellation;

procedure Cancel_Search is
   Source : aliased Greplib.Cancellation.Cancellation_Source;
begin
   Source.Request;
   Ada.Text_IO.Put_Line
     ("cancelled:" & Boolean'Image (Greplib.Cancellation.Is_Requested (Greplib.Cancellation.Token (Source))));
end Cancel_Search;
