with Sockets; use Sockets;
with Connection_Manager; use Connection_Manager;
with Client_Handler;
with Ada.Text_IO; use Ada.Text_IO;
with Types; use Types;

procedure Telnet_Server with SPARK_Mode => Off is
   Server_Socket : Socket_Type;
   Client_Socket : Socket_Type;
   Client_Address : Socket_Address;

   Client_ID_Val : Client_ID;
   Success : Boolean;

   Port : constant := 2323;  -- Use 2323 instead of 23 to avoid needing root

begin
   Put_Line ("Starting Telnet Broadcast Server on port" & Port'Image);

   -- Create and bind server socket
   Create_Server_Socket (Server_Socket);

   if not Is_Valid (Server_Socket) then
      Put_Line ("Failed to create server socket");
      return;
   end if;

   begin
      Bind_Socket (Server_Socket, Port);
      Listen_Socket (Server_Socket, 5);
   exception
      when Socket_Error =>
         Put_Line ("Failed to bind/listen on port" & Port'Image);
         Close_Socket (Server_Socket);
         return;
   end;

   Put_Line ("Server listening... Connect with: telnet localhost" & Port'Image);

   -- Main accept loop
   loop
      begin
         -- Accept new connection
         Accept_Connection (Server_Socket, Client_Socket, Client_Address);

         if Is_Valid (Client_Socket) then
            -- Try to allocate a client slot
            Client_Registry.Allocate_Client (Client_ID_Val, Success);

            if Success then
               Put_Line ("Client" & Client_ID_Val'Image & " connected");

               -- Set default username
               declare
                  Username : Username_String := (others => ' ');
                  User_Str : constant String := "User" & Client_ID_Val'Image;
               begin
                  for I in User_Str'Range loop
                     if I - User_Str'First + 1 <= Username'Length then
                        Username(I - User_Str'First + 1) := User_Str(I);
                     end if;
                  end loop;
                  Client_Registry.Set_Username (Client_ID_Val, Username);
               end;

               -- Start client handler task
               Client_Handler.Task_Pool(Client_ID_Val).Start (
                  Client_ID_Val,
                  Sockets.To_Natural(Client_Socket));
            else
               -- Server full
               Put_Line ("Server full, rejecting connection");
               declare
                  Msg : constant String := "Server full, try again later" &
                                          Character'Val(13) & Character'Val(10);
                  Msg_Bytes : Byte_Array (1 .. Msg'Length);
               begin
                  for I in Msg'Range loop
                     Msg_Bytes(I - Msg'First + 1) := Byte(Character'Pos(Msg(I)));
                  end loop;
                  Send_Data (Client_Socket, Msg_Bytes, Msg'Length);
               end;
               Close_Socket (Client_Socket);
            end if;
         end if;

      exception
         when Socket_Error =>
            Put_Line ("Accept error, continuing...");
         when others =>
            Put_Line ("Unexpected error, continuing...");
      end;
   end loop;

exception
   when others =>
      Put_Line ("Server terminated unexpectedly");
      if Is_Valid (Server_Socket) then
         Close_Socket (Server_Socket);
      end if;
end Telnet_Server;