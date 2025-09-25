with Connection_Manager; use Connection_Manager;
with System;

package Client_Handler with SPARK_Mode => Off is

   -- Client task type for handling individual connections
   -- Jorvik compliant: allows single entry
   task type Client_Task is
      pragma Priority (System.Default_Priority);

      -- Entry allowed in Jorvik profile
      entry Start (ID : Client_ID; Socket_ID : Natural);
   end Client_Task;

   -- Pre-allocated static pool of client tasks
   Task_Pool : array (Client_ID range 1 .. Max_Clients) of Client_Task;

end Client_Handler;