pragma Ada_2022;

with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Regexp;

package body Greplib.Internal.Regexp_Adapter is
   package U renames Ada.Strings.Unbounded;
   package R renames Regexp;
   use type R.Compile_Status;
   use type R.Match_Status;

   function Options (Case_Insensitive : Boolean) return R.Match_Options is
   begin
      return
        (Case_Sensitive => not Case_Insensitive,
         Whole_Word => False,
         Dot_Matches_Newline => False,
         Multiline_Anchors => False,
         Character_Mode => R.ASCII_Mode,
         Max_Steps => R.Default_Max_Steps,
         Abort_Callback => null);
   end Options;

   function Convert (Found : R.Match_Result) return Regex_Match is
      First_Zero : Natural;
      Last_Exclusive : Natural;
   begin
      case Found.Status is
         when R.Match_Ok =>
            First_Zero := Found.First - 1;
            if Found.Last < Found.First then
               Last_Exclusive := First_Zero;
            else
               Last_Exclusive := Found.Last;
            end if;
            return
              (Found => True,
               First_Byte => First_Zero,
               Last_Byte_Exclusive => Last_Exclusive,
               Limit_Exceeded => False);
         when R.Match_Limit_Exceeded =>
            return (Found => False, Limit_Exceeded => True, others => <>);
         when others =>
            return (others => <>);
      end case;
   end Convert;

   function Compile (Expression : String; Case_Insensitive : Boolean) return Compile_Result is
      pragma Unreferenced (Case_Insensitive);
      C : constant R.Compile_Result := R.Compile (Expression);
   begin
      if C.Status = R.Compile_Ok then
         return
           (Ok => True,
            Message => U.Null_Unbounded_String,
            Value => (Ready => True, R => C.Expression));
      else
         return
           (Ok => False,
            Message => U.To_Unbounded_String (R.Diagnostic_Image (C)),
            Value => <>);
      end if;
   exception
      when E : others =>
         return
           (Ok => False,
            Message => U.To_Unbounded_String (Ada.Exceptions.Exception_Message (E)),
            Value => <>);
   end Compile;

   function Find_From
     (Regex : Compiled_Regex;
      Subject : String;
      First_Byte : Natural;
      Case_Insensitive : Boolean) return Regex_Match is
      From : constant Positive := Positive (First_Byte + 1);
   begin
      if not Regex.Ready then
         return (others => <>);
      end if;
      return Convert (R.Find_From (Regex.R, Subject, From, Options (Case_Insensitive)));
   end Find_From;

   function Matches_Entire
     (Regex : Compiled_Regex;
      Subject : String;
      Case_Insensitive : Boolean) return Regex_Match is
   begin
      if not Regex.Ready then
         return (others => <>);
      end if;
      return Convert (R.Matches_Entire (Regex.R, Subject, Options (Case_Insensitive)));
   end Matches_Entire;

   function Supports_Spans return Boolean is
   begin
      return True;
   end Supports_Spans;
end Greplib.Internal.Regexp_Adapter;
