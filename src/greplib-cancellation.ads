pragma Ada_2022;

package Greplib.Cancellation is
   --  @summary Cooperative cancellation source and read-only token primitives.
   --  Search operations observe tokens at documented checkpoints and never use task abort for normal cancellation.
   --  Mutable request authority owned by the caller or by an internal operation controller.
   protected type Cancellation_Source is
      --  Request cooperative cancellation. The transition is monotonic and idempotent.
      procedure Request;

      --  True after Request has been called.
      function Is_Requested return Boolean;
   private
      Requested : Boolean := False;
   end Cancellation_Source;

   --  Read-only cancellation view. A null token represents no external cancellation request.
   type Cancellation_Token is private;

   --  Return a token observing Source without transferring ownership of Source.
   function Token (Source : aliased Cancellation_Source) return Cancellation_Token;

   --  Return a token that is requested when either Left or Right is requested.
   function Combine (Left, Right : Cancellation_Token) return Cancellation_Token;

   --  True when the token or any combined token input has observed a cancellation request.
   function Is_Requested (Token : Cancellation_Token) return Boolean;

   --  Token that never requests cancellation.
   No_Cancellation : constant Cancellation_Token;
private
   type Cancellation_Source_Access is access constant Cancellation_Source;
   type Cancellation_Token is record
      Primary : Cancellation_Source_Access := null;
      Secondary : Cancellation_Source_Access := null;
   end record;
   No_Cancellation : constant Cancellation_Token := (Primary => null, Secondary => null);
end Greplib.Cancellation;
