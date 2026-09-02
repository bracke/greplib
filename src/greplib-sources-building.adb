pragma Ada_2022;

package body Greplib.Sources.Building is
   function Make
     (Authority : Greplib.Result_Authority.Token;
      Kind : Source_Kind;
      Sequence : Source_Sequence;
      Path : Greplib.Paths.Path) return Source_Descriptor is
      pragma Unreferenced (Authority);
   begin
      return (K => Kind, Seq => Sequence, P => Path);
   end Make;
end Greplib.Sources.Building;
