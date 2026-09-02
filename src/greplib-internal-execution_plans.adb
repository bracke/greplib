pragma Ada_2022;

package body Greplib.Internal.Execution_Plans is
   use type Greplib.Options.Result_Mode;
   use type Greplib.Options.Span_Requirement;
   use type Greplib.Wide_Count;

   function Compile
     (Options : Greplib.Options.Search_Options;
      Binary_Report_Active : Boolean := False) return Search_Plan
   is
      Result : Search_Plan;
   begin
      if Binary_Report_Active then
         Result.K := Binary_Match_Plan;
      else
         case Options.Mode is
            when Greplib.Options.Emit_Selected_Records =>
               Result.K := Emit_Records_Plan;
            when Greplib.Options.Count_Selected_Records =>
               Result.K := Count_Selected_Plan;
            when Greplib.Options.Count_Matches =>
               Result.K := Count_Matches_Plan;
            when Greplib.Options.Source_Names_With_Matches =>
               Result.K := Names_With_Matches_Plan;
            when Greplib.Options.Source_Names_Without_Matches =>
               Result.K := Names_Without_Matches_Plan;
            when Greplib.Options.Quiet =>
               Result.K := Quiet_Plan;
         end case;
      end if;

      Result.Context :=
        Result.K = Emit_Records_Plan
        and then (Options.Context.Before /= 0 or else Options.Context.After /= 0);
      Result.Discover_Spans :=
        Options.Spans /= Greplib.Options.No_Spans or else Result.K = Count_Matches_Plan;
      Result.Retain_Content := Result.K = Emit_Records_Plan;
      Result.Stop_After_First := Result.K in Names_With_Matches_Plan | Quiet_Plan | Binary_Match_Plan;
      Result.Complete_Input := Result.K not in Names_With_Matches_Plan | Quiet_Plan | Binary_Match_Plan;
      return Result;
   end Compile;

   function Kind (Plan : Search_Plan) return Plan_Kind is (Plan.K);

   function Retains_Record_Content (Plan : Search_Plan) return Boolean is (Plan.Retain_Content);

   function Needs_Context (Plan : Search_Plan) return Boolean is (Plan.Context);

   function Needs_Spans (Plan : Search_Plan) return Boolean is (Plan.Discover_Spans);

   function Needs_Complete_Input (Plan : Search_Plan) return Boolean is (Plan.Complete_Input);

   function Stops_After_First_Selected (Plan : Search_Plan) return Boolean is (Plan.Stop_After_First);
end Greplib.Internal.Execution_Plans;
