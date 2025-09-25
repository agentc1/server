with Sockets; use Sockets;
with Broadcast_Queue; use Broadcast_Queue;
with Telnet_Protocol; use Telnet_Protocol;
with Types; use Types;
with Ada.Real_Time; use Ada.Real_Time;

package body Client_Handler with SPARK_Mode => Off is

   task body Client_Task is
      My_ID : Client_ID;
      My_Socket : Socket_Type;
      My_Socket_ID : Natural;

      -- Buffers
      Recv_Buffer : Byte_Array (1 .. 1024);
      Send_Buffer : Byte_Array (1 .. 1024);
      Telnet_Buffer : Line_Buffer;

      -- Message handling
      Line : String (1 .. Max_Line_Length);
      Line_Len : Natural;
      Line_Complete : Boolean;

      Msg : Broadcast_Queue.Message_Type;
      Msg_Available : Boolean;

      Received : Natural;
      Send_Len : Natural;

      Running : Boolean := False;
      Next_Time : Time;
      Period : constant Time_Span := Milliseconds(100);  -- 100ms polling

   begin
      -- Wait for activation
      accept Start (ID : Client_ID; Socket_ID : Natural) do
         My_ID := ID;
         My_Socket_ID := Socket_ID;
         My_Socket := From_Natural(Socket_ID);
         Running := True;
      end Start;

      -- Send welcome message
      declare
         Welcome_Buf : Byte_Array (1 .. 100);
         Welcome_Len : Natural;
      begin
         Get_Welcome_Sequence (Welcome_Buf, Welcome_Len);
         Send_Data (My_Socket, Welcome_Buf, Welcome_Len);
      end;

      -- Reset position in broadcast queue for this client
      Broadcast_Queue.Queue.Reset_Client_Position (My_ID);

      -- Main client loop
      Next_Time := Clock;
      while Running loop
         -- Set next wakeup time
         Next_Time := Next_Time + Period;

         begin
            -- Check for incoming data from client
            Receive_Data (My_Socket, Recv_Buffer, Received);

            if Received > 0 then
               -- Process telnet protocol
               Process_Telnet_Input (
                  Recv_Buffer, Received,
                  Telnet_Buffer,
                  Line, Line_Len, Line_Complete);

               if Line_Complete and Line_Len > 0 then
                  -- Prepare message for broadcast
                  declare
                     Broadcast_Msg : Broadcast_Queue.Message_Type;
                     Username : Username_String;
                     Formatted : String (1 .. Max_Message_Length);
                     Format_Len : Natural := 0;
                  begin
                     -- Get username
                     Username := Client_Registry.Get_Username (My_ID);

                     -- Format as "User: message"
                     for I in Username'Range loop
                        exit when Username(I) = ' ';
                        if Format_Len < Max_Message_Length then
                           Format_Len := Format_Len + 1;
                           Formatted(Format_Len) := Username(I);
                        end if;
                     end loop;

                     -- Add separator
                     if Format_Len + 2 < Max_Message_Length then
                        Formatted(Format_Len + 1) := ':';
                        Formatted(Format_Len + 2) := ' ';
                        Format_Len := Format_Len + 2;
                     end if;

                     -- Add message
                     for I in 1 .. Line_Len loop
                        exit when Format_Len >= Max_Message_Length;
                        Format_Len := Format_Len + 1;
                        Formatted(Format_Len) := Line(I);
                     end loop;

                     -- Create broadcast message
                     Broadcast_Msg.Sender := My_ID;
                     for I in 1 .. Format_Len loop
                        if I <= Broadcast_Msg.Text'Length then
                           Broadcast_Msg.Text(I) := Formatted(I);
                        end if;
                     end loop;
                     Broadcast_Msg.Len := Format_Len;

                     -- Post to broadcast queue
                     Broadcast_Queue.Queue.Post_Message (Broadcast_Msg);
                  end;
               end if;
            elsif Received = 0 and not Is_Valid (My_Socket) then
               -- Connection closed
               Running := False;
            end if;

            -- Check for messages to send to client
            Broadcast_Queue.Queue.Get_Message_For_Client (My_ID, Msg, Msg_Available);

            if Msg_Available and Msg.Len > 0 then
               -- Convert message to telnet format and send
               declare
                  Text_To_Send : String (1 .. Msg.Len);
               begin
                  for I in 1 .. Msg.Len loop
                     Text_To_Send(I) := Msg.Text(I);
                  end loop;

                  Format_For_Telnet (Text_To_Send, Msg.Len, Send_Buffer, Send_Len);
                  Send_Data (My_Socket, Send_Buffer, Send_Len);
               end;
            end if;

         exception
            when others =>
               -- Connection error
               Running := False;
         end;

         -- Sleep until next period
         delay until Next_Time;
      end loop;

      -- Cleanup
      Close_Socket (My_Socket);
      Client_Registry.Release_Client (My_ID);

   exception
      when others =>
         -- Ensure cleanup on any error
         if Is_Valid (My_Socket) then
            Close_Socket (My_Socket);
         end if;
         Client_Registry.Release_Client (My_ID);
   end Client_Task;

end Client_Handler;