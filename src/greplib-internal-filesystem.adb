pragma Ada_2022;

with Ada.Containers;
with Ada.Directories;
with Ada.Strings.Unbounded;
with GNAT.OS_Lib;

package body Greplib.Internal.Filesystem is
   package U renames Ada.Strings.Unbounded;
   use type Ada.Directories.File_Kind;
   use type Ada.Containers.Count_Type;

   type Fake_Node is record
      Path : U.Unbounded_String;
      Parent : U.Unbounded_String;
      Simple : U.Unbounded_String;
      K : Entry_Kind := Ordinary_File;
      Link : Boolean := False;
      Identity : U.Unbounded_String;
      Content : U.Unbounded_String;
      Has_Content : Boolean := False;
      Fail_Kind : Boolean := False;
      Fail_Children : Boolean := False;
      Fail_Read_After : Greplib.Byte_Count := Greplib.Byte_Count'Last;
   end record;

   package Fake_Node_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Fake_Node);
   Fake_Enabled : Boolean := False;
   Fake_Nodes : Fake_Node_Vectors.Vector;

   function Normalize (Path : String) return String is
      Result : String := Path;
   begin
      for C of Result loop
         if C = '\' then
            C := '/';
         end if;
      end loop;
      return Result;
   end Normalize;

   function Simple_From_Path (Path : String) return String is
      Normal : constant String := Normalize (Path);
      Last_Slash : Natural := 0;
   begin
      for I in Normal'Range loop
         if Normal (I) = '/' then
            Last_Slash := I;
         end if;
      end loop;

      if Last_Slash = 0 then
         return Normal;
      elsif Last_Slash = Normal'Last then
         return "";
      else
         return Normal (Last_Slash + 1 .. Normal'Last);
      end if;
   end Simple_From_Path;

   function Parent_From_Path (Path : String) return String is
      Normal : constant String := Normalize (Path);
      Last_Slash : Natural := 0;
   begin
      for I in Normal'Range loop
         if Normal (I) = '/' then
            Last_Slash := I;
         end if;
      end loop;

      if Last_Slash = 0 then
         return "";
      elsif Last_Slash = Normal'First then
         return Normal (Normal'First .. Last_Slash);
      else
         return Normal (Normal'First .. Last_Slash - 1);
      end if;
   end Parent_From_Path;

   function Find_Fake (Path : String) return Natural is
      Normal : constant String := Normalize (Path);
   begin
      if Fake_Nodes.Is_Empty then
         return 0;
      end if;

      for I in Fake_Nodes.First_Index .. Fake_Nodes.Last_Index loop
         if U.To_String (Fake_Nodes.Element (I).Path) = Normal then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Fake;

   function Kind (Path : String) return Entry_Kind is
      K : Ada.Directories.File_Kind;
   begin
      if Fake_Enabled then
         declare
            Index : constant Natural := Find_Fake (Path);
         begin
            if Index = 0 or else Fake_Nodes.Element (Index).Fail_Kind then
               raise Constraint_Error;
            end if;
            return Fake_Nodes.Element (Index).K;
         end;
      end if;

      K := Ada.Directories.Kind (Path);
      if K = Ada.Directories.Ordinary_File then
         return Ordinary_File;
      elsif K = Ada.Directories.Directory then
         return Directory;
      else
         return Special_File;
      end if;
   end Kind;

   function Simple_Name (Path : String) return String is
   begin
      if Fake_Enabled then
         return Simple_From_Path (Path);
      else
         return Ada.Directories.Simple_Name (Path);
      end if;
   end Simple_Name;

   function Is_Symbolic_Link (Path : String) return Boolean is
      Index : Natural;
   begin
      if Fake_Enabled then
         Index := Find_Fake (Path);
         return Index /= 0 and then Fake_Nodes.Element (Index).Link;
      else
         return GNAT.OS_Lib.Is_Symbolic_Link (Path);
      end if;
   end Is_Symbolic_Link;

   function Normalized_Identity (Path : String) return String is
      Index : Natural;
   begin
      if Fake_Enabled then
         Index := Find_Fake (Path);
         if Index /= 0 and then U.Length (Fake_Nodes.Element (Index).Identity) /= 0 then
            return U.To_String (Fake_Nodes.Element (Index).Identity);
         else
            return Normalize (Path);
         end if;
      else
         return GNAT.OS_Lib.Normalize_Pathname (Path, Resolve_Links => True);
      end if;
   end Normalized_Identity;

   procedure Collect_Children
     (Path : String;
      Include_Hidden : Boolean;
      Maximum_Entries : Greplib.Wide_Count;
      Entries : in out Path_List;
      Examined : in out Greplib.Wide_Count;
      Limit_Exceeded : out Boolean)
   is
      Search : Ada.Directories.Search_Type;
      Dir_Entry : Ada.Directories.Directory_Entry_Type;
      Search_Started : Boolean := False;
   begin
      Limit_Exceeded := False;
      if Fake_Enabled then
         declare
            Parent : constant String := Normalize (Path);
            Parent_Index : constant Natural := Find_Fake (Path);
         begin
            if Parent_Index = 0 or else Fake_Nodes.Element (Parent_Index).Fail_Children then
               raise Constraint_Error;
            end if;

            for Node of Fake_Nodes loop
               if U.To_String (Node.Parent) = Parent then
                  Examined := Examined + 1;
                  declare
                     Simple : constant String := U.To_String (Node.Simple);
                  begin
                     if Greplib.Wide_Count (Entries.Length) >= Maximum_Entries then
                        Limit_Exceeded := True;
                        return;
                     elsif Include_Hidden
                       or else Simple'Length = 0
                       or else Simple (Simple'First) /= '.'
                     then
                        Entries.Append (U.To_String (Node.Path));
                     end if;
                  end;
               end if;
            end loop;
            return;
         end;
      end if;

      Ada.Directories.Start_Search (Search, Path, "", (others => True));
      Search_Started := True;
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
         Examined := Examined + 1;
         declare
            Simple : constant String := Ada.Directories.Simple_Name (Dir_Entry);
         begin
            if Simple = "." or else Simple = ".." then
               null;
            elsif Greplib.Wide_Count (Entries.Length) >= Maximum_Entries then
               Limit_Exceeded := True;
               Ada.Directories.End_Search (Search);
               return;
            elsif Include_Hidden
              or else Simple'Length = 0
              or else Simple (Simple'First) /= '.'
            then
               Entries.Append (Ada.Directories.Full_Name (Dir_Entry));
            end if;
         end;
      end loop;
      Ada.Directories.End_Search (Search);
   exception
      when others =>
         if Search_Started then
            Ada.Directories.End_Search (Search);
         end if;
         raise;
   end Collect_Children;

   procedure Clear_Fake is
   begin
      Fake_Nodes.Clear;
      Fake_Enabled := False;
   end Clear_Fake;

   procedure Use_Fake is
   begin
      Fake_Enabled := True;
   end Use_Fake;

   procedure Use_Host is
   begin
      Fake_Enabled := False;
   end Use_Host;

   procedure Add_Fake_Entry
     (Path : String;
      Kind : Entry_Kind;
      Is_Link : Boolean := False;
      Identity : String := "";
      Content : String := "";
      Has_Content : Boolean := False;
      Fail_Kind : Boolean := False;
      Fail_Children : Boolean := False;
      Fail_Read_After : Greplib.Byte_Count := Greplib.Byte_Count'Last)
   is
      Normal : constant String := Normalize (Path);
      Existing : constant Natural := Find_Fake (Normal);
      Node : constant Fake_Node :=
        (Path => U.To_Unbounded_String (Normal),
         Parent => U.To_Unbounded_String (Parent_From_Path (Normal)),
         Simple => U.To_Unbounded_String (Simple_From_Path (Normal)),
         K => Kind,
         Link => Is_Link,
         Identity => U.To_Unbounded_String (Identity),
         Content => U.To_Unbounded_String (Content),
         Has_Content => Has_Content,
         Fail_Kind => Fail_Kind,
         Fail_Children => Fail_Children,
         Fail_Read_After => Fail_Read_After);
   begin
      Fake_Enabled := True;
      if Existing = 0 then
         Fake_Nodes.Append (Node);
      else
         Fake_Nodes.Replace_Element (Existing, Node);
      end if;
   end Add_Fake_Entry;

   function Has_Fake_Content (Path : String) return Boolean is
      Index : constant Natural := Find_Fake (Path);
   begin
      return Fake_Enabled and then Index /= 0 and then Fake_Nodes.Element (Index).Has_Content;
   end Has_Fake_Content;

   function Fake_Content (Path : String) return String is
      Index : constant Natural := Find_Fake (Path);
   begin
      if Fake_Enabled and then Index /= 0 then
         return U.To_String (Fake_Nodes.Element (Index).Content);
      else
         return "";
      end if;
   end Fake_Content;

   function Fake_Read_Failure_After (Path : String) return Greplib.Byte_Count is
      Index : constant Natural := Find_Fake (Path);
   begin
      if Fake_Enabled and then Index /= 0 then
         return Fake_Nodes.Element (Index).Fail_Read_After;
      else
         return Greplib.Byte_Count'Last;
      end if;
   end Fake_Read_Failure_After;
end Greplib.Internal.Filesystem;
