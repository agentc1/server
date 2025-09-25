package Request_Parser with SPARK_Mode => On is
   Max_Path : constant := 256;

   subtype Str is String (Positive range <>);

   type Method is (Get, Post, Bad);

   type Parsed is record
      M        : Method := Bad;
      Path     : String (1 .. Max_Path) := (others => ' ');
      Path_Len : Natural := 0;
   end record
   with Predicate => Path_Len <= Max_Path;

   procedure Parse_Line (Line : in Str; R : out Parsed)
     with Pre  => Line'Length >= 3,
          Post => R.Path_Len <= Max_Path;
end Request_Parser;
