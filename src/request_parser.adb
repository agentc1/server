package body Request_Parser with SPARK_Mode => On is
   procedure Parse_Line (Line : in Str; R : out Parsed) is
      I : Positive := Line'First;
   begin
      R.M := Bad;
      R.Path := (others => ' ');
      R.Path_Len := 0;

      -- Detect method (minimal: GET, POST)
      if Line'Length >= 4 and then Line (I .. I + 2) = "GET" then
         R.M := Get;
         I := I + 3;
      elsif Line'Length >= 5 and then Line (I .. I + 3) = "POST" then
         R.M := Post;
         I := I + 4;
      else
         return;
      end if;

      -- Skip one space if present
      if I <= Line'Last and then Line (I) = ' ' then
         I := I + 1;
      end if;

      -- Copy path prefix until space or end, bounded by Max_Path
      while I <= Line'Last loop
         pragma Loop_Invariant (I in Line'Range or else I = Line'Last + 1);
         pragma Loop_Invariant (R.Path_Len <= Max_Path);
         pragma Loop_Variant   (Line'Last - I + 1);
         exit when Line (I) = ' ';
         exit when R.Path_Len = Max_Path;
         R.Path_Len := R.Path_Len + 1;
         R.Path (R.Path_Len) := Line (I);
         I := I + 1;
      end loop;
   end Parse_Line;
end Request_Parser;
