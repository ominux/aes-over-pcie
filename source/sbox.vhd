-- File name:   sbox.vhd
-- Created:     2009-02-26
-- Author:      Jevin Sweval
-- Lab Section: 337-02
-- Version:     1.0  Initial Design Entry
-- Description: Rijndael S-Box

use work.aes.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sbox is
   port (
      a : in byte;
      b : out byte;
   );
end sbox;

architecture dataflow of sbox is
   
   
   function square_gf4 (q : nibble)
      return nibble
   is
      k : nibble;
   begin
      k(3) := q(3);
      k(2) := q(3) xor q(2);
      k(1) := q(2) xor q(1);
      k(0) := q(3) xor q(1) xor q(0);
      
      return k;
   end function square_gf4;
   
   
   function mullambda_gf4 (q : nibble)
      return nibble
   is
      k : nibble;
   begin
      k(3) := q(2) xor q(0);
      k(2) := q(3) xor q(2) xor q(1) xor q(0);
      k(1) := q(3);
      k(0) := q(2);
      
      return k;
   end function mullambda_gf4;
   
   
   function mul_gf2(q : pair, w : pair)
      return pair
   is
      k : pair;
   begin
      k(1) := (q(1) and w(1)) xor (q(0) and w(1)) xor (q(1) and w(0));
      k(0) := (q(1) and w(1)) xor (q(0) and w(0));
      
      return k;
   end function mul_gf2;
   
   
   function mulphi_gf2(q : pair)
      return pair
   is
      k : pair;
   begin
      k(1) := q(1) xor q(0);
      k(0) := q(1);
      
      return k;
   end function mulphi_gf2;
   
   
   function mul_gf4(q : nibble, w : nibble)
      return nibble
   is
      qh, ql, wh, wl : pair;
      res_top, res_mid, res_bot : pair;
      k : nibble;
   begin
      qh := q(3 downto 2);
      ql := q(1 downto 0);
      wh := w(3 downto 2);
      wl := w(1 downto 0);
      
      res_phi := mulphi_gf2(mul_gf2(qh, wh));
      res_mid := mul_gf2(qh xor ql, wh xor wl);
      res_low := mul_gf2(ql, wl);
      
      k(3 downto 2) := res_mid xor res_low;
      k(1 downto 0) := res_hi xor res_low;
      
      return k;
   end function mul_gf4;
   
   function iso_map(q : byte)
      return byte
   is
      k : byte;
   begin
      k(7) := q(7) xor q(5);
      k(6) := q(7) xor q(6) xor q(4) xor q(3) xor q(2) xor q(1);
      k(5) := q(7) xor q(5) xor q(3) xor q(2);
      k(4) := q(7) xor q(5) xor q(3) xor q(2) xor q(1);
      k(3) := q(7) xor q(6) xor q(2) xor q(1);
      k(2) := q(7) xor q(4) xor q(3) xor q(2) xor q(1);
      k(1) := q(6) xor q(4) xor q(1);
      k(0) := q(6) xor q(1) xor q(0);
      
      return k;
   end function iso_map;
   
   
   function inv_iso_map(q : byte)
      return byte
   is
      k : byte;
   begin
      k(7) := q(7) xor q(6) xor q(5) xor q(1);
      k(6) := q(6) xor q(2);
      k(5) := q(6) xor q(5) xor q(1);
      k(4) := q(6) xor q(5) xor q(4) xor q(2) xor q(1);
      k(3) := q(5) xor q(4) xor q(3) xor q(2) xor q(1);
      k(2) := q(7) xor q(4) xor q(3) xor q(2) xor q(1);
      k(1) := q(5) xor q(4);
      k(0) := q(6) xor q(5) xor q(4) xor q(2) xor q(0);
      
      return k;
   end function inv_iso_map;
   
   
begin
   
end dataflow;
