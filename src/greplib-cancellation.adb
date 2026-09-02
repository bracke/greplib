pragma Ada_2022;

package body Greplib.Cancellation is
   protected body Cancellation_Source is
      procedure Request is
      begin
         Requested := True;
      end Request;

      function Is_Requested return Boolean is
      begin
         return Requested;
      end Is_Requested;
   end Cancellation_Source;

   function Token (Source : aliased Cancellation_Source) return Cancellation_Token is
   begin
      return (Primary => Source'Unchecked_Access, Secondary => null);
   end Token;

   function Combine (Left, Right : Cancellation_Token) return Cancellation_Token is
   begin
      if Left.Primary = null then
         return Right;
      elsif Right.Primary = null then
         return Left;
      else
         return (Primary => Left.Primary, Secondary => Right.Primary);
      end if;
   end Combine;

   function Is_Requested (Token : Cancellation_Token) return Boolean is
   begin
      return (Token.Primary /= null and then Token.Primary.Is_Requested)
        or else (Token.Secondary /= null and then Token.Secondary.Is_Requested);
   end Is_Requested;
end Greplib.Cancellation;
