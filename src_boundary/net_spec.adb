with Net; use Net;
with Types; use Types;
package body Net_Spec with SPARK_Mode => Off is
   procedure Recv_Spec (Buf : out Byte_Array; Max : Positive; Got : out Natural) is
   begin
      Got := Net.Recv (Buf, Max);
   end Recv_Spec;
end Net_Spec;
