pragma Ada_2022;

with Ada.Containers.Indefinite_Vectors;
with Ada.Strings.Unbounded;
with Greplib.Diagnostics;
with Greplib.Events;

package Greplib.Patterns is
   --  @summary Pattern definitions, atomic compilation, and record-local matching.
   --  Public APIs never expose regexp dependency types; pattern indexes remain declaration-stable from one.
   --  Pattern declaration kind. Regular expressions use the Alire regexp dependency through an adapter.
   type Pattern_Kind is (Regular_Expression, Fixed_String);

   --  Owned pattern declaration. Duplicate declarations are valid and retain separate pattern indexes.
   type Pattern_Definition is private;

   --  Ordered pattern declaration list. Pattern indexes are one-based list positions.
   type Pattern_List is private;

   --  Immutable compilation-time options. Search-time options never mutate compiled matcher behavior.
   type Compilation_Options is record
      --  Fixed strings use ASCII-only A-Z folding; regex support depends on regexp capabilities.
      Case_Insensitive : Boolean := False;
      --  Require every accepted candidate to cover the whole logical record.
      Whole_Record : Boolean := False;
      --  Require ASCII word boundaries around every non-empty accepted candidate.
      Whole_Word : Boolean := False;
      --  Maximum number of declarations accepted during compilation.
      Maximum_Pattern_Count : Wide_Count := Default_Maximum_Pattern_Count;
      --  Maximum total pattern text bytes accepted during compilation.
      Maximum_Total_Pattern_Bytes : Byte_Count := Default_Maximum_Total_Pattern_Bytes;
   end record;

   --  Limited compiled matcher set. It is usable only when atomic compilation succeeds.
   type Compiled_Pattern_Set is private;

   --  Create a regular-expression declaration. The syntax is exactly the resolved regexp crate syntax.
   function Regular_Expression_Pattern (Expression : String) return Pattern_Definition;

   --  Create a fixed-string declaration. Empty fixed strings match every record.
   function Fixed_String_Pattern (Text : String) return Pattern_Definition;

   --  Append Pattern to List, assigning the next one-based declaration index.
   procedure Append (List : in out Pattern_List; Pattern : Pattern_Definition);

   --  Return the number of declarations in List.
   function Length (List : Pattern_List) return Natural;

   --  Return the declaration kind.
   function Kind (Pattern : Pattern_Definition) return Pattern_Kind;

   --  Return the owned pattern text as supplied by the constructor.
   function Text (Pattern : Pattern_Definition) return String;

   --  Compile all declarations atomically. On failure, the returned set is unusable and carries diagnostics.
   function Compile
     (Patterns : Pattern_List;
      Options : Compilation_Options := (others => <>)) return Compiled_Pattern_Set;

   --  Validate all declarations and compilation options without returning a compiled matcher set. Regex validation
   --  uses the same regexp adapter path as Compile, and diagnostics reference original one-based pattern indexes.
   function Validate
     (Patterns : Pattern_List;
      Options : Compilation_Options := (others => <>)) return Greplib.Diagnostics.Diagnostic_List;

   --  True only when compilation succeeded and the set can be used for searching.
   function Is_Usable (Set : Compiled_Pattern_Set) return Boolean;

   --  Return retained compilation diagnostics. Diagnostics reference original pattern indexes where applicable.
   function Diagnostics (Set : Compiled_Pattern_Set) return Greplib.Diagnostics.Diagnostic_List;

   --  Return the number of compiled declarations in the set.
   function Count (Set : Compiled_Pattern_Set) return Natural;

   --  Return immutable compilation options captured by the set.
   function Options (Set : Compiled_Pattern_Set) return Compilation_Options;

   --  Match one logical record. Spans are non-overlapping and arbitrated leftmost-longest, then pattern index.
   procedure Match_Record
     (Set : Compiled_Pattern_Set;
      Subject : String;
      Need_Spans : Boolean;
      Positive : out Boolean;
      Spans : out Greplib.Events.Span_List;
      Spans_Complete : out Boolean);

private
   type Pattern_Definition is record
      K : Pattern_Kind;
      T : Ada.Strings.Unbounded.Unbounded_String;
   end record;
   package Definition_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Pattern_Definition);
   type Pattern_List is record
      Items : Definition_Vectors.Vector;
   end record;

   type Compiled_Entry;
   type Compiled_Entry_Access is access Compiled_Entry;
   package Compiled_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Compiled_Entry_Access);
   type Compiled_Pattern_Set is record
      Usable : Boolean := False;
      Opts : Compilation_Options;
      Items : Compiled_Vectors.Vector;
      Diags : Greplib.Diagnostics.Diagnostic_List;
   end record;
end Greplib.Patterns;
