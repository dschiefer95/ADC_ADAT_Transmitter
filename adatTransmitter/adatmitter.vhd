----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    07:19:34 11/29/2017 
-- Design Name: 
-- Module Name:    adatmitter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adatmitter is
	port (
		mclk : in std_logic;
		bick : out std_logic;
		lrck : out std_logic;
		sdto1 : in std_logic;
		pdn : out std_logic;
		tdm1 : out std_logic;
		tdm0 : out std_logic;
		msn : out std_logic;
		dif : out std_logic;
		cks0 : out std_logic;
		cks1 : out std_logic;
		cks2 : out std_logic
	);	
end adatmitter;

architecture adatmitter_arch of adatmitter is
	-- state_read and state_send could be combined into a single
	-- type if desired
	type state_read is (idle, read1, read2, read3, read4);
	type state_send is (idle, send1, send2, send3, send4);
	signal state_reg_read, state_next_read : state_read;
	signal state_reg_send, state_next_send : state_send;
	signal reset: std_logic;
	signal shift_reg : std_logic_vector(23 downto 0);
	
	-- need to verify if this can be used as implicit memory like this:
	signal read_counter : unsigned(4 downto 0);
	
	-- not sure which pin to route this to, so using as a signal
	-- at the moment...
	signal tff_in : std_logic;

begin
	-- state register for read
	process(mclk, reset)
	begin
		if (reset='1') then
			state_reg_read <= idle;
		elsif (mclk'event and mclk='1') then
			state_reg_read <= state_next_read;
		end if;
	end process;
	-- state register for send
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			state_reg_send <= state_next_send;
		end if;
	end process;
	-- shift register
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			shift_reg <= shift_next;
		end if;
	end process;
	-- read counter
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			read_counter <= read_counter_next;
		end if;
	end process;
	
	
	-- next-state logic for read
	process (state_reg_read)
	begin
		state_next_read <= state_next_read;
		shift_next <= shift_next;
		read_counter_next <= read_counter + 1;
		case state_reg_read is
			when read1 =>
				if (read_counter<24)
					shift_next(23 downto 1) <= shift_reg(22 downto 0) & sdto1;
				elsif (read_counter=24)
					ch1_reg <= '1' & shift_reg[23:20] & '1' & shift_reg[19:16] & '1' & shift_reg[15:12] & '1' & shift_reg[11:8] & '1' & shift_reg[7:4] & '1' & shift_reg[3:0];
					state_next_send <= send1;
				elsif (read_counter=32) then
					state_next_read <= read2;
					read_counter_next <= '0';
				end if;
			when ...
		end case;
	end process;
	-- next-state logic for send
	process (state_reg_send)
	begin
		case state_reg_send is
			when idle =>
				if (send_counter=23) then
					state_next_send <= send1;
					send_counter <= 0;
				else
					send_counter <= send_counter + 1;
				end if;
			when ...
		end case;
	end process;
	
	

	-- output logic for send
	process(state_reg_send)
	begin
		case state_reg_send is
			when send1 =>
				tff_in <= shift_reg(23);
				shift_reg(23 downto 1) <= shift_reg(22 downto 0);
				
end adatmitter_arch;

