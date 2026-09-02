pragma Ada_2022;

with Interfaces;

package Greplib.Internal.Filesystem_Identity is
   type Object_Identity is private;

   function Unavailable return Object_Identity;
   function Read (Name : String) return Object_Identity;
   function Is_Available (Identity : Object_Identity) return Boolean;
   function Same_Object (Left, Right : Object_Identity) return Boolean;
   function Same_Filesystem (Left, Right : Object_Identity) return Boolean;
   function Image (Identity : Object_Identity) return String;

private
   type Object_Identity is record
      Available : Boolean := False;
      Device : Interfaces.Unsigned_64 := 0;
      Inode : Interfaces.Unsigned_64 := 0;
   end record;
end Greplib.Internal.Filesystem_Identity;
