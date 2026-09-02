pragma Ada_2022;

with Greplib.Paths;

package Greplib.Sources is
   --  @summary Stable public source descriptors for memory, stream, and file sources.
   --  Directory search assigns source sequence numbers according to accepted traversal order.
   --  Kind of source represented by a Search operation or event.
   type Source_Kind is (Memory_Source, Stream_Source, File_Source);

   --  Owned source identity. Path spelling is stable and Sequence is one-based.
   --  The representation is private so future source metadata can be added without breaking callers.
   type Source_Descriptor is private;

   --  Return the source origin category.
   function Kind (Source : Source_Descriptor) return Source_Kind;

   --  Return the one-based source sequence assigned by root and traversal order.
   function Sequence (Source : Source_Descriptor) return Source_Sequence;

   --  Return the preserved source path or synthetic memory/stream identity.
   function Path (Source : Source_Descriptor) return Greplib.Paths.Path;

private
   type Source_Descriptor is record
      K : Source_Kind := Memory_Source;
      Seq : Source_Sequence := 1;
      P : Greplib.Paths.Path;
   end record;
end Greplib.Sources;
