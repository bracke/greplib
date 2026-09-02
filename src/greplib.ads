pragma Ada_2022;

package Greplib is
   --  @summary Root numeric types and canonical default limits for greplib.
   --  Offsets and counts use wide checked integer subtypes. Byte offsets are zero-based and refer to original input
   --  bytes unless a child package explicitly documents logical record content offsets.
   pragma Pure;

   --  Wide nonnegative counter type used as the base for public offsets, sizes, and counters.
   type Wide_Count is range 0 .. 2 ** 63 - 1;

   --  Zero-based byte offset. Source offsets use original input bytes; match spans use logical record bytes.
   subtype Byte_Offset is Wide_Count;

   --  Count of bytes. Accessor documentation states whether the count is original or logical content.
   subtype Byte_Count is Wide_Count;

   --  One-based physical record number assigned by the common record reader.
   subtype Record_Number is Wide_Count range 1 .. Wide_Count'Last;

   --  One-based source sequence assigned by caller root order and deterministic traversal order.
   subtype Source_Sequence is Wide_Count range 1 .. Wide_Count'Last;

   --  One-based pattern declaration index. Duplicate patterns retain distinct indexes.
   subtype Pattern_Index is Wide_Count range 1 .. Wide_Count'Last;

   --  Default sequential stream read size in bytes.
   Default_Read_Block_Size : constant Byte_Count := 64 * 1024;
   --  Default initial retained record-buffer capacity in bytes.
   Default_Initial_Record_Buffer : constant Byte_Count := 4 * 1024;
   --  Default maximum logical record size in bytes before oversized-record policy is applied.
   Default_Maximum_Record_Size : constant Byte_Count := 16 * 1024 * 1024;
   --  Default maximum retained before-context bytes for one operation.
   Default_Maximum_Context_Buffer_Bytes : constant Byte_Count := 8 * 1024 * 1024;
   --  Default maximum number of declarations accepted at pattern compilation.
   Default_Maximum_Pattern_Count : constant Wide_Count := 1024;
   --  Default maximum total pattern text bytes accepted at pattern compilation.
   Default_Maximum_Total_Pattern_Bytes : constant Byte_Count := 16 * 1024 * 1024;
   --  Default maximum emitted non-overlapping match spans for one record.
   Default_Maximum_Match_Spans_Per_Record : constant Wide_Count := 100_000;
   --  Default maximum diagnostics retained in an outcome while total diagnostic counts continue.
   Default_Maximum_Retained_Diagnostics : constant Wide_Count := 1_000;
   --  Default maximum records retained by collected-result helpers.
   Default_Maximum_Collected_Records : constant Wide_Count := 10_000;
   --  Default maximum content bytes retained by collected-result helpers.
   Default_Maximum_Collected_Bytes : constant Byte_Count := 64 * 1024 * 1024;
   --  Default maximum recursive traversal depth, where an explicit root has depth zero.
   Default_Maximum_Traversal_Depth : constant Wide_Count := 1024;
   --  Default maximum path spelling bytes accepted by public and traversal path handling.
   Default_Maximum_Path_Bytes : constant Byte_Count := 1024 * 1024;
   --  Default maximum directory entries collected for deterministic sorting.
   Default_Maximum_Directory_Entries : constant Wide_Count := 1_000_000;
   --  Default maximum requested Ada worker tasks for concurrent path search.
   Default_Maximum_Worker_Count : constant Wide_Count := 256;
   --  Default maximum accepted sources whose results are not fully delivered yet.
   Default_Maximum_In_Flight_Sources : constant Wide_Count := 64;
   --  Default maximum queued events retained per source channel.
   Default_Maximum_Queued_Events_Per_Source : constant Wide_Count := 128;
   --  Default maximum queued event payload bytes retained per source channel.
   Default_Maximum_Queued_Event_Bytes_Per_Source : constant Byte_Count := 32 * 1024 * 1024;
end Greplib;
