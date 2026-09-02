pragma Ada_2022;

with Ada.Containers.Indefinite_Vectors;

package Greplib.Internal.Filesystem is
   type Entry_Kind is (Ordinary_File, Directory, Special_File);

   package Path_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, String);
   subtype Path_List is Path_Vectors.Vector;

   function Kind (Path : String) return Entry_Kind;
   function Simple_Name (Path : String) return String;
   function Is_Symbolic_Link (Path : String) return Boolean;
   function Normalized_Identity (Path : String) return String;

   procedure Collect_Children
     (Path : String;
      Include_Hidden : Boolean;
      Maximum_Entries : Greplib.Wide_Count;
      Entries : in out Path_List;
      Examined : in out Greplib.Wide_Count;
      Limit_Exceeded : out Boolean);

   procedure Clear_Fake;
   procedure Use_Fake;
   procedure Use_Host;
   procedure Add_Fake_Entry
     (Path : String;
      Kind : Entry_Kind;
      Is_Link : Boolean := False;
      Identity : String := "";
      Content : String := "";
      Has_Content : Boolean := False;
      Fail_Kind : Boolean := False;
      Fail_Children : Boolean := False;
      Fail_Read_After : Greplib.Byte_Count := Greplib.Byte_Count'Last);
   function Has_Fake_Content (Path : String) return Boolean;
   function Fake_Content (Path : String) return String;
   function Fake_Read_Failure_After (Path : String) return Greplib.Byte_Count;
end Greplib.Internal.Filesystem;
