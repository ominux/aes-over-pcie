use work.aes.all;
use work.pcie.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bridge is
   port (
      clk : in std_logic;
      nrst : in std_logic;
      rx_data : in byte;
      tx_data_aes : in byte;
      rx_data_k : in std_logic;
      aes_done : in std_logic;
      tx_data : out byte;
      tx_data_k : out std_logic;
      got_key : out std_logic;
      got_pt : out std_logic;
      send_ct : out std_logic     
   );
end entity bridge;

architecture behavioral of bridge is
    type state_type is (send_byte_count_lo, send_dummy_2, read_dummy_2, send_tag, send_crc_lo, send_dummy_1, send_tlp_type, read_requester_id_hi, send_lcrc_lo_hi, send_completer_id_lo, send_lcrc_hi_lo, read_addr_hi_hi, read_crc_hi, read_addr_lo_lo, send_dllp_seq_num_lo, read_dllp_seq_num_hi, read_dllp_seq_num_lo, read_addr_hi_lo, e_idle, send_crc_hi, read_lcrc_hi_hi, send_lcrc_hi_hi, read_lcrc_lo_hi, read_requestor_id_lo, read_byte_enables, read_addr_lo_hi, send_lcrc_lo_lo, read_length_hi, send_dllp_type, idle, send_requester_id_lo, read_crc_lo, read_lcrc_lo_lo, send_dllp_seq_num_hi, read_tlp_type, send_addr_lo_lo, read_dllp_type, read_dummy_1, read_tag, send_payload, read_tlp_seq_num_lo, send_tlp_length_hi, load_payload, store_ct, read_lcrc_hi_lo, read_tlp_seq_num_hi, send_requester_id_hi, send_completer_id_hi, read_length_lo, send_byte_count_hi, send_tlp_seq_num_lo, send_tlp_seq_num_hi, send_tlp_length_lo);
   signal state, next_state : state_type;
   signal dllp_seq_num, next_dllp_seq_num : seq_number_type;
   signal tlp_seq_num, next_tlp_seq_num : seq_number_type;
   signal tlp_type, next_tlp_type : byte;
   signal tag, next_tag : byte;
   signal addr, next_addr : dword;
   signal i, next_i                       : g_index;
   signal i_up, i_clr                     : std_logic;
   signal crc, next_crc : word;
   signal lcrc, next_lcrc : dword;
   
begin
   
   
   state_reg : process (clk, nrst)
   begin
      -- on reset, the RCU goes to the IDLE state, otherwise it goes
      -- to the next state.
      if (nrst = '0') then
         state <= IDLE;
      elsif (rising_edge(clk)) then
         state <= next_state;
      end if;
   end process state_reg;
   
   -- leda C_1406 off
   i_reg : process(clk)
   begin
      if rising_edge(clk) then
         i <= next_i;
      end if;
   end process i_reg;
   -- leda C_1406 on
   
   i_nsl : process(i, i_up, i_clr)
   begin
      if (i_clr = '1') then
         next_i <= 0;
      elsif (i_up = '1') then
         next_i <= to_integer(to_unsigned(i, 4) + 1);
      else
         next_i <= i;
      end if;
   end process i_nsl;

   
   register_party : process(clk, nrst)
   begin
      if rising_edge(clk) then
         dllp_seq_num <= next_dllp_seq_num;
         tlp_seq_num <= next_tlp_seq_num;
         tlp_type <= next_tlp_type;
         tag <= next_tag;
         addr <= next_addr;
         crc <= next_crc;
         lcrc <= next_lcrc;
      end if;
   end process register_party;
       
   rcu_nsl : process(state)
   begin
      case state is
         when idle =>
            next_state <= read_dllp_type;
         when read_dllp_type =>
            next_state <= read_dummy_1;
         when read_dummy_1 =>
            next_state <= read_dllp_seq_num_hi;
         when read_dllp_seq_num_hi =>
            next_state <= read_dllp_seq_num_lo;
         when read_dllp_seq_num_lo =>
            next_state <= read_crc_hi;
         when read_crc_hi =>
            next_state <= read_crc_lo;
         when read_crc_lo =>
            -- done reading dllp, going to lp
            next_state <= read_tlp_seq_num_hi;
         when read_tlp_seq_num_hi =>
            next_state <= read_tlp_seq_num_lo;
         when read_tlp_seq_num_lo =>
            -- done reading lp, going to tlp
            next_state <= read_tlp_type;
         when read_tlp_type =>
            next_state <= read_dummy_2;
         when read_dummy_2 =>
            next_state <= read_length_hi;
         when read_length_hi =>
            next_state <= read_length_lo;
         when read_length_lo =>
            next_state <= read_requester_id_hi;
         when read_requester_id_hi =>
            next_state <= read_requestor_id_lo;
         when read_requestor_id_lo =>
            next_state <= read_tag;
         when read_tag =>
            next_state <= read_byte_enables;
         when read_byte_enables =>
            next_state <= read_addr_hi_hi;
         when read_addr_hi_hi =>
            next_state <= read_addr_hi_lo;
         when read_addr_hi_lo =>
            next_state <= read_addr_lo_hi;
         when read_addr_lo_hi =>
            next_state <= read_addr_lo_lo;
         when read_addr_lo_lo =>
            if (addr = x"00001000") then
               next_state <= load_payload;
            elsif (addr = x"00002000") then
               next_state <= load_payload;
            elsif (addr = x"00003000") then
               next_state <= store_ct;
            else
               next_state <= e_idle;
            end if;
         when load_payload =>
            if (i /= 15) then
               next_state <= load_payload;
            else
               next_state <= read_lcrc_hi_hi;
            end if;
         when store_ct =>
            next_state <= read_lcrc_hi_hi;
         when read_lcrc_hi_hi =>
            next_state <= read_lcrc_hi_lo;
         when read_lcrc_hi_lo =>
            next_state <= read_lcrc_lo_hi;
         when read_lcrc_lo_hi =>
            next_state <= read_lcrc_lo_lo;
         when read_lcrc_lo_lo =>
            next_state <= send_dllp_type;
         when send_dllp_type =>
            -- sends ack or nak
            next_state <= send_dummy_1;
         when send_dummy_1 =>
            next_state <= send_dllp_seq_num_hi;
         when send_dllp_seq_num_hi =>
            next_state <= send_dllp_seq_num_lo;
         when send_dllp_seq_num_lo =>
            next_state <= send_crc_hi;
         when send_crc_hi =>
            next_state <= send_crc_lo;
         when send_crc_lo =>
            -- either go to idle after an ack/nak or send the ct
            -- next_state <= send_tlp_seq_num_hi;
         when send_tlp_seq_num_hi =>
            next_state <= send_tlp_seq_num_lo;
         when send_tlp_seq_num_lo =>
            next_state <= send_tlp_type;
         when send_tlp_type =>
            next_state <= send_dummy_2;
         when send_dummy_2 =>
            next_state <= send_tlp_length_hi;
         when send_tlp_length_hi =>
            next_state <= send_tlp_length_lo;
         when send_tlp_length_lo =>
            next_state <= send_completer_id_hi;
         when send_completer_id_hi =>
            next_state <= send_completer_id_lo;
         when send_completer_id_lo =>
            next_state <= send_byte_count_hi;
         when send_byte_count_hi =>
            next_state <= send_byte_count_lo;
         when send_byte_count_lo =>
            next_state <= send_requester_id_hi;
         when send_requester_id_hi =>
            next_state <= send_requester_id_lo;
         when send_requester_id_lo =>
            next_state <= send_tag;
         when send_tag =>
            next_state <= send_addr_lo_lo;
         when send_addr_lo_lo =>
            next_state <= send_payload;
         when send_payload =>
            if (i /= 15) then
               next_state <= send_payload;
            else
               next_state <= send_lcrc_hi_hi;
            end if;
         when send_lcrc_hi_hi =>
            next_state <= send_lcrc_hi_lo;
         when send_lcrc_hi_lo =>
            next_state <= send_lcrc_lo_hi;
         when send_lcrc_lo_hi =>
            next_state <= send_lcrc_lo_lo;
         when send_lcrc_lo_lo =>
            next_state <= idle;
         when others =>
            next_state <= e_idle;
      end case;
   end process rcu_nsl;
   
   bridge_output : process(state)
   begin
      tx_data <= x"7C"; -- idl
      tx_data_k <= '1'; -- control byte
      got_key <= '0';
      got_pt <= '0';
      send_ct <= '1';
      
      next_dllp_seq_num <= dllp_seq_num;
      next_tlp_seq_num <= tlp_seq_num;
      next_tlp_type <= tlp_type;
      next_tag <= tag;
      next_addr <= addr;
      next_lcrc <= lcrc;
      next_crc <= crc;
      
      case state is
         when idle =>
            -- already logic idling
         when read_addr_lo_lo =>
            next_addr(7 downto 0) <= rx_data;
            if (addr(31 downto 8) & rx_data = x"00001000") then
               got_key <= '1';
            elsif (addr(31 downto 8) & rx_data = x"00002000") then
               got_pt <= '1';
            end if;
         when send_addr_lo_lo =>
            send_ct <= '1';
         when read_dllp_seq_num_hi =>
            next_dllp_seq_num(11 downto 8) <= rx_data(3 downto 0);
         when read_dllp_seq_num_lo =>
            next_dllp_seq_num(7 downto 0) <= rx_data;
         when read_tlp_seq_num_hi =>
            next_tlp_seq_num(11 downto 8) <= rx_data(3 downto 0);
         when read_tlp_seq_num_lo =>
            next_tlp_seq_num(7 downto 0) <= rx_data;
         when read_crc_hi =>
            next_crc(15 downto 8) <= rx_data;
         when read_crc_lo =>
            next_crc(7 downto 0) <= rx_data;
         when read_lcrc_hi_hi =>
            next_lcrc(31 downto 24) <= rx_data;
         when read_lcrc_hi_lo =>
            next_lcrc(23 downto 16) <= rx_data;
         when read_lcrc_lo_hi =>
            next_lcrc(15 downto 8) <= rx_data;
         when read_lcrc_lo_lo =>
            next_lcrc(7 downto 0) <= rx_data;
         when read_tlp_type =>
            next_tlp_type <= rx_data;
         when read_length_hi =>
            -- nothing
         when read_length_lo =>
            -- nothing
         when read_tag =>
            next_tag <= rx_data;
         when read_addr_hi_hi =>
            next_addr(31 downto 24) <= rx_data;
         when read_addr_hi_lo =>
            next_addr(23 downto 16) <= rx_data;
         when read_addr_lo_hi =>
            next_addr(15 downto 8) <= rx_data;
         when send_lcrc_hi_hi =>
            tx_data <= lcrc(31 downto 24);
            tx_data_k <= '1';
         when send_lcrc_hi_lo =>
            tx_data <= lcrc(23 downto 16);
            tx_data_k <= '1';
         when send_lcrc_lo_hi =>
            tx_data <= lcrc(15 downto 8);
            tx_data_k <= '1';
         when send_lcrc_lo_lo =>
            tx_data <= lcrc(7 downto 0);
            tx_data_k <= '1';
         when others =>
            -- get fucked
      end case;
   end process bridge_output;
   
end architecture behavioral;
