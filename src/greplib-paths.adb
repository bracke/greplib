pragma Ada_2022;

with Ada.Strings.Unbounded;

package body Greplib.Paths is
   package U renames Ada.Strings.Unbounded;

   function To_Path (Image : String) return Path is
   begin
      return (Text => U.To_Unbounded_String (Image));
   end To_Path;

   function Image (Item : Path) return String is
   begin
      return U.To_String (Item.Text);
   end Image;

   function Is_Empty (Item : Path) return Boolean is
   begin
      return U.Length (Item.Text) = 0;
   end Is_Empty;

   procedure Append (List : in out Path_List; Item : Path) is
   begin
      List.Items.Append (Item);
   end Append;

   function Length (List : Path_List) return Natural is
   begin
      return Natural (List.Items.Length);
   end Length;

   function Element (List : Path_List; Index : Positive) return Path is
   begin
      return List.Items.Element (Index);
   end Element;

   procedure Clear (List : in out Path_List) is
   begin
      List.Items.Clear;
   end Clear;
end Greplib.Paths;
