# System spec (natural language → contracts map)

- **Queue capacity never exceeded.**
  - Where: `Msg_Queue.Queue.Enqueue` pre/post; ring indices within bounds.
- **No dequeue from empty queue.**
  - Where: `Msg_Queue.Queue.Dequeue` pre/post.
- **Parser never overruns buffers; path length ≤ Max_Path.**
  - Where: `Request_Parser.Parse_Line` pre/post + loop invariants/variant.
- **Networking assumptions localized.**
  - Where: `Net_Spec.Recv_Spec` postcondition `Got <= Max` and precondition about buffer size.
