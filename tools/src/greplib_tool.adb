pragma Ada_2022;

with Ada.Command_Line;
with Ada.Containers.Indefinite_Vectors;
with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Tree_Checks;

with Tarlib;
with Tarlib.Entries;
with Tarlib.Errors;
with Tarlib.Files;
with Tarlib.Readers;
with Tarlib.Writers;

procedure Greplib_Tool is
   package U renames Ada.Strings.Unbounded;
   package String_Vectors is new Ada.Containers.Indefinite_Vectors (Positive, String);
   package PF renames Project_Tools.Files;
   package PP renames Project_Tools.Processes;
   package PR renames Project_Tools.Release_Checks;
   use type Ada.Containers.Count_Type;
   use type Tarlib.Byte_Count;
   use type Tarlib.Entries.Entry_Kind;
   use type Tarlib.Errors.Status_Code;

   Check : constant PR.Checker := PR.Create (".");

   procedure Usage is
   begin
      Ada.Text_IO.Put_Line
        ("usage: greplib_tool build|test-fast|test-full|test-stress|check-format|check-style|check-docs|" &
         "check-fixtures|check-metadata|check-clean-tree|check-package|verify|package|release-check|clean");
   end Usage;

   procedure Check_File (Path : String) is
   begin
      PR.Require_File (Check, Path);
   end Check_File;

   function Ends_With (Text : String; Suffix : String) return Boolean is
   begin
      return Text'Length >= Suffix'Length
        and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

   function Is_Prohibited_Automation (Path : String) return Boolean is
      Simple : constant String := Ada.Directories.Simple_Name (Path);
   begin
      return Ends_With (Simple, ".sh")
        or else Ends_With (Simple, ".bash")
        or else Ends_With (Simple, ".zsh")
        or else Ends_With (Simple, ".fish")
        or else Ends_With (Simple, ".py")
        or else Ends_With (Simple, ".pl")
        or else Ends_With (Simple, ".rb")
        or else Simple = "Makefile"
        or else Simple = "package.json";
   end Is_Prohibited_Automation;

   function Is_Build_Artifact (Path : String) return Boolean is
   begin
      return Ends_With (Path, ".ali")
        or else Ends_With (Path, ".o")
        or else Ends_With (Path, ".a")
        or else Ends_With (Path, ".so")
        or else Ends_With (Path, ".exe")
        or else Ends_With (Path, ".log");
   end Is_Build_Artifact;

   function Starts_With (Text : String; Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Release_Filesystem_Path (Path : String) return String is
   begin
      if Path = "alire.toml" then
         return "dist/release-alire.toml";
      elsif Path = "tests/alire.toml" then
         return "dist/release-tests-alire.toml";
      elsif Path = "tools/alire.toml" then
         return "dist/release-tools-alire.toml";
      else
         return Path;
      end if;
   end Release_Filesystem_Path;

   function Is_Internal_Spec (Path : String) return Boolean is
      Simple : constant String := Ada.Directories.Simple_Name (Path);
   begin
      return Ends_With (Simple, "greplib-internal.ads")
        or else Ends_With (Simple, "greplib-internal-filesystem.ads")
        or else Ends_With (Simple, "greplib-internal-filesystem_identity.ads")
        or else Ends_With (Simple, "greplib-internal-regexp_adapter.ads");
   end Is_Internal_Spec;

   procedure Sort (Items : in out String_Vectors.Vector) is
   begin
      if Items.Length < 2 then
         return;
      end if;

      for I in Items.First_Index .. Items.Last_Index loop
         for J in I + 1 .. Items.Last_Index loop
            if Items.Element (J) < Items.Element (I) then
               declare
                  Hold : constant String := Items.Element (I);
               begin
                  Items.Replace_Element (I, Items.Element (J));
                  Items.Replace_Element (J, Hold);
               end;
            end if;
         end loop;
      end loop;
   end Sort;

   procedure Run
     (Label : String;
      Dir : String;
      Program : String;
      Args : GNAT.OS_Lib.Argument_List) is
      Located : constant String :=
        (if Project_Tools.Files.File_Exists (Program) or else Project_Tools.Files.File_Exists (Dir & "/" & Program)
         then Program
         else PP.Locate_Command (Program));
   begin
      if Located = "" then
         PR.Fail ("required command not found: " & Program);
      end if;
      PP.Run (Label, Dir, Located, Args);
   end Run;

   procedure Require_Rg_No_Matches
     (Label : String;
      Pattern : String;
      Paths : GNAT.OS_Lib.Argument_List) is
      Args : GNAT.OS_Lib.Argument_List (1 .. Paths'Length + 2);
      Status : Integer;
   begin
      Args (1) := new String'("-n");
      Args (2) := new String'(Pattern);
      for I in Paths'Range loop
         Args (I - Paths'First + 3) := Paths (I);
      end loop;

      Status := PP.Run_Status (Label, ".", "rg", Args, Quiet => True);
      if Status = 0 then
         PR.Fail (Label & " found violations");
      elsif Status /= 1 then
         PR.Fail (Label & " could not run");
      end if;
   end Require_Rg_No_Matches;

   procedure Add_File (Files : in out String_Vectors.Vector; Path : String) is
   begin
      if PF.File_Exists (Path) then
         Files.Append (Path);
      end if;
   exception
      when others =>
         PR.Fail ("cannot classify: " & Path);
   end Add_File;

   procedure Add_Tree (Files : in out String_Vectors.Vector; Root : String) is
      Entries : constant PF.Path_List :=
        PF.List_Tree
          (Root,
           "*",
           [U.To_Unbounded_String ("obj"),
            U.To_Unbounded_String ("bin"),
            U.To_Unbounded_String ("lib"),
            U.To_Unbounded_String ("config"),
            U.To_Unbounded_String ("dist"),
            U.To_Unbounded_String ("generated"),
            U.To_Unbounded_String ("alire")]);
   begin
      if not PF.Directory_Exists (Root) then
         return;
      end if;

      for Path of Entries loop
         declare
            Text : constant String := U.To_String (Path);
         begin
            if not Is_Build_Artifact (Text) then
               Files.Append (Text);
            end if;
         end;
      end loop;
   exception
      when others =>
         PR.Fail ("cannot enumerate: " & Root);
   end Add_Tree;

   function Source_Files return String_Vectors.Vector is
      Files : String_Vectors.Vector;
   begin
      Add_File (Files, "alire.toml");
      Add_File (Files, "greplib.gpr");
      Add_File (Files, "README.md");
      Add_File (Files, "CHANGELOG.md");
      Add_File (Files, "LICENSE");
      Add_File (Files, ".gitignore");
      Add_Tree (Files, "src");
      Add_Tree (Files, "docs");
      Add_Tree (Files, "examples");
      Add_File (Files, "tests/alire.toml");
      Add_File (Files, "tests/greplib_tests.gpr");
      Add_Tree (Files, "tests/src");
      Add_Tree (Files, "tests/fixtures");
      Add_File (Files, "tools/alire.toml");
      Add_File (Files, "tools/greplib_tool.gpr");
      Add_Tree (Files, "tools/src");
      Sort (Files);
      return Files;
   end Source_Files;

   procedure Check_Packageable_Source (Files : String_Vectors.Vector) is
   begin
      for Path of Files loop
         if Is_Build_Artifact (Path) then
            PR.Fail ("release manifest contains build artifact: " & Path);
         elsif Is_Prohibited_Automation (Path) then
            PR.Fail ("release manifest contains prohibited automation: " & Path);
         end if;
      end loop;
   end Check_Packageable_Source;

   procedure Generate_Source_Manifest is
      Files : String_Vectors.Vector := Source_Files;
      Manifest : Ada.Text_IO.File_Type;
   begin
      Check_Packageable_Source (Files);
      if not PF.Directory_Exists ("dist") then
         Ada.Directories.Create_Directory ("dist");
      end if;

      Ada.Text_IO.Create (Manifest, Ada.Text_IO.Out_File, "dist/source-manifest.txt");
      Ada.Text_IO.Put_Line (Manifest, "greplib source manifest");
      Ada.Text_IO.Put_Line (Manifest, "format: deterministic relative paths");
      for Path of Files loop
         Ada.Text_IO.Put_Line (Manifest, Path);
      end loop;
      Ada.Text_IO.Close (Manifest);
      Ada.Text_IO.Put_Line ("wrote dist/source-manifest.txt");
   exception
      when others =>
         if Ada.Text_IO.Is_Open (Manifest) then
            Ada.Text_IO.Close (Manifest);
         end if;
         raise;
   end Generate_Source_Manifest;

   procedure Check_Source_Manifest is
      Files : constant String_Vectors.Vector := Source_Files;
      Manifest : Ada.Text_IO.File_Type;
      Line_Number : Natural := 0;
      Manifest_Files : String_Vectors.Vector;
   begin
      Check_Packageable_Source (Files);
      if Files.Is_Empty then
         PR.Fail ("release manifest would be empty");
      end if;
      Check_File ("dist/source-manifest.txt");
      Check_File ("dist/greplib-0.1.0-dev.tar");

      Ada.Text_IO.Open (Manifest, Ada.Text_IO.In_File, "dist/source-manifest.txt");
      while not Ada.Text_IO.End_Of_File (Manifest) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (Manifest);
         begin
            Line_Number := Line_Number + 1;
            if Line_Number = 1 and then Line /= "greplib source manifest" then
               PR.Fail ("source manifest header mismatch");
            elsif Line_Number = 2 and then Line /= "format: deterministic relative paths" then
               PR.Fail ("source manifest format line mismatch");
            elsif Line_Number > 2 then
               Manifest_Files.Append (Line);
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (Manifest);

      if Manifest_Files.Length /= Files.Length then
         PR.Fail ("source manifest entry count mismatch");
      end if;

      for Index in Files.First_Index .. Files.Last_Index loop
         if Manifest_Files.Element (Index) /= Files.Element (Index) then
            PR.Fail
              ("source manifest entry mismatch: expected "
               & Files.Element (Index)
               & " got "
               & Manifest_Files.Element (Index));
         end if;
      end loop;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (Manifest) then
            Ada.Text_IO.Close (Manifest);
         end if;
         raise;
   end Check_Source_Manifest;

   procedure Generate_Release_Alire_Manifest
     (Source_Path : String;
      Target_Path : String) is
      Source : Ada.Text_IO.File_Type;
      Target : Ada.Text_IO.File_Type;
      In_Pin_Section : Boolean := False;
      Lines_Written : Natural := 0;
   begin
      Ada.Text_IO.Open (Source, Ada.Text_IO.In_File, Source_Path);
      Ada.Text_IO.Create (Target, Ada.Text_IO.Out_File, Target_Path);

      while not Ada.Text_IO.End_Of_File (Source) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (Source);
            Starts_Table : constant Boolean := Starts_With (Line, "[");
            Starts_Array_Table : constant Boolean := Starts_With (Line, "[[");
         begin
            if Starts_Array_Table and then Line = "[[pins]]" then
               In_Pin_Section := True;
            elsif In_Pin_Section and then Starts_Table then
               In_Pin_Section := False;
            end if;

            if not In_Pin_Section then
               Ada.Text_IO.Put_Line (Target, Line);
               Lines_Written := Lines_Written + 1;
            end if;
         end;
      end loop;

      Ada.Text_IO.Close (Source);
      Ada.Text_IO.Close (Target);

      if Lines_Written = 0 then
         PR.Fail ("release manifest would be empty: " & Target_Path);
      end if;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (Source) then
            Ada.Text_IO.Close (Source);
         end if;
         if Ada.Text_IO.Is_Open (Target) then
            Ada.Text_IO.Close (Target);
         end if;
         raise;
   end Generate_Release_Alire_Manifest;

   procedure Generate_Release_Alire_Manifests is
   begin
      Generate_Release_Alire_Manifest ("alire.toml", "dist/release-alire.toml");
      Generate_Release_Alire_Manifest ("tests/alire.toml", "dist/release-tests-alire.toml");
      Generate_Release_Alire_Manifest ("tools/alire.toml", "dist/release-tools-alire.toml");
   end Generate_Release_Alire_Manifests;

   procedure Check_Release_Alire_Manifest is
   begin
      Check_File ("dist/release-alire.toml");
      Check_File ("dist/release-tests-alire.toml");
      Check_File ("dist/release-tools-alire.toml");
      PR.Require_Text (Check, "dist/release-alire.toml", "regexp = ""*""");
      PR.Require_Text (Check, "dist/release-tests-alire.toml", "project_tools = ""*""");
      PR.Require_Text (Check, "dist/release-tools-alire.toml", "tarlib = ""*""");
      Require_Rg_No_Matches
        ("release alire local pin check",
         "\[\[pins\]\]|\.\./|path[ ]*=",
         [new String'("dist/release-alire.toml"),
          new String'("dist/release-tests-alire.toml"),
          new String'("dist/release-tools-alire.toml")]);
   end Check_Release_Alire_Manifest;

   procedure Check_Tar_Archive is
      Files : constant String_Vectors.Vector := Source_Files;
      Source : aliased Tarlib.Files.File_Input_Source;
      Reader : Tarlib.Readers.Reader;
      Info : Tarlib.Readers.Entry_Info;
      Result : Tarlib.Errors.Status;
      Close_Result : Tarlib.Errors.Status;
      Has_Entry : Boolean;
      Entry_Count : Natural := 0;

      procedure Report_Status
        (Step : String;
         Status : Tarlib.Errors.Status) is
      begin
         PR.Fail ("tar " & Step & " failed: " & Tarlib.Errors.Status_Code'Image (Status.Code));
      end Report_Status;
   begin
      Tarlib.Files.Open_Read (Source, "dist/greplib-0.1.0-dev.tar", Result);
      if Result.Code /= Tarlib.Errors.Success then
         Report_Status ("open", Result);
         return;
      end if;

      Tarlib.Readers.Initialize (Reader, Source, Result);
      if Result.Code /= Tarlib.Errors.Success then
         Report_Status ("initialize reader", Result);
         Tarlib.Files.Close (Source, Close_Result);
         return;
      end if;

      loop
         Tarlib.Readers.Next_Entry (Reader, Info, Has_Entry, Result);
         if Result.Code /= Tarlib.Errors.Success then
            Report_Status ("read header", Result);
            exit;
         elsif not Has_Entry then
            exit;
         end if;

         Entry_Count := Entry_Count + 1;
         if Entry_Count > Natural (Files.Length) then
            PR.Fail ("tar archive contains extra entry: " & Tarlib.Readers.Path (Info));
         else
            declare
               Filesystem_Path : constant String := Files.Element (Entry_Count);
               Stored_Path : constant String := Tarlib.Readers.Path (Info);
               Archive_Path : constant String := "greplib/" & Filesystem_Path;
               Stored_Size : constant Tarlib.Byte_Count := Tarlib.Readers.Size (Info);
               Expected_Size : constant Tarlib.Byte_Count :=
                 Tarlib.Byte_Count (Ada.Directories.Size (Release_Filesystem_Path (Filesystem_Path)));
            begin
               if Is_Build_Artifact (Stored_Path)
                 or else Is_Prohibited_Automation (Stored_Path)
                 or else Starts_With (Stored_Path, "greplib/alire/")
                 or else Starts_With (Stored_Path, "greplib/dist/")
                 or else Starts_With (Stored_Path, "greplib/obj/")
                 or else Starts_With (Stored_Path, "greplib/bin/")
                 or else Starts_With (Stored_Path, "greplib/lib/")
               then
                  PR.Fail ("tar archive contains prohibited entry: " & Stored_Path);
               elsif Tarlib.Readers.Path (Info) /= Archive_Path then
                  PR.Fail
                    ("tar archive entry order mismatch: expected "
                     & Archive_Path
                     & " got "
                     & Tarlib.Readers.Path (Info));
               elsif Tarlib.Readers.Kind (Info) /= Tarlib.Entries.Regular_File then
                  PR.Fail ("tar archive entry is not a regular file: " & Tarlib.Readers.Path (Info));
               elsif Stored_Size /= Expected_Size then
                  PR.Fail ("tar archive entry size mismatch: " & Tarlib.Readers.Path (Info));
               end if;
            end;
         end if;

         Tarlib.Readers.Skip_Entry (Reader, Result);
         if Result.Code /= Tarlib.Errors.Success then
            Report_Status ("skip entry", Result);
            exit;
         end if;
      end loop;

      if Entry_Count /= Natural (Files.Length) then
         PR.Fail ("tar archive entry count mismatch");
      end if;

      Tarlib.Files.Close (Source, Result);
      if Result.Code /= Tarlib.Errors.Success then
         Report_Status ("close reader", Result);
      end if;
   exception
      when others =>
         Tarlib.Files.Close (Source, Close_Result);
         raise;
   end Check_Tar_Archive;

   procedure Write_Tar_Archive (Files : String_Vectors.Vector) is
      Sink : aliased Tarlib.Files.File_Output_Sink;
      Archive : Tarlib.Writers.Writer;
      Result : Tarlib.Errors.Status;
      Close_Result : Tarlib.Errors.Status;

      procedure Require_Success
        (Step : String;
         Status : Tarlib.Errors.Status) is
      begin
         if Status.Code /= Tarlib.Errors.Success then
            PR.Fail ("tar " & Step & " failed: " & Tarlib.Errors.Status_Code'Image (Status.Code));
         end if;
      end Require_Success;
   begin
      Check_Packageable_Source (Files);
      Tarlib.Files.Create_Write (Sink, "dist/greplib-0.1.0-dev.tar", Result);
      Require_Success ("create", Result);
      Tarlib.Writers.Initialize (Archive, Sink, Result);
      Require_Success ("initialize", Result);

      for Path of Files loop
         Tarlib.Files.Add_File (Archive, Release_Filesystem_Path (Path), "greplib/" & Path, Result);
         Require_Success ("add " & Path, Result);
      end loop;

      Tarlib.Writers.Finish (Archive, Result);
      Require_Success ("finish", Result);
      Tarlib.Files.Close (Sink, Result);
      Require_Success ("close", Result);
      Ada.Text_IO.Put_Line ("wrote dist/greplib-0.1.0-dev.tar");
   exception
      when others =>
         Tarlib.Files.Close (Sink, Close_Result);
         raise;
   end Write_Tar_Archive;

   procedure Generate_Package is
      Files : constant String_Vectors.Vector := Source_Files;
   begin
      if PF.Directory_Exists ("dist") then
         Ada.Directories.Delete_Tree ("dist");
      end if;
      if not PF.Directory_Exists ("dist") then
         Ada.Directories.Create_Directory ("dist");
      end if;
      Generate_Source_Manifest;
      Generate_Release_Alire_Manifests;
      Check_Release_Alire_Manifest;
      Write_Tar_Archive (Files);
   end Generate_Package;

   procedure Check_Style_And_Format is
      Errors : Natural := 0;
      Source_Paths : constant GNAT.OS_Lib.Argument_List :=
        [new String'("src"),
         new String'("tests/src"),
         new String'("examples"),
         new String'("tools/src"),
         new String'("tools/alire.toml"),
         new String'("tools/greplib_tool.gpr"),
         new String'("docs"),
         new String'("README.md"),
         new String'("CHANGELOG.md"),
         new String'("alire.toml"),
         new String'("greplib.gpr"),
         new String'("tests/alire.toml"),
         new String'("tests/greplib_tests.gpr"),
         new String'(".gitignore")];

      procedure Check_Source_Tree (Dir : String) is
      begin
         Project_Tools.Tree_Checks.Check_No_Forbidden_Tree_Artifacts
           (Errors,
            Dir,
            [U.To_Unbounded_String ("Makefile"), U.To_Unbounded_String ("package.json")],
            [U.To_Unbounded_String (".sh"),
             U.To_Unbounded_String (".bash"),
             U.To_Unbounded_String (".zsh"),
             U.To_Unbounded_String (".fish"),
             U.To_Unbounded_String (".py"),
             U.To_Unbounded_String (".pl"),
             U.To_Unbounded_String (".rb"),
             U.To_Unbounded_String (".ali"),
             U.To_Unbounded_String (".o"),
             U.To_Unbounded_String (".a"),
             U.To_Unbounded_String (".so"),
             U.To_Unbounded_String (".exe"),
             U.To_Unbounded_String (".log")],
            "source tree");
      end Check_Source_Tree;
   begin
      Require_Rg_No_Matches ("trailing whitespace or tab check", "\t| $", Source_Paths);
      Require_Rg_No_Matches ("120-character line check", "^.{121,}$", Source_Paths);
      Check_Source_Tree ("src");
      Check_Source_Tree ("tests/src");
      Check_Source_Tree ("tools/src");
      Check_Source_Tree ("docs");
      Check_Packageable_Source (Source_Files);
      if Errors /= 0 then
         PR.Fail ("style checks failed");
      end if;
   end Check_Style_And_Format;

   procedure Check_Docs is
      procedure Require_Default
        (Name : String;
         Ada_Value : String;
         Doc_Value : String) is
      begin
         PR.Require_Text (Check, "src/greplib.ads", Name & " : constant");
         PR.Require_Text (Check, "src/greplib.ads", Ada_Value);
         PR.Require_Text (Check, "docs/resource-limits.md", "`" & Name & "`: " & Doc_Value);
      end Require_Default;
   begin
      PR.Require_File (Check, "README.md");
      PR.Require_File (Check, "docs/quickstart.md");
      PR.Require_File (Check, "docs/api-overview.md");
      PR.Require_File (Check, "docs/architecture.md");
      PR.Require_File (Check, "docs/matching-semantics.md");
      PR.Require_File (Check, "docs/stream-semantics.md");
      PR.Require_File (Check, "docs/filesystem-search.md");
      PR.Require_File (Check, "docs/concurrency.md");
      PR.Require_File (Check, "docs/diagnostics.md");
      PR.Require_File (Check, "docs/resource-limits.md");
      PR.Require_File (Check, "docs/regexp-compatibility.md");
      PR.Require_File (Check, "docs/testing.md");
      PR.Require_File (Check, "docs/releasing.md");
      PR.Require_File (Check, "docs/ai-implementation-guide.md");
      PR.Require_Text (Check, "README.md", "regexp");
      PR.Require_Text (Check, "README.md", "Greplib.Patterns.Is_Usable");
      PR.Require_Text (Check, "README.md", "Greplib.Diagnostics.Debug_Image");
      PR.Require_Text (Check, "README.md", "Greplib.Results.Status");
      PR.Require_Text (Check, "README.md", "Greplib.Results.Selected_Record_Count");
      PR.Require_File (Check, "examples/readme_demo.adb");
      PR.Require_Text (Check, "examples/examples.gpr", "readme_demo.adb");
      PR.Require_Text (Check, "docs/api-overview.md", "Greplib.Events.Source_No");
      PR.Require_Text (Check, "docs/api-overview.md", "Greplib.Events.Source");
      PR.Require_Text (Check, "docs/api-overview.md", "Greplib.Sources.Kind");
      PR.Require_Text (Check, "docs/api-overview.md", "source sequence");
      PR.Require_Text (Check, "docs/api-overview.md", "Greplib.Results.Source_Summaries");
      PR.Require_Text (Check, "docs/api-overview.md", "binary classification");
      PR.Require_Text (Check, "docs/api-overview.md", "Greplib.Search.Validate");
      PR.Require_Text (Check, "docs/ai-implementation-guide.md", "Synthetic worker failure outcomes");
      PR.Require_Text (Check, "docs/ai-implementation-guide.md", "execution plans");
      PR.Require_Text (Check, "docs/matching-semantics.md", "Greplib.Patterns.Validate");
      PR.Require_Text (Check, "docs/resource-limits.md", "Source_Truncation");
      PR.Require_Text (Check, "docs/architecture.md", "Greplib.Internal.Filesystem");
      PR.Require_Text (Check, "docs/architecture.md", "Greplib.Internal.Execution_Plans");
      PR.Require_Text (Check, "docs/concurrency.md", "Maximum_Queued_Events_Per_Source");
      PR.Require_Text (Check, "docs/concurrency.md", "Maximum_Queued_Sources");
      PR.Require_Text (Check, "docs/concurrency.md", "bounded source queue");
      PR.Require_Text (Check, "docs/filesystem-search.md", "Stay_On_Starting_Filesystem");
      PR.Require_Text (Check, "docs/filesystem-search.md", "Greplib.Files.Validate");
      PR.Require_Text (Check, "docs/filesystem-search.md", "Greplib.Directories.Validate");
      PR.Require_Text (Check, "docs/filesystem-search.md", "Greplib.Path_Filters.Validate");
      PR.Require_Text (Check, "docs/filesystem-search.md", "Compiled_Filter_Set");
      PR.Require_Text (Check, "docs/filesystem-search.md", "unusable");
      PR.Require_Text (Check, "docs/filesystem-search.md", "traversal.filesystem_boundary_skipped");
      PR.Require_Text (Check, "docs/filesystem-search.md", "Filesystem_Boundaries_Skipped");
      PR.Require_Text (Check, "docs/filesystem-search.md", "Source_Changed_During_Search = True");
      PR.Require_Text (Check, "docs/filesystem-search.md", "device/inode identity");
      PR.Require_Text (Check, "docs/regexp-compatibility.md", "case-insensitive matching");
      PR.Require_Text (Check, "docs/regexp-compatibility.md", "whole-record matching");
      PR.Require_Text (Check, "docs/regexp-compatibility.md", "embedded NUL subjects");
      PR.Require_Text (Check, "docs/regexp-compatibility.md", "zero-length progress");
      PR.Require_Text (Check, "docs/regexp-compatibility.md", "empty pattern behavior");
      PR.Require_Text (Check, "docs/regexp-compatibility.md", "compiled expression copy behavior");
      PR.Require_Text (Check, "docs/regexp-compatibility.md", "read-only matching from Ada tasks");
      PR.Require_Text (Check, "docs/stream-semantics.md", "Maximum_Context_Buffer_Bytes");
      PR.Require_Text (Check, "docs/stream-semantics.md", "Greplib.Files.Validate");
      PR.Require_Text (Check, "docs/stream-semantics.md", "resource.context_buffer_exceeded");
      PR.Require_Text (Check, "docs/resource-limits.md", "event overhead estimate");
      PR.Require_Text (Check, "docs/resource-limits.md", "Collection_Truncation");
      PR.Require_Text (Check, "docs/resource-limits.md", "Greplib.Collected.Validate");
      PR.Require_Text (Check, "docs/resource-limits.md", "validation overloads");
      PR.Require_Text (Check, "docs/resource-limits.md", "unusable compiled path filters");
      PR.Require_Text (Check, "docs/resource-limits.md", "source summary reason");
      Require_Default ("Default_Read_Block_Size", "64 * 1024", "64 KiB");
      Require_Default ("Default_Initial_Record_Buffer", "4 * 1024", "4 KiB");
      Require_Default ("Default_Maximum_Record_Size", "16 * 1024 * 1024", "16 MiB");
      Require_Default ("Default_Maximum_Context_Buffer_Bytes", "8 * 1024 * 1024", "8 MiB");
      Require_Default ("Default_Maximum_Pattern_Count", "1024", "1024");
      Require_Default ("Default_Maximum_Total_Pattern_Bytes", "16 * 1024 * 1024", "16 MiB");
      Require_Default ("Default_Maximum_Match_Spans_Per_Record", "100_000", "100000");
      Require_Default ("Default_Maximum_Retained_Diagnostics", "1_000", "1000");
      Require_Default ("Default_Maximum_Collected_Records", "10_000", "10000");
      Require_Default ("Default_Maximum_Collected_Bytes", "64 * 1024 * 1024", "64 MiB");
      Require_Default ("Default_Maximum_Traversal_Depth", "1024", "1024");
      Require_Default ("Default_Maximum_Path_Bytes", "1024 * 1024", "1 MiB");
      Require_Default ("Default_Maximum_Directory_Entries", "1_000_000", "1000000");
      Require_Default ("Default_Maximum_Worker_Count", "256", "256");
      Require_Default ("Default_Maximum_In_Flight_Sources", "64", "64");
      Require_Default ("Default_Maximum_Queued_Events_Per_Source", "128", "128");
      Require_Default ("Default_Maximum_Queued_Event_Bytes_Per_Source", "32 * 1024 * 1024", "32 MiB");
      PR.Require_Text (Check, "docs/testing.md", "fake filesystem");
      PR.Require_Text (Check, "docs/testing.md", "--mode=fast|full|stress|release");
      PR.Require_Text (Check, "docs/testing.md", "--list-tests");
      PR.Require_Text (Check, "docs/releasing.md", "greplib-0.1.0-dev.tar");
      PR.Require_Text (Check, "docs/releasing.md", "Manifest validation checks");
      PR.Require_Text (Check, "docs/releasing.md", "exact deterministic order");
      PR.Require_Text (Check, "docs/releasing.md", "greplib_tool check-package");
      PR.Require_Text (Check, "docs/releasing.md", "greplib_tool check-clean-tree");
      PR.Require_Text (Check, "docs/releasing.md", "git status --porcelain");
      for Path of Source_Files loop
         if Ends_With (Path, ".ads") and then not Is_Internal_Spec (Path) then
            PR.Require_Text (Check, Path, "--");
         end if;
      end loop;
      PR.Require_Text (Check, "src/greplib.ads", "Zero-based byte offset");
      PR.Require_Text (Check, "src/greplib-byte_strings.ads", "safe to copy");
      PR.Require_Text (Check, "src/greplib-cancellation.ads", "monotonic and idempotent");
      PR.Require_Text (Check, "src/greplib-collected.ads", "finite collection limit");
      PR.Require_Text (Check, "src/greplib-collected.ads", "function Validate");
      PR.Require_Text (Check, "src/greplib-collected.ads", "function Validate_File");
      PR.Require_Text (Check, "src/greplib-collected.ads", "function Validate_Paths");
      PR.Require_Text (Check, "src/greplib-collected.ads", "unusable compiled filter set");
      PR.Require_Text (Check, "src/greplib-collected.ads", "without starting a search");
      PR.Require_Text (Check, "src/greplib-diagnostics.ads", "Stable identifier");
      PR.Require_Text (Check, "src/greplib-diagnostics.ads", "type Diagnostic is private");
      PR.Require_Text (Check, "src/greplib-diagnostics.ads", "type Diagnostic_List is tagged private");
      PR.Require_Text (Check, "src/greplib-diagnostics.ads", "function Has_Path");
      PR.Require_Text (Check, "src/greplib-diagnostics.ads", "function Numeric_Limit");
      PR.Require_Text (Check, "src/greplib-diagnostics.ads", "function Observed_Size");
      PR.Require_Text (Check, "src/greplib-directories.ads", "caller-task callback delivery");
      PR.Require_Text (Check, "src/greplib-directories.ads", "function Validate");
      PR.Require_Text (Check, "src/greplib-directories.ads", "Compiled_Filter_Set");
      PR.Require_Text (Check, "src/greplib-directories.ads", "unusable compiled");
      PR.Require_Text (Check, "src/greplib-directories.ads", "spawning worker tasks");
      PR.Require_Text (Check, "src/greplib-events.ads", "half-open logical record byte offsets");
      PR.Require_Text (Check, "src/greplib-events.ads", "type Search_Event is private");
      PR.Require_Text (Check, "src/greplib-events.ads", "safe to copy and retain");
      PR.Require_Text (Check, "src/greplib-events.ads", "worker tasks never invoke this interface");
      PR.Require_Text (Check, "src/greplib-events-building.ads", "Internal event construction API");
      PR.Require_Text (Check, "src/greplib-events-building.ads", "Greplib.Result_Authority.Token");
      Require_Rg_No_Matches
        ("public event constructor check", "function Make_", [new String'("src/greplib-events.ads")]);
      PR.Require_Text (Check, "src/greplib-files.ads", "function Validate");
      PR.Require_Text (Check, "src/greplib-files.ads", "without reading a stream");
      PR.Require_Text (Check, "src/greplib-options.ads", "Validation reports");
      PR.Require_Text (Check, "src/greplib-path_filters.ads", "function Validate");
      PR.Require_Text (Check, "src/greplib-path_filters.ads", "without starting traversal");
      PR.Require_Text (Check, "src/greplib-path_filters.ads", "last match wins");
      PR.Require_Text (Check, "src/greplib-paths.ads", "preserve caller spelling");
      PR.Require_Text (Check, "src/greplib-patterns.ads", "function Validate");
      PR.Require_Text (Check, "src/greplib-patterns.ads", "without returning a compiled matcher set");
      PR.Require_Text (Check, "src/greplib-patterns.ads", "atomic compilation");
      PR.Require_Text (Check, "src/greplib-results.ads", "Completeness");
      PR.Require_Text (Check, "src/greplib-results.ads", "type Search_Summary is private");
      PR.Require_Text (Check, "src/greplib-results.ads", "type Search_Outcome is private");
      PR.Require_Text (Check, "src/greplib-results.ads", "function Status");
      PR.Require_Text (Check, "src/greplib-results.ads", "function Selected_Record_Count");
      PR.Require_Text (Check, "src/greplib-result_authority.ads", "type Token is private");
      PR.Require_Text (Check, "src/greplib-results-editing.ads", "Internal mutation layer");
      PR.Require_Text (Check, "src/greplib-results-editing.ads", "Greplib.Result_Authority.Token");
      PR.Require_Text (Check, "src/greplib-search.ads", "function Validate");
      PR.Require_Text (Check, "src/greplib-search.ads", "without consuming input");
      PR.Require_Text (Check, "src/greplib-search.ads", "callbacks synchronously");
      PR.Require_Text (Check, "src/greplib-search.ads", "never retain dangling references");
      PR.Require_Text (Check, "src/greplib-files.ads", "never close it");
      PR.Require_Text (Check, "src/greplib-files.ads", "Callback exceptions are re-raised unchanged");
      PR.Require_Text (Check, "src/greplib-sources.ads", "one-based source sequence");
      PR.Require_Text (Check, "src/greplib-sources.ads", "type Source_Descriptor is private");
      PR.Require_Text (Check, "src/greplib-sources-building.ads", "Internal source descriptor construction API");
      PR.Require_Text (Check, "src/greplib-sources-building.ads", "Greplib.Result_Authority.Token");
      Require_Rg_No_Matches
        ("public source constructor check",
         "function Make",
         [new String'("src/greplib-sources.ads")]);
   end Check_Docs;

   procedure Check_Metadata is
   begin
      PR.Require_File (Check, "alire.toml");
      PR.Require_File (Check, "greplib.gpr");
      PR.Require_File (Check, "tests/alire.toml");
      PR.Require_File (Check, "tests/greplib_tests.gpr");
      PR.Require_File (Check, "tools/alire.toml");
      PR.Require_File (Check, "tools/greplib_tool.gpr");
      PR.Require_Text (Check, "alire.toml", "name = ""greplib""");
      PR.Require_Text (Check, "alire.toml", "regexp = ""*""");
      PR.Require_Text (Check, "greplib.gpr", "for Library_Interface use");
      Require_Rg_No_Matches
        ("library interface helper package check",
         "Greplib\.(Results\.Editing|Events\.Building|Sources\.Building|Result_Authority)",
         [new String'("greplib.gpr")]);
      PR.Require_Text (Check, "tests/alire.toml", "greplib = ""*""");
      PR.Require_Text (Check, "tests/alire.toml", "project_tools = ""*""");
      PR.Require_Text (Check, "tools/alire.toml", "project_tools = ""*""");
      PR.Require_Text (Check, "tools/alire.toml", "tarlib = ""*""");
      PR.Require_Text (Check, "LICENSE", "MIT License");
   end Check_Metadata;

   procedure Check_Clean_Tree is
      Output : PP.Unbounded_String;
      Status : Integer;
   begin
      if not PF.File_Exists (".git/HEAD") then
         Ada.Text_IO.Put_Line ("clean-tree check skipped: Git metadata is not available");
         return;
      elsif PP.Locate_Command ("git") = "" then
         PR.Fail ("clean-tree check requires git");
      end if;

      Status :=
        PP.Run_Status
          ("git clean-tree status",
           ".",
           "git",
           [new String'("status"), new String'("--porcelain")],
           Output,
           Quiet => True);

      if Status /= 0 then
         PR.Fail ("clean-tree check could not read git status");
      elsif U.Length (Output) /= 0 then
         PR.Fail ("release requires a clean git tree");
      end if;
   end Check_Clean_Tree;

   procedure Run_Build is
   begin
      Run ("build greplib", ".", "alr", [new String'("build")]);
   end Run_Build;

   procedure Run_Tests (Mode : String := "fast") is
   begin
      Run ("build greplib tests", "tests", "alr", [new String'("build")]);
      Run ("run greplib tests", "tests", "./bin/greplib_tests", [new String'("--mode=" & Mode)]);
   end Run_Tests;

   procedure Run_Examples is
   begin
      Run
        ("build examples",
         ".",
         "alr",
         [new String'("exec"),
          new String'("--"),
          new String'("gprbuild"),
          new String'("-p"),
          new String'("-P"),
          new String'("examples/examples.gpr")]);
   end Run_Examples;

   procedure Run_Tool_Build is
   begin
      Run ("build greplib tool", "tools", "alr", [new String'("build")]);
   end Run_Tool_Build;

   procedure Run_Verify is
   begin
      Check_Metadata;
      Check_Docs;
      Check_Style_And_Format;
      PR.Require_Directory (Check, "tests/fixtures");
      Ada.Text_IO.Put_Line ("verification checks completed");
   end Run_Verify;

   procedure Run_Check_Package is
   begin
      Check_Release_Alire_Manifest;
      Check_Source_Manifest;
      Check_Tar_Archive;
      Ada.Text_IO.Put_Line ("package checks completed");
   end Run_Check_Package;

   procedure Run_Release_Check is
   begin
      Check_Clean_Tree;
      Run_Build;
      Run_Tests ("release");
      Run_Examples;
      Run_Tool_Build;
      Check_Metadata;
      Check_Docs;
      Check_Style_And_Format;
      Generate_Package;
      Check_Source_Manifest;
      Check_Tar_Archive;
      Ada.Text_IO.Put_Line ("release checks completed");
   end Run_Release_Check;

   Command : constant String := (if Ada.Command_Line.Argument_Count = 0 then "" else Ada.Command_Line.Argument (1));
begin
   if Command = "" then
      Usage;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   elsif Command = "build" then
      Run_Build;
   elsif Command = "test-fast" then
      Run_Tests ("fast");
   elsif Command = "test-full" then
      Run_Tests ("full");
   elsif Command = "test-stress" then
      Run_Tests ("stress");
   elsif Command in "check-format" | "check-style" then
      Check_Style_And_Format;
   elsif Command = "check-docs" then
      Check_Docs;
   elsif Command = "check-fixtures" then
      PR.Require_Directory (Check, "tests/fixtures");
   elsif Command = "check-metadata" then
      Check_Metadata;
   elsif Command = "check-clean-tree" then
      Check_Clean_Tree;
   elsif Command = "check-package" then
      Run_Check_Package;
   elsif Command = "verify" then
      Run_Verify;
   elsif Command = "release-check" then
      Run_Release_Check;
   elsif Command = "package" then
      Generate_Package;
   elsif Command = "clean" then
      Run ("clean root", ".", "alr", [new String'("clean")]);
      Run ("clean tests", "tests", "alr", [new String'("clean")]);
      Run ("clean tools", "tools", "alr", [new String'("clean")]);
   else
      Usage;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Greplib_Tool;
