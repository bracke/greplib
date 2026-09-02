pragma Ada_2022;

with Ada.Containers.Indefinite_Vectors;
with Ada.Strings.Unbounded;

package Greplib.Paths is
   --  @summary Owned path spelling values and ordered path lists.
   --  Public paths preserve caller spelling; internal filtering may use slash-normalized derived strings.
   --  Path is an owned value; Image returns the same spelling supplied through To_Path.
   type Path is private;

   --  Ordered list of Path values. Duplicate roots are retained and processed independently.
   type Path_List is private;

   --  Create an owned path value from caller-provided spelling without locale-dependent normalization.
   function To_Path (Image : String) return Path;

   --  Return the preserved caller spelling for reporting and source identity.
   function Image (Item : Path) return String;

   --  True when the preserved spelling is the empty string.
   function Is_Empty (Item : Path) return Boolean;

   --  Append Item to the end of List, preserving root declaration order.
   procedure Append (List : in out Path_List; Item : Path);

   --  Number of paths currently retained in List.
   function Length (List : Path_List) return Natural;

   --  Return the one-based path at Index. Constraint_Error is propagated for an invalid index.
   function Element (List : Path_List; Index : Positive) return Path;

   --  Remove all paths from List and release retained storage according to the container implementation.
   procedure Clear (List : in out Path_List);

private
   type Path is record
      Text : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   package Vectors is new Ada.Containers.Indefinite_Vectors (Positive, Path);
   type Path_List is record
      Items : Vectors.Vector;
   end record;
end Greplib.Paths;
