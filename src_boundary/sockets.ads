with Types; use Types;

package Sockets with SPARK_Mode => Off is
   -- Socket abstraction layer (unverified boundary)

   type Socket_Type is private;
   type Socket_Address is private;

   Invalid_Socket : constant Socket_Type;

   -- Server operations
   procedure Create_Server_Socket (Socket : out Socket_Type);
   procedure Bind_Socket (Socket : Socket_Type; Port : Natural);
   procedure Listen_Socket (Socket : Socket_Type; Queue_Size : Natural);
   procedure Accept_Connection (
      Server : Socket_Type;
      Client : out Socket_Type;
      Address : out Socket_Address);

   -- Client operations
   procedure Send_Data (
      Socket : Socket_Type;
      Data   : Byte_Array;
      Len    : Natural);

   procedure Receive_Data (
      Socket : Socket_Type;
      Buffer : out Byte_Array;
      Received : out Natural);

   procedure Close_Socket (Socket : in out Socket_Type);

   -- Status checks
   function Is_Valid (Socket : Socket_Type) return Boolean;

   -- Conversion functions for passing to tasks
   function To_Natural (Socket : Socket_Type) return Natural;
   function From_Natural (N : Natural) return Socket_Type;

   -- Exceptions (converted to success flags in SPARK boundary)
   Socket_Error : exception;

private
   type Socket_Type is new Integer;
   type Socket_Address is new Integer;

   Invalid_Socket : constant Socket_Type := -1;
end Sockets;