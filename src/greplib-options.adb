pragma Ada_2022;

with Greplib.Diagnostics;
with Ada.Streams;

package body Greplib.Options is
   function Separator (Options : Search_Options) return Character is
   begin
      case Options.Separator_Kind is
         when LF => return ASCII.LF;
         when NUL => return Character'Val (0);
         when Custom => return Options.Custom_Separator;
      end case;
   end Separator;

   function Validate (Options : Search_Options) return Greplib.Diagnostics.Diagnostic_List is
      use Greplib.Diagnostics;
      Result : Diagnostic_List;
      Has_Context : constant Boolean := Options.Context.Before /= 0 or else Options.Context.After /= 0;
   begin
      if Options.Mode = Count_Matches and then Options.Invert_Match then
         Result.Append
           (Make (Configuration_Invalid_Option_Combination, Fatal_Error, "Count_Matches is invalid with inversion"));
      end if;

      if Has_Context
        and then Options.Mode /= Emit_Selected_Records
      then
         Result.Append
           (Make (Configuration_Invalid_Option_Combination, Fatal_Error, "context requires Emit_Selected_Records"));
      end if;

      if Has_Context and then Options.On_Binary = Report_Match_Without_Record then
         Result.Append
           (Make
              (Configuration_Invalid_Option_Combination,
               Fatal_Error,
               "binary match without record is invalid with context"));
      end if;

      if Options.On_Binary = Report_Match_Without_Record
        and then Options.Mode /= Emit_Selected_Records
      then
         Result.Append
           (Make
              (Configuration_Invalid_Option_Combination,
               Fatal_Error,
               "binary match without record requires Emit_Selected_Records"));
      end if;

      if Options.CR_Policy = Strip_Before_Line_Feed and then Options.Separator_Kind /= LF then
         Result.Append
           (Make (Configuration_Invalid_Option_Combination, Fatal_Error, "CR stripping requires LF separator"));
      end if;

      if Options.Maximum_Record_Size = 0 then
         Result.Append
           (Make (Configuration_Invalid_Option_Combination, Fatal_Error, "maximum record size must be positive"));
      end if;

      if Options.Maximum_Context_Buffer_Bytes = 0 then
         Result.Append
           (Make
              (Configuration_Invalid_Option_Combination,
               Fatal_Error,
               "maximum context buffer bytes must be positive"));
      end if;

      if Options.Read_Block_Size = 0 then
         Result.Append
           (Make (Configuration_Invalid_Option_Combination, Fatal_Error, "read block size must be positive"));
      elsif Options.Read_Block_Size > Byte_Count (Ada.Streams.Stream_Element_Offset'Last) then
         Result.Append
           (Make (Configuration_Invalid_Option_Combination, Fatal_Error, "read block size is too large"));
      end if;

      if Options.Maximum_Match_Spans_Per_Record = 0 then
         Result.Append
           (Make
              (Configuration_Invalid_Option_Combination,
               Fatal_Error,
               "maximum match spans per record must be positive"));
      end if;

      if Options.Worker_Count = 0 or else Options.Worker_Count > Default_Maximum_Worker_Count then
         Result.Append
           (Make (Configuration_Invalid_Option_Combination, Fatal_Error, "invalid worker count"));
      end if;

      return Result;
   end Validate;
end Greplib.Options;
