pragma Ada_2022;

with Ada.Strings.Unbounded;
with Greplib.Internal.Regexp_Adapter;

package body Greplib.Patterns is
   package U renames Ada.Strings.Unbounded;
   package RA renames Greplib.Internal.Regexp_Adapter;

   type Compiled_Entry is record
      Original_Index : Pattern_Index;
      K : Pattern_Kind;
      T : U.Unbounded_String;
      Regex : RA.Compiled_Regex;
   end record;

   function Regular_Expression_Pattern (Expression : String) return Pattern_Definition is
   begin
      return (K => Regular_Expression, T => U.To_Unbounded_String (Expression));
   end Regular_Expression_Pattern;

   function Fixed_String_Pattern (Text : String) return Pattern_Definition is
   begin
      return (K => Fixed_String, T => U.To_Unbounded_String (Text));
   end Fixed_String_Pattern;

   procedure Append (List : in out Pattern_List; Pattern : Pattern_Definition) is
   begin
      List.Items.Append (Pattern);
   end Append;

   function Length (List : Pattern_List) return Natural is (Natural (List.Items.Length));
   function Kind (Pattern : Pattern_Definition) return Pattern_Kind is (Pattern.K);
   function Text (Pattern : Pattern_Definition) return String is (U.To_String (Pattern.T));

   function Compile
     (Patterns : Pattern_List;
      Options : Compilation_Options := (others => <>)) return Compiled_Pattern_Set
   is
      use Greplib.Diagnostics;
      Result : Compiled_Pattern_Set;
      Total : Byte_Count := 0;
      Index : Pattern_Index := 1;
   begin
      Result.Opts := Options;
      if Options.Maximum_Pattern_Count = 0 then
         Result.Items.Clear;
         Result.Diags.Append
           (Make
              (Configuration_Invalid_Option_Combination,
               Fatal_Error,
               "maximum pattern count must be positive"));
      end if;

      if Options.Maximum_Total_Pattern_Bytes = 0 then
         Result.Items.Clear;
         Result.Diags.Append
           (Make
              (Configuration_Invalid_Option_Combination,
               Fatal_Error,
               "maximum total pattern bytes must be positive"));
      end if;

      if Patterns.Items.Is_Empty then
         Result.Items.Clear;
         Result.Diags.Append (Make (Configuration_No_Patterns, Fatal_Error, "pattern list is empty"));
      end if;

      if not Result.Diags.Is_Empty then
         return Result;
      end if;

      if Wide_Count (Patterns.Items.Length) > Options.Maximum_Pattern_Count then
         Result.Items.Clear;
         Result.Diags.Append (Make (Configuration_Invalid_Option_Combination, Fatal_Error, "too many patterns"));
         return Result;
      end if;

      for P of Patterns.Items loop
         Total := Total + Byte_Count (U.Length (P.T));
         if Total > Options.Maximum_Total_Pattern_Bytes then
            Result.Items.Clear;
            Result.Diags.Append (Make (Configuration_Invalid_Option_Combination, Fatal_Error, "pattern bytes limit"));
            return Result;
         end if;

         if P.K = Regular_Expression then
            declare
               C : constant RA.Compile_Result := RA.Compile (U.To_String (P.T), Options.Case_Insensitive);
            begin
               if not C.Ok then
                  Result.Items.Clear;
                  Result.Diags.Append
                    (Make (Pattern_Invalid_Regular_Expression, Fatal_Error, U.To_String (C.Message), Index));
                  return Result;
               end if;
               Result.Items.Append
                 (new Compiled_Entry'
                    (Original_Index => Index, K => P.K, T => P.T, Regex => C.Value));
            end;
         else
            Result.Items.Append
              (new Compiled_Entry'
                 (Original_Index => Index, K => P.K, T => P.T, Regex => <>));
         end if;

         Index := Index + 1;
      end loop;

      Result.Usable := True;
      return Result;
   exception
      when Constraint_Error =>
         Result.Usable := False;
         Result.Items.Clear;
         Result.Diags.Clear;
         Result.Diags.Append
           (Make (Internal_Numeric_Overflow, Fatal_Error, "pattern compilation numeric overflow"));
         return Result;
   end Compile;

   function Is_Usable (Set : Compiled_Pattern_Set) return Boolean is (Set.Usable);
   function Diagnostics (Set : Compiled_Pattern_Set) return Greplib.Diagnostics.Diagnostic_List is (Set.Diags);
   function Validate
     (Patterns : Pattern_List;
      Options : Compilation_Options := (others => <>)) return Greplib.Diagnostics.Diagnostic_List
   is
      Set : constant Compiled_Pattern_Set := Compile (Patterns, Options);
   begin
      return Diagnostics (Set);
   end Validate;

   function Count (Set : Compiled_Pattern_Set) return Natural is (Natural (Set.Items.Length));
   function Options (Set : Compiled_Pattern_Set) return Compilation_Options is (Set.Opts);

   function Fold (C : Character) return Character is
   begin
      if C in 'A' .. 'Z' then
         return Character'Val (Character'Pos (C) + Character'Pos ('a') - Character'Pos ('A'));
      else
         return C;
      end if;
   end Fold;

   function Equal_At
     (Subject : String;
      Pattern : String;
      Start : Positive;
      Case_Insensitive : Boolean) return Boolean is
   begin
      for J in Pattern'Range loop
         declare
            S : constant Character := Subject (Start + J - Pattern'First);
            P : constant Character := Pattern (J);
         begin
            if Case_Insensitive then
               if Fold (S) /= Fold (P) then
                  return False;
               end if;
            elsif S /= P then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Equal_At;

   function Is_Word (C : Character) return Boolean is
   begin
      return C in 'A' .. 'Z' or else C in 'a' .. 'z' or else C in '0' .. '9' or else C = '_';
   end Is_Word;

   function Passes_Word (Subject : String; First : Natural; Last_Exclusive : Natural) return Boolean is
   begin
      if First = Last_Exclusive then
         return False;
      end if;
      if First > 0 and then Is_Word (Subject (Subject'First + First - 1)) then
         return False;
      end if;
      if Last_Exclusive < Subject'Length and then Is_Word (Subject (Subject'First + Last_Exclusive)) then
         return False;
      end if;
      return True;
   end Passes_Word;

   procedure Add_Span
     (Set : Compiled_Pattern_Set;
      Subject : String;
      Candidate : Greplib.Events.Match_Span;
      Spans : in out Greplib.Events.Span_List) is
   begin
      if Set.Opts.Whole_Word
        and then not Passes_Word
          (Subject, Natural (Candidate.First_Byte), Natural (Candidate.Last_Byte_Exclusive))
      then
         return;
      end if;
      Spans.Append (Candidate);
   end Add_Span;

   procedure Match_Record
     (Set : Compiled_Pattern_Set;
      Subject : String;
      Need_Spans : Boolean;
      Positive : out Boolean;
      Spans : out Greplib.Events.Span_List;
      Spans_Complete : out Boolean)
   is
      use Greplib.Events;
   begin
      Positive := False;
      Spans.Clear;
      Spans_Complete := True;

      if not Set.Usable then
         return;
      end if;

      for E of Set.Items loop
         declare
            Pattern_Text : constant String := U.To_String (E.T);
         begin
            if E.K = Fixed_String then
               if Set.Opts.Whole_Record then
                  if Subject'Length = Pattern_Text'Length
                    and then
                      (Pattern_Text'Length = 0
                       or else Equal_At (Subject, Pattern_Text, Subject'First, Set.Opts.Case_Insensitive))
                  then
                     declare
                        S : constant Match_Span :=
                          (E.Original_Index, 0, Byte_Offset (Subject'Length));
                     begin
                        if not Set.Opts.Whole_Word
                          or else Passes_Word (Subject, Natural (S.First_Byte), Natural (S.Last_Byte_Exclusive))
                        then
                           Positive := True;
                           if Need_Spans then
                              Spans.Append (S);
                           end if;
                           return;
                        end if;
                     end;
                  end if;
               elsif Pattern_Text'Length = 0 then
                  if Set.Opts.Whole_Word then
                     null;
                  elsif Need_Spans then
                     Positive := True;
                     for Pos in 0 .. Subject'Length loop
                        Spans.Append
                          (Greplib.Events.Match_Span'
                             (E.Original_Index, Byte_Offset (Pos), Byte_Offset (Pos)));
                     end loop;
                  else
                     Positive := True;
                     return;
                  end if;
               elsif Subject'Length >= Pattern_Text'Length then
                  for Pos in Subject'First .. Subject'Last - Pattern_Text'Length + 1 loop
                     if Equal_At (Subject, Pattern_Text, Pos, Set.Opts.Case_Insensitive) then
                        declare
                           First : constant Natural := Pos - Subject'First;
                           Last : constant Natural := First + Pattern_Text'Length;
                        begin
                           if not Set.Opts.Whole_Word or else Passes_Word (Subject, First, Last) then
                              Positive := True;
                              if Need_Spans then
                                 Spans.Append
                                   (Greplib.Events.Match_Span'
                                      (E.Original_Index, Byte_Offset (First), Byte_Offset (Last)));
                              else
                                 return;
                              end if;
                           end if;
                        end;
                     end if;
                  end loop;
               end if;
            else
               if Set.Opts.Whole_Record then
                  declare
                     Found : constant RA.Regex_Match :=
                       RA.Matches_Entire (E.Regex, Subject, Set.Opts.Case_Insensitive);
                  begin
                     if Found.Found
                       and then
                         (not Set.Opts.Whole_Word or else Passes_Word (Subject, 0, Subject'Length))
                     then
                        Positive := True;
                        if Need_Spans then
                           Spans.Append
                             (Greplib.Events.Match_Span'
                                (E.Original_Index, 0, Byte_Offset (Subject'Length)));
                        else
                           return;
                        end if;
                     elsif Found.Limit_Exceeded then
                        Spans_Complete := False;
                     end if;
                  end;
               else
                  declare
                     Current : Natural := 0;
                  begin
                     while Current <= Subject'Length loop
                        declare
                           Found : constant RA.Regex_Match :=
                             RA.Find_From (E.Regex, Subject, Current, Set.Opts.Case_Insensitive);
                           Accepted : constant Boolean :=
                             Found.Found
                             and then
                               (not Set.Opts.Whole_Word
                                or else
                                  Passes_Word
                                    (Subject, Found.First_Byte, Found.Last_Byte_Exclusive));
                        begin
                           exit when not Found.Found;
                           if Accepted then
                              Positive := True;
                              if Need_Spans then
                                 Spans.Append
                                   (Greplib.Events.Match_Span'
                                      (E.Original_Index,
                                       Byte_Offset (Found.First_Byte),
                                       Byte_Offset (Found.Last_Byte_Exclusive)));
                              else
                                 return;
                              end if;
                           elsif Found.Limit_Exceeded then
                              Spans_Complete := False;
                              exit;
                           end if;

                           if Accepted and then Found.Last_Byte_Exclusive > Found.First_Byte then
                              Current := Found.Last_Byte_Exclusive;
                           elsif Found.First_Byte < Subject'Length then
                              Current := Found.First_Byte + 1;
                           else
                              exit;
                           end if;
                        end;
                     end loop;
                  end;
               end if;
            end if;
         end;
      end loop;

      if Need_Spans and then not Spans.Is_Empty then
         --  Leftmost-longest/order arbitration for fixed-string spans.
         for I in Spans.First_Index .. Spans.Last_Index loop
            for J in I + 1 .. Spans.Last_Index loop
               declare
                  A : Match_Span := Spans.Element (I);
                  B : Match_Span := Spans.Element (J);
                  Swap : constant Boolean :=
                    B.First_Byte < A.First_Byte
                    or else
                      (B.First_Byte = A.First_Byte
                       and then B.Last_Byte_Exclusive > A.Last_Byte_Exclusive)
                    or else
                      (B.First_Byte = A.First_Byte
                       and then B.Last_Byte_Exclusive = A.Last_Byte_Exclusive
                       and then B.Pattern < A.Pattern);
               begin
                  if Swap then
                     Spans.Replace_Element (I, B);
                     Spans.Replace_Element (J, A);
                  end if;
               end;
            end loop;
         end loop;

         declare
            Filtered : Span_List;
            Last_End : Byte_Offset := 0;
            Have : Boolean := False;
         begin
            for S of Spans loop
               if (not Have or else S.First_Byte >= Last_End)
                 and then
                   (Filtered.Is_Empty
                    or else Filtered.Last_Element.First_Byte /= S.First_Byte
                    or else Filtered.Last_Element.Last_Byte_Exclusive /= S.Last_Byte_Exclusive)
               then
                  Filtered.Append (S);
                  Last_End := S.Last_Byte_Exclusive;
                  Have := True;
               end if;
            end loop;
            Spans := Filtered;
         end;
      end if;
   end Match_Record;
end Greplib.Patterns;
