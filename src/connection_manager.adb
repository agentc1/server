package body Connection_Manager with SPARK_Mode => Off is

   protected body Client_Registry is

      procedure Allocate_Client (
         ID      : out Client_ID;
         Success : out Boolean) is
      begin
         ID := No_Client;
         Success := False;

         -- Find first available slot
         for I in Client_ID range 1 .. Max_Clients loop
            if Clients(I).State = Disconnected then
               Clients(I).State := Connection_Manager.Active;
               Clients(I).Username := (others => ' ');
               ID := I;
               Success := True;
               Active := Active + 1;
               exit;
            end if;
         end loop;
      end Allocate_Client;

      procedure Release_Client (ID : Client_ID) is
      begin
         if ID /= No_Client and then ID <= Max_Clients and then
            Clients(ID).State /= Disconnected
         then
            Clients(ID).State := Disconnected;
            Clients(ID).Username := (others => ' ');
            if Active > 0 then
               Active := Active - 1;
            end if;
         end if;
      end Release_Client;

      function Active_Count return Natural is
      begin
         return Active;
      end Active_Count;

      procedure Get_Active_Clients (
         Clients : out Client_ID_Array;
         Count   : out Natural) is
         Idx : Natural := Clients'First;
      begin
         Count := 0;

         -- Initialize output array
         for I in Clients'Range loop
            Clients(I) := No_Client;
         end loop;

         -- Collect active clients
         for I in Client_ID range 1 .. Max_Clients loop
            if Client_Registry.Clients(I).State = Connection_Manager.Active and then
               Idx <= Clients'Last
            then
               Clients(Idx) := I;
               Idx := Idx + 1;
               Count := Count + 1;
            end if;
         end loop;
      end Get_Active_Clients;

      procedure Set_Username (
         ID   : Client_ID;
         Name : Username_String) is
      begin
         if ID /= No_Client and then ID <= Max_Clients then
            Clients(ID).Username := Name;
         end if;
      end Set_Username;

      function Get_Username (ID : Client_ID) return Username_String is
      begin
         if ID /= No_Client and then ID <= Max_Clients then
            return Clients(ID).Username;
         else
            return (others => ' ');
         end if;
      end Get_Username;

   end Client_Registry;

end Connection_Manager;