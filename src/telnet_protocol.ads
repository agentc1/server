with Types; use Types;

package Telnet_Protocol with SPARK_Mode => On is

   -- Telnet command bytes
   IAC   : constant Byte := 255;  -- Interpret As Command
   DONT  : constant Byte := 254;
   DO_CMD : constant Byte := 253;
   WONT  : constant Byte := 252;
   WILL  : constant Byte := 251;
   SB    : constant Byte := 250;  -- Subnegotiation begin
   SE    : constant Byte := 240;  -- Subnegotiation end

   -- Common telnet options
   ECHO_OPT : constant Byte := 1;
   SUPPRESS_GO_AHEAD : constant Byte := 3;

   -- Line terminators
   CR : constant Character := Character'Val(13);
   LF : constant Character := Character'Val(10);

   Max_Line_Length : constant := 200;

   type Telnet_State is (
      Data_State,      -- Normal data
      IAC_State,       -- Just saw IAC
      Command_State,   -- In command sequence
      Skip_State       -- Skipping option byte
   );

   type Line_Buffer is record
      Data  : String (1 .. Max_Line_Length);
      Len   : Natural := 0;
      State : Telnet_State := Data_State;
   end record;

   -- Process raw telnet input and extract complete lines
   procedure Process_Telnet_Input (
      Raw_Input : Byte_Array;
      Raw_Len   : Natural;
      Buffer    : in out Line_Buffer;
      Line_Out  : out String;
      Line_Len  : out Natural;
      Complete  : out Boolean)
   with Pre => Raw_Len <= Raw_Input'Length and
               Line_Out'Length >= Max_Line_Length,
        Post => Line_Len <= Line_Out'Length and
                Line_Len <= Max_Line_Length and
                Buffer.Len <= Max_Line_Length;

   -- Format a text message for telnet output (adds CR LF)
   procedure Format_For_Telnet (
      Text      : String;
      Text_Len  : Natural;
      Output    : out Byte_Array;
      Out_Len   : out Natural)
   with Pre => Text_Len <= Text'Length and
               Output'Length >= Text_Len + 2,
        Post => Out_Len <= Output'Length;

   -- Create initial telnet negotiation sequence
   procedure Get_Welcome_Sequence (
      Output  : out Byte_Array;
      Out_Len : out Natural)
   with Pre => Output'Length >= 30,
        Post => Out_Len <= Output'Length;

end Telnet_Protocol;