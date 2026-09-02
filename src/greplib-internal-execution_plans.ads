pragma Ada_2022;

with Greplib.Options;

package Greplib.Internal.Execution_Plans is
   --  @summary Internal execution-plan decisions derived from validated search options.
   --  This package is intentionally internal: callers configure Greplib.Options.Search_Options, while source
   --  processors use Search_Plan to make result-mode decisions without duplicating option predicates.

   type Plan_Kind is
     (Emit_Records_Plan, Count_Selected_Plan, Count_Matches_Plan, Names_With_Matches_Plan,
      Names_Without_Matches_Plan, Quiet_Plan, Binary_Match_Plan);

   type Search_Plan is private;

   function Compile
     (Options : Greplib.Options.Search_Options;
      Binary_Report_Active : Boolean := False) return Search_Plan;

   function Kind (Plan : Search_Plan) return Plan_Kind;
   function Retains_Record_Content (Plan : Search_Plan) return Boolean;
   function Needs_Context (Plan : Search_Plan) return Boolean;
   function Needs_Spans (Plan : Search_Plan) return Boolean;
   function Needs_Complete_Input (Plan : Search_Plan) return Boolean;
   function Stops_After_First_Selected (Plan : Search_Plan) return Boolean;
private
   type Search_Plan is record
      K : Plan_Kind := Emit_Records_Plan;
      Retain_Content : Boolean := True;
      Context : Boolean := False;
      Discover_Spans : Boolean := False;
      Complete_Input : Boolean := True;
      Stop_After_First : Boolean := False;
   end record;
end Greplib.Internal.Execution_Plans;
