package body Broadcast_Queue with SPARK_Mode => Off is

   protected body Queue is

      entry Post_Message (Msg : Message_Type) when Not_Full is
         New_Msg : Message_Type := Msg;
      begin
         -- Add sequence number
         New_Msg.Seq_Num := Next_Seq;
         Next_Seq := Next_Seq + 1;

         -- Store message in circular buffer
         Ring(Head) := New_Msg;

         -- Update head position
         if Head = Message_Buffer_Size then
            Head := 1;
         else
            Head := Head + 1;
         end if;

         -- Update count and full status
         if Count < Message_Buffer_Size then
            Count := Count + 1;
         else
            -- Buffer full, advance tail (lose oldest message)
            if Tail = Message_Buffer_Size then
               Tail := 1;
            else
               Tail := Tail + 1;
            end if;
         end if;

         -- Update full flag
         Not_Full := Count < Message_Buffer_Size;
      end Post_Message;

      procedure Get_Message_For_Client (
         Client    : Client_ID;
         Msg       : out Message_Type;
         Available : out Boolean) is
         Client_Pos : Natural;
         Read_Pos : Positive;
      begin
         Available := False;
         Msg := (Sender => No_Client,
                Text => (others => ' '),
                Len => 0,
                Seq_Num => 0);

         if Client = No_Client or Client > Max_Clients then
            return;
         end if;

         Client_Pos := Client_Positions(Client);

         -- Check if there are unread messages for this client
         if Client_Pos < Next_Seq - 1 and Count > 0 then
            -- Calculate position in ring buffer
            -- Find the message with sequence number Client_Pos + 1

            for I in 1 .. Count loop
               if Tail + I - 1 <= Message_Buffer_Size then
                  Read_Pos := Tail + I - 1;
               else
                  Read_Pos := (Tail + I - 1) mod Message_Buffer_Size;
                  if Read_Pos = 0 then
                     Read_Pos := Message_Buffer_Size;
                  end if;
               end if;

               if Ring(Read_Pos).Seq_Num = Client_Pos + 1 then
                  Msg := Ring(Read_Pos);
                  Available := True;
                  Client_Positions(Client) := Client_Pos + 1;
                  exit;
               end if;
            end loop;

            -- If we couldn't find the exact next message, skip ahead
            if not Available and Count > 0 then
               -- Get the oldest available message
               Msg := Ring(Tail);
               Available := True;
               Client_Positions(Client) := Msg.Seq_Num;
            end if;
         end if;
      end Get_Message_For_Client;

      function Message_Count return Natural is
      begin
         return Count;
      end Message_Count;

      procedure Reset_Client_Position (Client : Client_ID) is
      begin
         if Client /= No_Client and Client <= Max_Clients then
            -- Set to current sequence so client gets only new messages
            Client_Positions(Client) := Next_Seq - 1;
         end if;
      end Reset_Client_Position;

   end Queue;

end Broadcast_Queue;