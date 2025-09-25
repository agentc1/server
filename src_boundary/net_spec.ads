with Types; use Types;
package Net_Spec with SPARK_Mode => On is
   procedure Recv_Spec (Buf : out Byte_Array; Max : Positive; Got : out Natural)
     with Global  => null,
          Depends => (Buf => Max, Got => Max),
          Pre     => Buf'Length >= Max and then Max > 0,
          Post    => Got <= Max;
end Net_Spec;
