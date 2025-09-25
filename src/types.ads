with Interfaces; use Interfaces;
package Types with SPARK_Mode => On is
   subtype Byte is Unsigned_8;
   type Byte_Array is array (Positive range <>) of Byte;
end Types;
