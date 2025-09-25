with Types; use Types;
package Net with SPARK_Mode => Off is
   -- Replace this with your actual binding to recv()/read() etc.
   function Recv (Buf : out Byte_Array; Max : Positive) return Natural;
end Net;
