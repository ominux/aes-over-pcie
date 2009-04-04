-- File name:   state.vhd
-- Created:     2009-04-04
-- Author:      Jevin Sweval
-- Lab Section: 337-02
-- Version:     1.0  Initial Design Entry
-- Description: AES state register block

use work.aes.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity state is
   
   port (
      clk      : in std_logic;
      state_q  : in state;
      state_d  : out state
   );
   
end entity state;


architecture dataflow of state is
   
begin
   
   reg : process(clk)
   begin
      if rising_edge(clk) then
         state_q <= state_d;
      end if;
   end process reg;
   
end architecture dataflow;
