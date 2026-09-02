pragma Ada_2022;

with Ada.Containers;
with Ada.Strings.Unbounded;

package body Greplib.Diagnostics is
   package U renames Ada.Strings.Unbounded;

   function Identifier (Code : Diagnostic_Code) return String is
   begin
      return U.To_String (Code.Id);
   end Identifier;

   function Domain (Code : Diagnostic_Code) return Diagnostic_Domain is
   begin
      return Code.Area;
   end Domain;

   function Make
     (Code : Diagnostic_Code;
      Level : Severity;
      Message : String := "";
      Pattern : Pattern_Index := Pattern_Index'First;
      Offset : Byte_Offset := 0;
      Path : String := "";
      Filesystem_Operation : String := "";
      Has_Record : Boolean := False;
      Record_No : Record_Number := Record_Number'First;
      Has_Native_Error : Boolean := False;
      Native_Error : Integer := 0;
      Exception_Name : String := "";
      Exception_Message : String := "";
      Has_Numeric_Limit : Boolean := False;
      Numeric_Limit : Wide_Count := 0;
      Has_Observed_Size : Boolean := False;
      Observed_Size : Wide_Count := 0) return Diagnostic is
   begin
      return
        (Code_Id => Code.Id,
         Code_Area => Code.Area,
         S => Level,
         Text => U.To_Unbounded_String (Message),
         Pattern => Pattern,
         Offset => Offset,
         Path_Text => U.To_Unbounded_String (Path),
         Operation_Text => U.To_Unbounded_String (Filesystem_Operation),
         Record_Set => Has_Record,
         Record_Number_Value => Record_No,
         Native_Error_Set => Has_Native_Error,
         Native_Error_Code => Native_Error,
         Exception_Name_Text => U.To_Unbounded_String (Exception_Name),
         Exception_Message_Text => U.To_Unbounded_String (Exception_Message),
         Numeric_Limit_Set => Has_Numeric_Limit,
         Numeric_Limit_Value => Numeric_Limit,
         Observed_Size_Set => Has_Observed_Size,
         Observed_Size_Value => Observed_Size);
   end Make;

   function Code (Item : Diagnostic) return Diagnostic_Code is
      ((Id => Item.Code_Id, Area => Item.Code_Area));
   function Level (Item : Diagnostic) return Severity is (Item.S);
   function Message (Item : Diagnostic) return String is (U.To_String (Item.Text));
   function Has_Path (Item : Diagnostic) return Boolean is (U.Length (Item.Path_Text) /= 0);
   function Path (Item : Diagnostic) return String is (U.To_String (Item.Path_Text));
   function Has_Filesystem_Operation (Item : Diagnostic) return Boolean is
      (U.Length (Item.Operation_Text) /= 0);
   function Filesystem_Operation (Item : Diagnostic) return String is (U.To_String (Item.Operation_Text));
   function Has_Record_Number (Item : Diagnostic) return Boolean is (Item.Record_Set);
   function Record_No (Item : Diagnostic) return Record_Number is (Item.Record_Number_Value);
   function Has_Native_Error (Item : Diagnostic) return Boolean is (Item.Native_Error_Set);
   function Native_Error (Item : Diagnostic) return Integer is (Item.Native_Error_Code);
   function Has_Exception_Name (Item : Diagnostic) return Boolean is
      (U.Length (Item.Exception_Name_Text) /= 0);
   function Exception_Name (Item : Diagnostic) return String is (U.To_String (Item.Exception_Name_Text));
   function Has_Exception_Message (Item : Diagnostic) return Boolean is
      (U.Length (Item.Exception_Message_Text) /= 0);
   function Exception_Message (Item : Diagnostic) return String is
      (U.To_String (Item.Exception_Message_Text));
   function Has_Numeric_Limit (Item : Diagnostic) return Boolean is (Item.Numeric_Limit_Set);
   function Numeric_Limit (Item : Diagnostic) return Wide_Count is (Item.Numeric_Limit_Value);
   function Has_Observed_Size (Item : Diagnostic) return Boolean is (Item.Observed_Size_Set);
   function Observed_Size (Item : Diagnostic) return Wide_Count is (Item.Observed_Size_Value);

   function Debug_Image (Item : Diagnostic) return String is
      Result : U.Unbounded_String := Item.Code_Id;
   begin
      U.Append (Result, ": ");
      U.Append (Result, Item.Text);
      if Has_Path (Item) then
         U.Append (Result, " path=" & Path (Item));
      end if;
      if Has_Filesystem_Operation (Item) then
         U.Append (Result, " op=" & Filesystem_Operation (Item));
      end if;
      if Has_Record_Number (Item) then
         U.Append (Result, " record=" & Record_Number'Image (Record_No (Item)));
      end if;
      if Has_Native_Error (Item) then
         U.Append (Result, " native=" & Integer'Image (Native_Error (Item)));
      end if;
      if Has_Exception_Name (Item) then
         U.Append (Result, " exception=" & Exception_Name (Item));
      end if;
      if Has_Numeric_Limit (Item) then
         U.Append (Result, " limit=" & Wide_Count'Image (Numeric_Limit (Item)));
      end if;
      if Has_Observed_Size (Item) then
         U.Append (Result, " observed=" & Wide_Count'Image (Observed_Size (Item)));
      end if;
      return U.To_String (Result);
   end Debug_Image;

   procedure Append (List : in out Diagnostic_List; Item : Diagnostic) is
   begin
      List.Items.Append (Item);
   end Append;

   function Length (List : Diagnostic_List) return Ada.Containers.Count_Type is (List.Items.Length);

   function Is_Empty (List : Diagnostic_List) return Boolean is (List.Items.Is_Empty);

   function Element (List : Diagnostic_List; Index : Positive) return Diagnostic is
      (List.Items.Element (Index));

   procedure Clear (List : in out Diagnostic_List) is
   begin
      List.Items.Clear;
   end Clear;
end Greplib.Diagnostics;
