pragma Ada_2022;

package body Greplib.Sources is
   function Kind (Source : Source_Descriptor) return Source_Kind is (Source.K);

   function Sequence (Source : Source_Descriptor) return Source_Sequence is (Source.Seq);

   function Path (Source : Source_Descriptor) return Greplib.Paths.Path is (Source.P);
end Greplib.Sources;
