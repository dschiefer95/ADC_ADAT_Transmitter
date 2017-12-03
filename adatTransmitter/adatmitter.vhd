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
	-- need to specify starting state value
	type state_read is (idle_read, read1, read2, read3, read4);
	type state_send is (idle_send, send1, send2, send3, send4, send5, send6);
	signal state_reg_read, state_next_read : state_read;
	signal state_reg_send, state_next_send : state_send;
	signal reset_read: std_logic;
	signal reset_send: std_logic;
	signal shift_reg : std_logic_vector(23 downto 0);
	signal shift_next : std_logic_vector(23 downto 0);
	
	-- need to verify if this can be used as implicit memory like this:
	signal read_counter : unsigned(4 downto 0);
	signal read_counter_next : unsigned(4 downto 0);
	signal send_counter : unsigned(7 downto 0);
	signal send_counter_next : unsigned(7 downto 0);
	signal ss5_counter : unsigned(4 downto 0);
	signal ss5_counter_next : unsigned(4 downto 0);
	
	-- not sure which pin to route this to, so using as a signal
	-- at the moment...
	signal tff_in : std_logic;
	
	-- not sure where to route this, so using as a signal
	signal reset : std_logic;
	
	-- buffer/transmit registers
	signal ch1_reg : std_logic_vector(29 downto 0);
	signal ch2_reg : std_logic_vector(29 downto 0);
	signal ch3_reg : std_logic_vector(29 downto 0);
	signal ch4_reg : std_logic_vector(29 downto 0);
	signal ch1_next : std_logic_vector(29 downto 0);
	signal ch2_next : std_logic_vector(29 downto 0);
	signal ch3_next : std_logic_vector(29 downto 0);
	signal ch4_next : std_logic_vector(29 downto 0);
	
	-- For communication between the read and send state machines
	signal start_send : std_logic;

begin
	-- state register for read
	process(mclk, reset_read)
	begin
		if (reset_read='1') then
			state_reg_read <= idle_read;
		elsif (mclk'event and mclk='1') then
			state_reg_read <= state_next_read;
		end if;
	end process;
	-- state register for send
	process(mclk, reset_send)
	begin
		if (reset_send='1') then
			state_reg_send <= idle_send;
		elsif (mclk'event and mclk='1') then
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
	-- send counter
	process(mclk)
	begin
		if (start_send = '1') then
			if (mclk'event and mclk='1') then
				send_counter <= send_counter_next;
			end if;
		end if;
	end process;
	-- send state5 counter
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			ss5_counter <= ss5_counter_next;
		end if;
	end process;
	-- ch1 register
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			ch1_reg <= ch1_next;
		end if;
	end process;
	-- ch2 register
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			ch2_reg <= ch2_next;
		end if;
	end process;
	-- ch3 register
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			ch3_reg <= ch3_next;
		end if;
	end process;
	-- ch4 register
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			ch4_reg <= ch4_next;
		end if;
	end process;
	-- ch5678s register (for channels 5-8 and the last 16 sync bits)
	process(mclk)
	begin
		if (mclk'event and mclk='1') then
			ch5678s_reg <= ch5678s_next;
		end if;
	end process;
	
	
	-- next-state logic for read
	process (state_reg_read, read_counter)
	begin
		state_next_read <= state_next_read;
		shift_next <= shift_next;
		read_counter_next <= read_counter + 1;
		case state_reg_read is
			when idle_read =>
				if (read_counter=127) then
					state_next_read <= read1;
					read_counter_next <= (others => '0');
				else	
					state_next_read <= idle_read;
				end if;
		
			when read1 =>
				if (read_counter<24) then
					shift_next(23 downto 0) <= shift_reg(22 downto 0) & sdto1;
				elsif (read_counter=24) then
					ch1_reg(29 downto 0) <= '1' & shift_reg(23 downto 20) & '1' & shift_reg(19 downto 16) & '1' & shift_reg(15 downto 12) & '1' & shift_reg(11 downto 8) & '1' & shift_reg(7 downto 4) & '1' & shift_reg(3 downto 0);
					start_send <= '1';
				elsif (read_counter=31) then
					state_next_read <= read2;
					read_counter_next <= (others => '0');
				end if;
				
			when read2 =>
				if (read_counter<24) then
					shift_next(23 downto 0) <= shift_reg(22 downto 0) & sdto1;
				elsif (read_counter=24) then
					ch2_reg(29 downto 0) <= '1' & shift_reg(23 downto 20) & '1' & shift_reg(19 downto 16) & '1' & shift_reg(15 downto 12) & '1' & shift_reg(11 downto 8) & '1' & shift_reg(7 downto 4) & '1' & shift_reg(3 downto 0);
				elsif (read_counter=31) then
					state_next_read <= read3;
					read_counter_next <= (others => '0');
				end if;
				
			when read3 =>
				if (read_counter<24) then
					shift_next(23 downto 0) <= shift_reg(22 downto 0) & sdto1;
				elsif (read_counter=24) then
					ch3_reg(29 downto 0) <= '1' & shift_reg(23 downto 20) & '1' & shift_reg(19 downto 16) & '1' & shift_reg(15 downto 12) & '1' & shift_reg(11 downto 8) & '1' & shift_reg(7 downto 4) & '1' & shift_reg(3 downto 0);
				elsif (read_counter=31) then
					state_next_read <= read4;
					read_counter_next <= (others => '0');
				end if;
				
			when read4 =>
				if (read_counter<24) then
					shift_next(23 downto 0) <= shift_reg(22 downto 0) & sdto1;
				elsif (read_counter=24) then
					ch4_reg(29 downto 0) <= '1' & shift_reg(23 downto 20) & '1' & shift_reg(19 downto 16) & '1' & shift_reg(15 downto 12) & '1' & shift_reg(11 downto 8) & '1' & shift_reg(7 downto 4) & '1' & shift_reg(3 downto 0);
				elsif (read_counter=31) then
					state_next_read <= idle_read;
					read_counter_next <= (others => '0');
				end if;
		end case;
	end process;
	
	-- next-state logic for send
	process (state_reg_send, start_send)
	begin
		state_next_send <= state_next_send;
		send_counter_next <= send_counter + 1;
		case state_reg_send is
			when idle_send =>
				if (start_send = '1') then
					state_next_send <= send1;
					send_counter_next <= (others => '0');
					ch1_next(29 downto 1) <= ch1_reg(28 downto 0);		-- the ch1_next needs to be in ch1_reg as soon as state_reg_send is send1
				else
					state_next_send <= idle_send;
				end if;
				
			-- counter values need to be figured out
			when send1 =>
				ch1_next(29 downto 1) <= ch1_reg(28 downto 0);
				if (send_counter=29) then
					state_next_send <= send2;
					send_counter_next <= (others => '0');
					ch2_next(29 downto 1) <= ch2_reg(28 downto 0);
				end if;
				
			when send2 =>
				ch2_next(29 downto 1) <= ch2_reg(28 downto 0);
				if (send_counter=29) then
					state_next_send <= send3;
					send_counter_next <= (others => '0');
					ch3_next(29 downto 1) <= ch3_reg(28 downto 0);
				end if;
			
			when send3 =>
				ch3_next(29 downto 1) <= ch3_reg(28 downto 0);
				if (send_counter=29) then
					state_next_send <= send4;
					send_counter_next <= (others => '0');
					ch4_next(29 downto 1) <= ch4_reg(28 downto 0);
				end if;
			
			when send4 =>
				ch4_next(29 downto 1) <= ch4_reg(28 downto 0);
				if(send_counter=29) then
					state_next_send <= send5;
					send_counter_next <= (others => '0');
					ch5678_next <= '1';
				end if;
				
			when send5 =>
				if (send_counter=4 and ss5_counter=23) then
					state_next_send <= send6;
					ch5678s_next <= '1';
					send_counter_next <= (others => '0');
					ss5_counter_next <= (others => '0');
				elsif (send_counter=4 and ss5_counter/=23) then
					ch5678s_next <= '1';
					send_counter_next <= (others => '0');
					ss5_counter_next <= ss5_counter + 1;
				else
					ch5678s_next <= '0';
					ss5_counter_next <= ss5_counter;
				end if;
					
			when send6 =>
				if (send_counter=10) then
					ch5678s_next <= '1';
				elsif (send_counter=15) then
					state_next_send <= send1;
					ch5678s_next <= (others => '0');
				else
					ch5678s_next <= (others => '0');
				end if;
		end case;
	end process;
	
	

	-- output logic for send
	process(state_reg_send)
	begin
		case state_reg_send is
			when idle_send =>
				ch1_reg(29 downto 0) <= ch1_reg(29 downto 0);
				ch2_reg(29 downto 0) <= ch2_reg(29 downto 0);
				ch3_reg(29 downto 0) <= ch3_reg(29 downto 0);
				ch4_reg(29 downto 0) <= ch4_reg(29 downto 0);
				
			when send1 =>
				tff_in <= ch1_reg(29);
				
			when send2 =>
				tff_in <= ch1_reg(29);
				
			when send3 =>
				tff_in <= ch1_reg(29);
				
			when send4 =>
				tff_in <= ch1_reg(29);
				
			when send5 =>
				tff_in <= ch5678s_reg;
				
			when send6 =>
				tff_in <= ch5678s_reg;
		end case;
	end process;
				
end adatmitter_arch;

