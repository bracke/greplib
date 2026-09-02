pragma Ada_2022;

with Greplib.Result_Authority;

package Greplib.Sources.Building is
   --  @summary Internal source descriptor construction API.
   --  Public callers can inspect Source_Descriptor values through Greplib.Sources accessors.

   --  Build an owned source descriptor.
   function Make
     (Authority : Greplib.Result_Authority.Token;
      Kind : Source_Kind;
      Sequence : Source_Sequence;
      Path : Greplib.Paths.Path) return Source_Descriptor;
end Greplib.Sources.Building;
