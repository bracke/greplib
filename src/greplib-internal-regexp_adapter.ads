pragma Ada_2022;

with Ada.Strings.Unbounded;
private with Regexp;

package Greplib.Internal.Regexp_Adapter is
   type Compiled_Regex is private;
   type Regex_Match is record
      Found : Boolean := False;
      First_Byte : Natural := 0;
      Last_Byte_Exclusive : Natural := 0;
      Limit_Exceeded : Boolean := False;
   end record;

   type Compile_Result is record
      Ok : Boolean := False;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Value : Compiled_Regex;
   end record;

   function Compile (Expression : String; Case_Insensitive : Boolean) return Compile_Result;
   function Find_From
     (Regex : Compiled_Regex;
      Subject : String;
      First_Byte : Natural;
      Case_Insensitive : Boolean) return Regex_Match;
   function Matches_Entire
     (Regex : Compiled_Regex;
      Subject : String;
      Case_Insensitive : Boolean) return Regex_Match;
   function Supports_Spans return Boolean;
private
   type Compiled_Regex is record
      Ready : Boolean := False;
      R : Regexp.Regexp;
   end record;
end Greplib.Internal.Regexp_Adapter;
