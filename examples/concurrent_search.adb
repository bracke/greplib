pragma Ada_2022;

with Ada.Text_IO;
with Greplib.Directories;

procedure Concurrent_Search is
   Options : Greplib.Directories.Directory_Search_Options;
begin
   Options.Worker_Count := 2;
   Ada.Text_IO.Put_Line ("requested workers:" & Options.Worker_Count'Image);
end Concurrent_Search;
