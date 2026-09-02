pragma Ada_2022;

with Ada.Containers.Indefinite_Vectors;
with Ada.Strings.Unbounded;
with Greplib.Diagnostics;

package Greplib.Path_Filters is
   --  @summary Compiled include/exclude filters for directory traversal paths.
   --  Regex filters compile through the internal regexp adapter; malformed filters leave no partial usable set.
   --  Action applied when a rule is the last matching rule.
   type Filter_Action is (Include, Exclude);

   --  Entry type to which a rule applies. Directory exclusions prune descendants in V1.
   type Filter_Target is (Any_Entry, Files_Only, Directories_Only);

   --  Path spelling basis used for matching. Relative paths are slash-normalized and root-relative.
   type Filter_Basis is (Base_Name, Relative_Path);

   --  Pattern language used by a rule. Regex syntax is the resolved regexp crate syntax.
   type Filter_Kind is (Exact_Name, Glob_Pattern, Regular_Expression);

   --  Owned filter declaration. Rules are evaluated in append order and the last match wins.
   type Filter_Rule is private;

   --  Ordered list of filter declarations. An empty list compiles to include-all behavior.
   type Filter_List is private;

   --  Atomically compiled filter set. Regex and translated glob matchers are hidden from public APIs.
   type Compiled_Filter_Set is private;

   --  Create a filter rule. Pattern is copied and interpreted according to Kind during Compile.
   function Rule
     (Action : Filter_Action;
      Target : Filter_Target;
      Basis : Filter_Basis;
      Kind : Filter_Kind;
      Pattern : String) return Filter_Rule;

   --  Append Item to List preserving declaration order.
   procedure Append (List : in out Filter_List; Item : Filter_Rule);

   --  Compile all rules atomically. Malformed globs or regexes make the returned set unusable.
   function Compile (List : Filter_List) return Compiled_Filter_Set;

   --  Validate all rules without starting traversal or evaluating entries. Regex validation uses the same regexp
   --  compilation path as Compile; malformed globs or regexes are reported as path_filter.invalid_pattern diagnostics.
   function Validate (List : Filter_List) return Greplib.Diagnostics.Diagnostic_List;

   --  True when filter compilation succeeded and Included may be called.
   function Is_Usable (Set : Compiled_Filter_Set) return Boolean;

   --  Return retained filter-compilation diagnostics.
   function Diagnostics (Set : Compiled_Filter_Set) return Greplib.Diagnostics.Diagnostic_List;

   --  Evaluate one traversal entry. Relative_Path must be slash-normalized and relative to the current root.
   function Included
     (Set : Compiled_Filter_Set;
      Base : String;
      Relative_Path : String;
      Is_Directory : Boolean) return Boolean;

private
   type Filter_Rule is record
      Action : Filter_Action;
      Target : Filter_Target;
      Basis : Filter_Basis;
      Kind : Filter_Kind;
      Pattern : Ada.Strings.Unbounded.Unbounded_String;
   end record;
   package Rule_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Filter_Rule);
   type Regex_Holder;
   type Regex_Holder_Access is access Regex_Holder;
   type Compiled_Rule is record
      Rule : Filter_Rule;
      Regex : Regex_Holder_Access := null;
   end record;
   package Compiled_Rule_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Compiled_Rule);
   type Filter_List is record
      Items : Rule_Vectors.Vector;
   end record;
   type Compiled_Filter_Set is record
      Usable : Boolean := True;
      Items : Compiled_Rule_Vectors.Vector;
      Diags : Greplib.Diagnostics.Diagnostic_List;
   end record;
end Greplib.Path_Filters;
