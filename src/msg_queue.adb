package body Msg_Queue with SPARK_Mode => On is
   protected body Queue is
      procedure Enqueue (X : in Item) is
      begin
         B(Tail) := X;
         if Tail = Capacity then
            Tail := 1;
         else
            Tail := Tail + 1;
         end if;
         N := N + 1;
      end Enqueue;

      procedure Dequeue (X : out Item) is
      begin
         X := B(Head);
         if Head = Capacity then
            Head := 1;
         else
            Head := Head + 1;
         end if;
         N := N - 1;
      end Dequeue;

      function Length return Natural is (N);
   end Queue;
end Msg_Queue;
