pragma Ada_2022;

with Greplib.Cancellation;
with Greplib.Diagnostics;
with Greplib.Events;
with Greplib.Options;
with Greplib.Path_Filters;
with Greplib.Paths;
with Greplib.Patterns;
with Greplib.Results;

package Greplib.Directories is
   --  @summary Directory-tree and path-root search entry points.
   --  Roots are processed in caller order; source sequence numbers are assigned in accepted traversal order. Concurrent
   --  search uses bounded source queues and per-source event channels while preserving caller-task callback delivery.
   --  Traversal diagnostics and partial per-source outcomes are retained structurally.

   --  Controls whether symbolic links are followed during root handling and recursive traversal.
   type Symbolic_Link_Policy is (Never_Follow, Follow_Explicit_Roots, Follow_All);

   --  Controls whether traversal diagnostics continue, stop the current root, or fail the whole search.
   type Traversal_Error_Policy is (Continue_After_Error, Fail_Root, Fail_Search);

   --  Directory traversal limits and policy flags. Counts and byte limits use wide checked greplib units.
   type Directory_Search_Options is record
      --  When False, directory roots still enumerate accepted direct regular-file children.
      Recursive : Boolean := False;
      --  When False, entries whose basename starts with "." are skipped before filters.
      Include_Hidden : Boolean := True;
      --  Maximum depth where explicit roots are depth zero and direct children are depth one.
      Maximum_Depth : Wide_Count := Default_Maximum_Traversal_Depth;
      --  Maximum preserved path spelling bytes accepted for traversal and search.
      Maximum_Path_Bytes : Byte_Count := Default_Maximum_Path_Bytes;
      --  Maximum entries collected from one directory for deterministic sorting.
      Maximum_Directory_Entries : Wide_Count := Default_Maximum_Directory_Entries;
      --  Sort each directory lexicographically by normalized code units before assigning sequences.
      Deterministic_Order : Boolean := True;
      --  Number of file-search workers. One uses the sequential reference path without worker tasks.
      Worker_Count : Wide_Count := 1;
      --  Maximum accepted file sources waiting to be searched.
      Maximum_Queued_Sources : Wide_Count := Default_Maximum_In_Flight_Sources;
      --  Maximum sources accepted but not fully delivered.
      Maximum_In_Flight_Sources : Wide_Count := Default_Maximum_In_Flight_Sources;
      --  Maximum queued events retained per source channel.
      Maximum_Queued_Events_Per_Source : Wide_Count := Default_Maximum_Queued_Events_Per_Source;
      --  Maximum queued event payload bytes retained per source channel.
      Maximum_Queued_Event_Bytes_Per_Source : Byte_Count := Default_Maximum_Queued_Event_Bytes_Per_Source;
      --  Zero means unlimited accepted sources; otherwise traversal stops after this many source assignments.
      Maximum_Sources : Wide_Count := 0;
      --  Symbolic-link policy for explicit roots and traversal-discovered entries.
      Symbolic_Links : Symbolic_Link_Policy := Follow_Explicit_Roots;
      --  Policy for recoverable traversal diagnostics.
      Traversal_Errors : Traversal_Error_Policy := Continue_After_Error;
      --  Search regular files. This is the default safe file-type policy.
      Search_Regular_Files : Boolean := True;
      --  Search special files only when explicitly enabled because they may block or have side effects.
      Search_Special_Files : Boolean := False;
      --  Skip descent across filesystem boundaries when supported by the platform adapter.
      Stay_On_Starting_Filesystem : Boolean := False;
   end record;

   --  Validate roots, pattern usability, search options, and directory options without opening files, enumerating
   --  directories, spawning worker tasks, or invoking callbacks. Returned diagnostics are independently detectable
   --  configuration errors where practical.
   function Validate
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Options : Directory_Search_Options) return Greplib.Diagnostics.Diagnostic_List;

   --  Validate the filtered directory-search configuration without opening files, enumerating directories, spawning
   --  worker tasks, or invoking callbacks. This overload also reports diagnostics retained by an unusable compiled
   --  filter set.
   function Validate
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Options : Directory_Search_Options) return Greplib.Diagnostics.Diagnostic_List;

   --  Search path roots without path filters and deliver events to Sink.
   --  Validation rejects an empty root list before opening files or enumerating directories.
   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);

   --  Search path roots without path filters and discard events. Returned summaries still include counts.
   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);

   --  Search path roots using a compiled filter set and deliver events to Sink.
   --  Filtered paths preserve original spelling for event reporting.
   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Sink : in out Greplib.Events.Event_Sink'Class;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);

   --  Search path roots using a compiled filter set and discard events.
   --  Directory pruning follows the compiled filter rule precedence documented in Greplib.Path_Filters.
   procedure Search_Paths
     (Roots : Greplib.Paths.Path_List;
      Patterns : Greplib.Patterns.Compiled_Pattern_Set;
      Filters : Greplib.Path_Filters.Compiled_Filter_Set;
      Search_Options : Greplib.Options.Search_Options;
      Directory_Options : Directory_Search_Options;
      Outcome : out Greplib.Results.Search_Outcome;
      Cancellation : Greplib.Cancellation.Cancellation_Token := Greplib.Cancellation.No_Cancellation);
private
   type Source_Acceptor is limited interface;
   procedure Accept_Source
     (Acceptor : in out Source_Acceptor;
      Name : String;
      Sequence : Source_Sequence) is abstract;
end Greplib.Directories;
