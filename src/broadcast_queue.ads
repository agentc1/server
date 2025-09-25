with Connection_Manager; use Connection_Manager;

package Broadcast_Queue with SPARK_Mode => Off is

   -- Maximum message length
   Max_Message_Length : constant := 200;

   -- Message buffer size
   Message_Buffer_Size : constant := 256;

   type Message_Text is array (1 .. Max_Message_Length) of Character;

   type Message_Type is record
      Sender  : Client_ID;
      Text    : Message_Text;
      Len     : Natural;
      Seq_Num : Natural;  -- For ordering guarantees
   end record;

   type Message_Array is array (1 .. Message_Buffer_Size) of Message_Type;
   type Position_Array is array (Client_ID) of Natural;

   -- Protected object for thread-safe broadcast queue
   protected Queue is

      -- Post a message to be broadcast to all clients
      entry Post_Message (Msg : Message_Type)
        with Post => Message_Count = Message_Count'Old + 1 or
                    Message_Count = Message_Buffer_Size;

      -- Get next message for a specific client
      procedure Get_Message_For_Client (
         Client    : Client_ID;
         Msg       : out Message_Type;
         Available : out Boolean)
      with Pre => Client /= No_Client and Client <= Max_Clients;

      -- Get current message count
      function Message_Count return Natural
      with Post => Message_Count'Result <= Message_Buffer_Size;

      -- Reset client position (for new connections)
      procedure Reset_Client_Position (Client : Client_ID)
      with Pre => Client /= No_Client and Client <= Max_Clients;

   private
      -- Circular buffer of messages
      Ring : Message_Array;
      Head : Positive := 1;  -- Next write position
      Tail : Positive := 1;  -- Oldest message position
      Count : Natural := 0;
      Next_Seq : Natural := 1;
      Not_Full : Boolean := True;

      -- Track last message each client has read
      Client_Positions : Position_Array := (others => 0);
   end Queue;

end Broadcast_Queue;