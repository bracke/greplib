pragma Ada_2022;

package Greplib.Result_Authority is
   --  Edit authority type for internal mutation operations.
   --  Public callers can name the type for signatures but cannot construct a value.
   type Token is private;

   Internal : constant Token;
private
   type Token is null record;
   Internal : constant Token := (null record);
end Greplib.Result_Authority;
