pragma Ada_2022;

with Ada.Streams;
with Ada.Strings.Unbounded;
with Greplib;

package Greplib.Byte_Strings is
   --  @summary Owned immutable byte-string values for event and result payloads.
   --  Conversions copy bytes so public events do not retain references into reusable parser buffers.
   --  Byte_String values are safe to copy between queued events and to retain after callbacks return.
   type Byte_String is private;

   --  Canonical empty immutable byte string.
   Empty : constant Byte_String;

   --  Copy each Character code position from Item into an owned byte string.
   function To_Byte_String (Item : String) return Byte_String;

   --  Copy each stream element from Item into an owned byte string, preserving byte values exactly.
   function To_Byte_String (Item : Ada.Streams.Stream_Element_Array) return Byte_String;

   --  Return the bytes as an Ada String. Each byte is mapped to the Character with the same position.
   function To_String (Item : Byte_String) return String;

   --  Return the bytes as a Stream_Element_Array. The returned array is owned by the caller.
   function To_Stream_Element_Array (Item : Byte_String) return Ada.Streams.Stream_Element_Array;

   --  Exact byte length. The value is independent of text encoding.
   function Length (Item : Byte_String) return Byte_Count;

   --  Return the one-based byte at Index. Constraint_Error is propagated for an invalid index.
   function Element (Item : Byte_String; Index : Positive) return Character;

private
   type Byte_String is record
      Data : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   Empty : constant Byte_String := (Data => Ada.Strings.Unbounded.Null_Unbounded_String);
end Greplib.Byte_Strings;
