pragma Ada_2022;

with Interfaces.C;
with Interfaces.C.Strings;

package body Greplib.Internal.Filesystem_Identity is
   use type Interfaces.Unsigned_64;
   use type Interfaces.C.Strings.chars_ptr;

   type Long_Array is array (Positive range <>) of Interfaces.C.long
     with Convention => C;

   type Timespec is record
      Sec : Interfaces.C.long;
      Nsec : Interfaces.C.long;
   end record
     with Convention => C;

   type Stat_Buffer is record
      Dev : Interfaces.C.unsigned_long;
      Ino : Interfaces.C.unsigned_long;
      Nlink : Interfaces.C.unsigned_long;
      Mode : Interfaces.C.unsigned;
      Uid : Interfaces.C.unsigned;
      Gid : Interfaces.C.unsigned;
      Pad0 : Interfaces.C.int;
      Rdev : Interfaces.C.unsigned_long;
      Size : Interfaces.C.long;
      Blksize : Interfaces.C.long;
      Blocks : Interfaces.C.long;
      Atim : Timespec;
      Mtim : Timespec;
      Ctim : Timespec;
      Unused : Long_Array (1 .. 3);
   end record
     with Convention => C;

   function C_Stat
     (Path : Interfaces.C.Strings.chars_ptr;
      Buffer : access Stat_Buffer) return Interfaces.C.int
     with Import, Convention => C, External_Name => "stat";

   function Unavailable return Object_Identity is
      ((Available => False, Device => 0, Inode => 0));

   function Read (Name : String) return Object_Identity is
      use type Interfaces.C.int;
      C_Name : Interfaces.C.Strings.chars_ptr := Interfaces.C.Strings.New_String (Name);
      Buffer : aliased Stat_Buffer;
      Status : Interfaces.C.int;
   begin
      Status := C_Stat (C_Name, Buffer'Access);
      Interfaces.C.Strings.Free (C_Name);

      if Status = 0 then
         return
           (Available => True,
            Device => Interfaces.Unsigned_64 (Buffer.Dev),
            Inode => Interfaces.Unsigned_64 (Buffer.Ino));
      else
         return (Available => False, Device => 0, Inode => 0);
      end if;
   exception
      when others =>
         if C_Name /= Interfaces.C.Strings.Null_Ptr then
            Interfaces.C.Strings.Free (C_Name);
         end if;
         return (Available => False, Device => 0, Inode => 0);
   end Read;

   function Is_Available (Identity : Object_Identity) return Boolean is
      (Identity.Available);

   function Same_Object (Left, Right : Object_Identity) return Boolean is
      (Left.Available
       and then Right.Available
       and then Left.Device = Right.Device
       and then Left.Inode = Right.Inode);

   function Same_Filesystem (Left, Right : Object_Identity) return Boolean is
      (Left.Available and then Right.Available and then Left.Device = Right.Device);

   function Image (Identity : Object_Identity) return String is
   begin
      if not Identity.Available then
         return "unavailable";
      end if;
      return Interfaces.Unsigned_64'Image (Identity.Device) & ":" & Interfaces.Unsigned_64'Image (Identity.Inode);
   end Image;
end Greplib.Internal.Filesystem_Identity;
