pragma Ada_2022;

with Ada.Strings.Unbounded;
with Greplib.Internal.Regexp_Adapter;

package body Greplib.Path_Filters is
   package U renames Ada.Strings.Unbounded;

   type Regex_Holder is record
      Value : Greplib.Internal.Regexp_Adapter.Compiled_Regex;
   end record;

   function Normalize_Separators (Text : String) return String is
      Result : String := Text;
   begin
      for C of Result loop
         if C = '\' then
            C := '/';
         end if;
      end loop;
      return Result;
   end Normalize_Separators;

   function Rule
     (Action : Filter_Action;
      Target : Filter_Target;
      Basis : Filter_Basis;
      Kind : Filter_Kind;
      Pattern : String) return Filter_Rule is
   begin
      return
        (Action, Target, Basis, Kind,
         U.To_Unbounded_String
           (if Basis = Relative_Path and then Kind = Exact_Name
            then Normalize_Separators (Pattern)
            else Pattern));
   end Rule;

   procedure Append (List : in out Filter_List; Item : Filter_Rule) is
   begin
      List.Items.Append (Item);
   end Append;

   function Valid_Glob (Pattern : String) return Boolean is
   begin
      return Pattern'Length = 0 or else Pattern (Pattern'Last) /= '\';
   end Valid_Glob;

   function Compile (List : Filter_List) return Compiled_Filter_Set is
      use Greplib.Diagnostics;
      Result : Compiled_Filter_Set;
   begin
      for R of List.Items loop
         if R.Kind = Regular_Expression then
            declare
               C : constant Greplib.Internal.Regexp_Adapter.Compile_Result :=
                 Greplib.Internal.Regexp_Adapter.Compile (U.To_String (R.Pattern), False);
            begin
               if not C.Ok then
                  Result.Usable := False;
                  Result.Diags.Append
                    (Make (Path_Filter_Invalid_Pattern, Fatal_Error, U.To_String (C.Message)));
               else
                  Result.Items.Append (Compiled_Rule'(Rule => R, Regex => new Regex_Holder'(Value => C.Value)));
               end if;
            end;
         elsif R.Kind = Glob_Pattern and then not Valid_Glob (U.To_String (R.Pattern)) then
            Result.Usable := False;
            Result.Diags.Append
              (Make (Path_Filter_Invalid_Pattern, Fatal_Error, "glob pattern ends with escape"));
         else
            Result.Items.Append (Compiled_Rule'(Rule => R, Regex => <>));
         end if;
      end loop;
      if not Result.Usable then
         Result.Items.Clear;
      end if;
      return Result;
   end Compile;

   function Is_Usable (Set : Compiled_Filter_Set) return Boolean is (Set.Usable);
   function Diagnostics (Set : Compiled_Filter_Set) return Greplib.Diagnostics.Diagnostic_List is (Set.Diags);

   function Validate (List : Filter_List) return Greplib.Diagnostics.Diagnostic_List is
      Set : constant Compiled_Filter_Set := Compile (List);
   begin
      return Diagnostics (Set);
   end Validate;

   function Glob_Match (Text : String; Pattern : String) return Boolean is
      function Match (T : Natural; P : Natural) return Boolean is
         Pattern_Char : Character;
      begin
         if P > Pattern'Length then
            return T > Text'Length;
         end if;

         Pattern_Char := Pattern (Pattern'First + P - 1);

         if Pattern_Char = '\' then
            if P = Pattern'Length then
               return False;
            end if;
            return
              T <= Text'Length
              and then Text (Text'First + T - 1) = Pattern (Pattern'First + P)
              and then Match (T + 1, P + 2);
         elsif Pattern_Char = '*' then
            if P < Pattern'Length and then Pattern (Pattern'First + P) = '*' then
               return Match (T, P + 2) or else (T <= Text'Length and then Match (T + 1, P));
            else
               return
                 Match (T, P + 1)
                 or else
                   (T <= Text'Length
                    and then Text (Text'First + T - 1) /= '/'
                    and then Match (T + 1, P));
            end if;
         elsif Pattern_Char = '?' then
            return
              T <= Text'Length
              and then Text (Text'First + T - 1) /= '/'
              and then Match (T + 1, P + 1);
         else
            return
              T <= Text'Length
              and then Text (Text'First + T - 1) = Pattern_Char
              and then Match (T + 1, P + 1);
         end if;
      end Match;
   begin
      return Match (1, 1);
   end Glob_Match;

   function Included
     (Set : Compiled_Filter_Set;
      Base : String;
      Relative_Path : String;
      Is_Directory : Boolean) return Boolean
   is
      Result : Boolean := True;
   begin
      for Item of Set.Items loop
         if Item.Rule.Target = Any_Entry
           or else (Item.Rule.Target = Files_Only and then not Is_Directory)
           or else (Item.Rule.Target = Directories_Only and then Is_Directory)
         then
            declare
               Subject : constant String :=
                 (if Item.Rule.Basis = Base_Name then Base else Normalize_Separators (Relative_Path));
               Pattern : constant String := U.To_String (Item.Rule.Pattern);
               Hit : Boolean := False;
            begin
               case Item.Rule.Kind is
                  when Exact_Name =>
                     Hit := Subject = Pattern;
                  when Glob_Pattern =>
                     Hit := Glob_Match (Subject, Pattern);
                  when Regular_Expression =>
                     Hit :=
                       Greplib.Internal.Regexp_Adapter.Matches_Entire
                         (Item.Regex.Value, Subject, False).Found;
               end case;
               if Hit then
                  Result := Item.Rule.Action = Include;
               end if;
            end;
         end if;
      end loop;
      return Result;
   end Included;
end Greplib.Path_Filters;
