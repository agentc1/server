package Msg_Queue with SPARK_Mode => On is
   type Item is private;

   protected type Queue (Capacity : Positive) is
      procedure Enqueue (X : in Item)
        with Pre  => Length < Capacity,
             Post => Length = Length'Old + 1;
      procedure Dequeue (X : out Item)
        with Pre  => Length > 0,
             Post => Length = Length'Old - 1;
      function Length return Natural;
   private
      B    : array (Positive range 1 .. Capacity) of Item;
      Head : Positive := 1;
      Tail : Positive := 1;
      N    : Natural  := 0;
   end Queue;

private
   type Item is new Natural;
end Msg_Queue;
