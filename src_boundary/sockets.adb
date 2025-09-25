with GNAT.Sockets; use GNAT.Sockets;
with Ada.Streams;

package body Sockets with SPARK_Mode => Off is

   type Socket_Record is record
      Socket : GNAT.Sockets.Socket_Type;
      Valid  : Boolean := False;
   end record;

   Socket_Table : array (Socket_Type range 0 .. 63) of Socket_Record;
   Next_ID : Socket_Type := 0;

   function Allocate_Socket_ID return Socket_Type is
      ID : Socket_Type := Next_ID;
   begin
      -- Simple allocation, find next free slot
      for I in Socket_Type range 0 .. 63 loop
         if not Socket_Table(ID).Valid then
            Next_ID := (ID + 1) mod 64;
            return ID;
         end if;
         ID := (ID + 1) mod 64;
      end loop;
      return Invalid_Socket;
   end Allocate_Socket_ID;

   procedure Create_Server_Socket (Socket : out Socket_Type) is
      S : GNAT.Sockets.Socket_Type;
      ID : Socket_Type;
   begin
      Create_Socket (S);
      ID := Allocate_Socket_ID;
      if ID /= Invalid_Socket then
         Socket_Table(ID) := (Socket => S, Valid => True);
         Socket := ID;
      else
         Close_Socket (S);
         raise Socket_Error with "No socket slots available";
      end if;
   exception
      when others =>
         Socket := Invalid_Socket;
   end Create_Server_Socket;

   procedure Bind_Socket (Socket : Socket_Type; Port : Natural) is
      Addr : Sock_Addr_Type;
   begin
      if Socket = Invalid_Socket or else not Socket_Table(Socket).Valid then
         raise Socket_Error with "Invalid socket";
      end if;

      Addr.Addr := Any_Inet_Addr;
      Addr.Port := Port_Type(Port);
      Bind_Socket (Socket_Table(Socket).Socket, Addr);
   exception
      when others =>
         raise Socket_Error with "Bind failed";
   end Bind_Socket;

   procedure Listen_Socket (Socket : Socket_Type; Queue_Size : Natural) is
   begin
      if Socket = Invalid_Socket or else not Socket_Table(Socket).Valid then
         raise Socket_Error with "Invalid socket";
      end if;

      GNAT.Sockets.Listen_Socket (Socket_Table(Socket).Socket, Queue_Size);
   exception
      when others =>
         raise Socket_Error with "Listen failed";
   end Listen_Socket;

   procedure Accept_Connection (
      Server : Socket_Type;
      Client : out Socket_Type;
      Address : out Socket_Address) is
      C : GNAT.Sockets.Socket_Type;
      Addr : Sock_Addr_Type;
      ID : Socket_Type;
   begin
      if Server = Invalid_Socket or else not Socket_Table(Server).Valid then
         Client := Invalid_Socket;
         Address := 0;
         return;
      end if;

      Accept_Socket (Socket_Table(Server).Socket, C, Addr);

      ID := Allocate_Socket_ID;
      if ID /= Invalid_Socket then
         Socket_Table(ID) := (Socket => C, Valid => True);
         Client := ID;
         Address := Socket_Address(Addr.Port);
      else
         Close_Socket (C);
         Client := Invalid_Socket;
         Address := 0;
      end if;
   exception
      when others =>
         Client := Invalid_Socket;
         Address := 0;
   end Accept_Connection;

   procedure Send_Data (
      Socket : Socket_Type;
      Data   : Byte_Array;
      Len    : Natural) is
      Last : Ada.Streams.Stream_Element_Offset;
      Buffer : Ada.Streams.Stream_Element_Array(1 .. Ada.Streams.Stream_Element_Offset(Len));
   begin
      if Socket = Invalid_Socket or else not Socket_Table(Socket).Valid then
         return;
      end if;

      -- Convert byte array to stream elements
      for I in 1 .. Len loop
         Buffer(Ada.Streams.Stream_Element_Offset(I)) :=
            Ada.Streams.Stream_Element(Data(Data'First + I - 1));
      end loop;

      Send_Socket (Socket_Table(Socket).Socket, Buffer, Last);
   exception
      when others =>
         null; -- Silently fail for now
   end Send_Data;

   procedure Receive_Data (
      Socket : Socket_Type;
      Buffer : out Byte_Array;
      Received : out Natural) is
      Stream_Buffer : Ada.Streams.Stream_Element_Array(1 .. Buffer'Length);
      Last : Ada.Streams.Stream_Element_Offset;
   begin
      Buffer := (others => 0);
      Received := 0;

      if Socket = Invalid_Socket or else not Socket_Table(Socket).Valid then
         return;
      end if;

      Receive_Socket (Socket_Table(Socket).Socket, Stream_Buffer, Last);

      -- Convert stream elements to byte array
      Received := Natural(Last);
      for I in 1 .. Natural(Last) loop
         if Buffer'First + I - 1 <= Buffer'Last then
            Buffer(Buffer'First + I - 1) := Byte(Stream_Buffer(Ada.Streams.Stream_Element_Offset(I)));
         end if;
      end loop;
   exception
      when others =>
         Received := 0;
   end Receive_Data;

   procedure Close_Socket (Socket : in out Socket_Type) is
   begin
      if Socket /= Invalid_Socket and then Socket_Table(Socket).Valid then
         begin
            GNAT.Sockets.Close_Socket (Socket_Table(Socket).Socket);
         exception
            when others => null;
         end;
         Socket_Table(Socket).Valid := False;
      end if;
      Socket := Invalid_Socket;
   end Close_Socket;

   function Is_Valid (Socket : Socket_Type) return Boolean is
   begin
      return Socket /= Invalid_Socket and then
             Socket in 0 .. 63 and then
             Socket_Table(Socket).Valid;
   end Is_Valid;

   function To_Natural (Socket : Socket_Type) return Natural is
   begin
      return Natural(Integer(Socket));
   end To_Natural;

   function From_Natural (N : Natural) return Socket_Type is
   begin
      return Socket_Type(Integer(N));
   end From_Natural;

begin
   -- Initialize GNAT.Sockets
   GNAT.Sockets.Initialize;
end Sockets;