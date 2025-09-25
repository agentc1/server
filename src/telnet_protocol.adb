with Interfaces; use Interfaces;

package body Telnet_Protocol with SPARK_Mode => On is

   procedure Process_Telnet_Input (
      Raw_Input : Byte_Array;
      Raw_Len   : Natural;
      Buffer    : in out Line_Buffer;
      Line_Out  : out String;
      Line_Len  : out Natural;
      Complete  : out Boolean) is
      B : Byte;
      C : Character;
   begin
      Line_Out := (others => ' ');
      Line_Len := 0;
      Complete := False;

      for I in Raw_Input'First .. Raw_Input'First + Raw_Len - 1 loop
         exit when I > Raw_Input'Last;
         B := Raw_Input(I);

         case Buffer.State is
            when Data_State =>
               if B = IAC then
                  Buffer.State := IAC_State;
               else
                  C := Character'Val(B);
                  -- Check for line terminator
                  if C = CR or C = LF then
                     if Buffer.Len > 0 then
                        -- Complete line found
                        for J in 1 .. Buffer.Len loop
                           if J <= Line_Out'Length then
                              Line_Out(J) := Buffer.Data(J);
                           end if;
                        end loop;
                        Line_Len := Buffer.Len;
                        Buffer.Len := 0;
                        Complete := True;
                        return;  -- Return first complete line
                     end if;
                  elsif B >= 32 and B < 127 then
                     -- Printable ASCII character
                     if Buffer.Len < Max_Line_Length then
                        Buffer.Len := Buffer.Len + 1;
                        Buffer.Data(Buffer.Len) := C;
                     end if;
                  end if;
               end if;

            when IAC_State =>
               if B = IAC then
                  -- Double IAC means literal 255
                  if Buffer.Len < Max_Line_Length then
                     Buffer.Len := Buffer.Len + 1;
                     Buffer.Data(Buffer.Len) := Character'Val(255);
                  end if;
                  Buffer.State := Data_State;
               elsif B = DO_CMD or B = DONT or B = WILL or B = WONT then
                  Buffer.State := Command_State;
               elsif B = SB then
                  Buffer.State := Skip_State;  -- Skip subnegotiation
               else
                  Buffer.State := Data_State;  -- Unknown command, ignore
               end if;

            when Command_State =>
               -- Skip option byte and return to data
               Buffer.State := Data_State;

            when Skip_State =>
               -- Skip until we see IAC SE
               if B = SE then
                  Buffer.State := Data_State;
               elsif B = IAC then
                  Buffer.State := IAC_State;
               end if;
         end case;
      end loop;
   end Process_Telnet_Input;

   procedure Format_For_Telnet (
      Text      : String;
      Text_Len  : Natural;
      Output    : out Byte_Array;
      Out_Len   : out Natural) is
      Pos : Natural;
   begin
      Out_Len := 0;
      Pos := Output'First;

      -- Copy text
      for I in 1 .. Text_Len loop
         exit when I > Text'Length;
         exit when Pos > Output'Last;

         -- Escape IAC bytes
         if Character'Pos(Text(I)) = 255 then
            if Pos + 1 <= Output'Last then
               Output(Pos) := IAC;
               Output(Pos + 1) := IAC;
               Pos := Pos + 2;
               Out_Len := Out_Len + 2;
            end if;
         else
            Output(Pos) := Byte(Character'Pos(Text(I)));
            Pos := Pos + 1;
            Out_Len := Out_Len + 1;
         end if;
      end loop;

      -- Add CR LF
      if Pos + 1 <= Output'Last then
         Output(Pos) := Byte(Character'Pos(CR));
         Output(Pos + 1) := Byte(Character'Pos(LF));
         Out_Len := Out_Len + 2;
      end if;
   end Format_For_Telnet;

   procedure Get_Welcome_Sequence (
      Output  : out Byte_Array;
      Out_Len : out Natural) is
      Welcome : constant String := "Welcome to Telnet Broadcast Server";
      Pos : Natural;
   begin
      Out_Len := 0;
      Pos := Output'First;

      -- Send telnet negotiation: WILL ECHO, WILL SUPPRESS_GO_AHEAD
      if Pos + 5 <= Output'Last then
         Output(Pos) := IAC;
         Output(Pos + 1) := WILL;
         Output(Pos + 2) := ECHO_OPT;
         Output(Pos + 3) := IAC;
         Output(Pos + 4) := WILL;
         Output(Pos + 5) := SUPPRESS_GO_AHEAD;
         Pos := Pos + 6;
         Out_Len := 6;
      end if;

      -- Add welcome message
      for I in Welcome'Range loop
         exit when Pos > Output'Last;
         Output(Pos) := Byte(Character'Pos(Welcome(I)));
         Pos := Pos + 1;
         Out_Len := Out_Len + 1;
      end loop;

      -- Add CR LF
      if Pos + 1 <= Output'Last then
         Output(Pos) := Byte(Character'Pos(CR));
         Output(Pos + 1) := Byte(Character'Pos(LF));
         Out_Len := Out_Len + 2;
      end if;
   end Get_Welcome_Sequence;

end Telnet_Protocol;