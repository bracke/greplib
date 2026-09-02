pragma Ada_2022;

with Ada.Strings.Unbounded;

package body Greplib.Byte_Strings is
   use type Ada.Streams.Stream_Element_Offset;
   package U renames Ada.Strings.Unbounded;

   function To_Byte_String (Item : String) return Byte_String is
   begin
      return (Data => U.To_Unbounded_String (Item));
   end To_Byte_String;

   function To_Byte_String (Item : Ada.Streams.Stream_Element_Array) return Byte_String is
      Result : String (1 .. Item'Length);
      J : Positive := Result'First;
   begin
      for E of Item loop
         Result (J) := Character'Val (Integer (E));
         J := J + 1;
      end loop;
      return To_Byte_String (Result);
   end To_Byte_String;

   function To_String (Item : Byte_String) return String is
   begin
      return U.To_String (Item.Data);
   end To_String;

   function To_Stream_Element_Array (Item : Byte_String) return Ada.Streams.Stream_Element_Array is
      S : constant String := To_String (Item);
      Result : Ada.Streams.Stream_Element_Array
        (Ada.Streams.Stream_Element_Offset (1) .. Ada.Streams.Stream_Element_Offset (S'Length));
      J : Ada.Streams.Stream_Element_Offset := Result'First;
   begin
      for C of S loop
         Result (J) := Ada.Streams.Stream_Element (Character'Pos (C));
         J := J + Ada.Streams.Stream_Element_Offset (1);
      end loop;
      return Result;
   end To_Stream_Element_Array;

   function Length (Item : Byte_String) return Byte_Count is
   begin
      return Byte_Count (U.Length (Item.Data));
   end Length;

   function Element (Item : Byte_String; Index : Positive) return Character is
      S : constant String := To_String (Item);
   begin
      return S (Index);
   end Element;
end Greplib.Byte_Strings;
