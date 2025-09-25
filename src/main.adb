with Msg_Queue;
with Request_Parser;
procedure Main with SPARK_Mode => On is
   Q     : Msg_Queue.Queue (16);
   Dummy : Msg_Queue.Item := 0;
   R     : Request_Parser.Parsed;
begin
   Q.Enqueue (1);
   Q.Dequeue (Dummy);
   Request_Parser.Parse_Line ("GET /", R);
end Main;
