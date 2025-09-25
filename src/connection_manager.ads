package Connection_Manager with SPARK_Mode => Off is
   pragma Unevaluated_Use_Of_Old (Allow);

   -- Maximum concurrent clients (Ravenscar requires static allocation)
   Max_Clients : constant := 32;

   type Client_ID is range 0 .. Max_Clients;
   No_Client : constant Client_ID := 0;

   type Client_State is (Disconnected, Connecting, Active, Closing);

   type Username_String is array (1 .. 16) of Character;

   type Client_ID_Array is array (Positive range <>) of Client_ID;

   type Client_Info is record
      State    : Client_State := Disconnected;
      Username : Username_String := (others => ' ');
   end record;

   type Client_Info_Array is array (Client_ID) of Client_Info;

   -- Protected object for thread-safe client management
   protected Client_Registry is

      -- Allocate a new client slot
      procedure Allocate_Client (
         ID      : out Client_ID;
         Success : out Boolean)
      with Post => (if Success then
                      ID /= No_Client and Active_Count = Active_Count'Old + 1
                    else
                      ID = No_Client and Active_Count = Active_Count'Old);

      -- Release a client slot
      procedure Release_Client (ID : Client_ID)
      with Pre => ID /= No_Client and ID <= Max_Clients,
           Post => Active_Count = Active_Count'Old - 1;

      -- Get count of active clients
      function Active_Count return Natural
      with Post => Active_Count'Result <= Max_Clients;

      -- Get list of all active clients
      procedure Get_Active_Clients (
         Clients : out Client_ID_Array;
         Count   : out Natural)
      with Pre => Clients'Length >= Max_Clients,
           Post => Count <= Max_Clients and Count = Active_Count;

      -- Set username for a client
      procedure Set_Username (
         ID   : Client_ID;
         Name : Username_String)
      with Pre => ID /= No_Client and ID <= Max_Clients;

      -- Get username for a client
      function Get_Username (ID : Client_ID) return Username_String
      with Pre => ID /= No_Client and ID <= Max_Clients;

   private
      Clients : Client_Info_Array := (others => (Disconnected, (others => ' ')));
      Active  : Natural := 0;
   end Client_Registry;

end Connection_Manager;