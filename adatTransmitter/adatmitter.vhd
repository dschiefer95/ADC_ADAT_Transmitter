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
		mhz50_out : out std_logic;
		mhz50_in : in std_logic;
	
		mclk : in std_logic;
		sdto1 : in std_logic;
		--ovf_pin : in std_logic;
		
		mclk_out : out std_logic;
		bick : out std_logic;
		lrck : out std_logic;
		pdn : out std_logic;
		tdm1 : out std_logic;
		tdm0 : out std_logic;
		msn : out std_logic;
		dif : out std_logic;
		cks0 : out std_logic;
		cks1 : out std_logic;
		cks2 : out std_logic;
		transmit: out std_logic;
		hpfe : out std_logic;
		mono : out std_logic;
		
		statesync_led : out std_logic;
		statesyncnot_led : out std_logic
	);
end adatmitter;

architecture adatmitter_arch of adatmitter is

	type state_read is (idle_read, read1, read2, read3, read4);
	type state_send is (idle_send, send1, send2, send3, send4, send5, send6);
	signal state_reg_read, state_next_read : state_read;
	signal state_reg_send, state_next_send : state_send;
	
	-- counters
	signal read_counter, read_counter_next : unsigned(6 downto 0) := "0000000";
	signal send_counter, send_counter_next : unsigned(6 downto 0) := "0000000";
	signal ss5_counter, ss5_counter_next : unsigned(4 downto 0) := "00000";
	signal integrity_counter, integrity_counter_next : unsigned(1 downto 0) := "11";
	
	-- input of T-flipflop
	signal tff_in : std_logic;
	signal tff_out : std_logic;
	
	-- buffer/transmit registers
	signal ch1_reg : std_logic_vector(29 downto 0);
	signal ch2_reg : std_logic_vector(29 downto 0);
	signal ch3_reg : std_logic_vector(29 downto 0);
	signal ch4_reg : std_logic_vector(29 downto 0);
	signal ch1_next : std_logic_vector(29 downto 0);
	signal ch2_next : std_logic_vector(29 downto 0);
	signal ch3_next : std_logic_vector(29 downto 0);
	signal ch4_next : std_logic_vector(29 downto 0);
	signal ch5678s_reg : std_logic;
	signal ch5678s_next : std_logic;
	
	-- clock divider
	signal fs_clock : std_logic;
	signal fs_counter : unsigned(6 downto 0) := "0000000";
	
	--sync leds
	signal statesyncled_send : std_logic;
	signal statesyncled_read : std_logic;

begin	
	dif <= '0';
	pdn <= '1';
	msn <= '0';
	cks0 <= '0';
	cks1 <= '1';
	cks2 <= '0';
	tdm1 <= '0';
	tdm0 <= '1';
	hpfe <= '1';
	mono <= '0';
	
	transmit <= tff_out;
	bick <= mclk;
	lrck <= fs_clock;
	mclk_out <= mclk;
	
	mhz50_out <= mhz50_in;
	
	process(mclk)
	begin
		if (mclk'event and mclk='0') then
			-- state registers
			state_reg_read <= state_next_read;
			state_reg_send <= state_next_send;
			
			-- counters
			integrity_counter <= integrity_counter_next;
			read_counter <= read_counter_next;
			send_counter <= send_counter_next;
			ss5_counter <= ss5_counter_next;
			
			-- channel registers (ch5678s register for channels 5-8 and the last 16 sync bits)
			ch1_reg <= ch1_next;
			ch2_reg <= ch2_next;
			ch3_reg <= ch3_next;
			ch4_reg <= ch4_next;
			ch5678s_reg <= ch5678s_next;
			
			-- T flip flop
			tff_out <= tff_in xor tff_out;
			
			-- clock divider for 48khz sample rate
			if (fs_counter=127) then
				fs_clock <= not(fs_clock);
				fs_counter <= (others => '0');
			else
				fs_counter <= fs_counter + 1;
			end if;
		end if;
	end process;
	
	--state sync led to make sure read and send are synced
	process(statesyncled_send, statesyncled_read)
	begin
		if (statesyncled_send='1') then
			if (statesyncled_read='1') then
				statesync_led <= '1';
			else 
				statesyncnot_led <= '1';
			end if;
		end if;
	end process;
	
	-- next-state logic
	process (state_reg_read, read_counter, state_reg_send, send_counter, ss5_counter, integrity_counter, ch1_reg, ch2_reg, ch3_reg, ch4_reg, sdto1)
	begin
		state_next_read <= state_reg_read;
		state_next_send <= state_reg_send;
		
		read_counter_next <= read_counter + 1;
		integrity_counter_next <= integrity_counter;
		send_counter_next <= send_counter + 1;
		ss5_counter_next <= ss5_counter;
		
		ch1_next(29 downto 0) <= ch1_reg(29 downto 0);
		ch2_next(29 downto 0) <= ch2_reg(29 downto 0);
		ch3_next(29 downto 0) <= ch3_reg(29 downto 0);
		ch4_next(29 downto 0) <= ch4_reg(29 downto 0);
		ch5678s_next <= '0';
		
		-- read state machine
		case state_reg_read is
			when idle_read =>
				if (read_counter=127) then
					state_next_read <= read1;
					read_counter_next <= (others => '0');
				end if;
		
			when read1 =>
				if (read_counter<24 and integrity_counter/=3) then
					ch1_next(29 downto 0) <= ch1_reg(28 downto 0) & sdto1;
					integrity_counter_next <= integrity_counter + 1;
				elsif (read_counter<24 and integrity_counter=3) then
					ch1_next(29 downto 0) <= ch1_reg(27 downto 0) & '1' & sdto1;
					integrity_counter_next <= (others => '0');
				elsif (read_counter=24) then
					state_next_send <= send1;
					send_counter_next <= (others => '0');
					statesyncled_read <= '1';
				elsif (read_counter=31) then
					state_next_read <= read2;
					read_counter_next <= (others => '0');
				end if;
				
			when read2 =>
				if (read_counter<24 and integrity_counter/=3) then
					ch2_next(29 downto 0) <= ch2_reg(28 downto 0) & sdto1;
					integrity_counter_next <= integrity_counter + 1;
				elsif (read_counter<24 and integrity_counter=3) then
					ch2_next(29 downto 0) <= ch2_reg(27 downto 0) & '1' & sdto1;
					integrity_counter_next <= (others => '0');
				elsif (read_counter=31) then
					state_next_read <= read3;
					read_counter_next <= (others => '0');
				end if;
				
			when read3 =>
				if (read_counter<24 and integrity_counter/=3) then
					ch3_next(29 downto 0) <= ch3_reg(28 downto 0) & sdto1;
					integrity_counter_next <= integrity_counter + 1;
				elsif (read_counter<24 and integrity_counter=3) then
					ch3_next(29 downto 0) <= ch3_reg(27 downto 0) & '1' & sdto1;
					integrity_counter_next <= (others => '0');
				elsif (read_counter=31) then
					state_next_read <= read4;
					read_counter_next <= (others => '0');
				end if;
				
			when read4 =>
				if (read_counter<24 and integrity_counter/=3) then
					ch4_next(29 downto 0) <= ch4_reg(28 downto 0) & sdto1;
					integrity_counter_next <= integrity_counter + 1;
				elsif (read_counter<24 and integrity_counter=3) then
					ch4_next(29 downto 0) <= ch4_reg(27 downto 0) & '1' & sdto1;
					integrity_counter_next <= (others => '0');
				elsif (read_counter=31) then
					state_next_read <= idle_read;
					read_counter_next <= (others => '0');
				end if;
		end case;
		
		-- send state machine
		case state_reg_send is
			when idle_send =>
			
			when send1 =>
				ch1_next(29 downto 1) <= ch1_reg(28 downto 0);
				if (send_counter=29) then
					state_next_send <= send2;
					send_counter_next <= (others => '0');
				end if;
			
			when send2 =>
				ch2_next(29 downto 1) <= ch2_reg(28 downto 0);
				if (send_counter=29) then
					state_next_send <= send3;
					send_counter_next <= (others => '0');
				end if;
			
			when send3 =>
				ch3_next(29 downto 1) <= ch3_reg(28 downto 0);
				if (send_counter=29) then
					state_next_send <= send4;
					send_counter_next <= (others => '0');
				end if;
			
			when send4 =>
				ch4_next(29 downto 1) <= ch4_reg(28 downto 0);
				if(send_counter=29) then
					state_next_send <= send5;
					send_counter_next <= (others => '0');
					ch5678s_next <= '1';
				end if;
				
			when send5 =>
				if (send_counter=4 and ss5_counter/=23) then
					ch5678s_next <= '1';
					send_counter_next <= (others => '0');
					ss5_counter_next <= ss5_counter + 1;
				elsif (send_counter=4 and ss5_counter=23) then
					state_next_send <= send6;
					ch5678s_next <= '1';
					send_counter_next <= (others => '0');
					ss5_counter_next <= (others => '0');
				end if;
					
			when send6 =>
				if (send_counter=10) then
					ch5678s_next <= '1';
				elsif (send_counter=15) then
					send_counter_next <= (others => '0');
					statesyncled_send <='1';
				end if;
		end case;
	end process;
	
	
	-- output logic
	process(state_reg_send, ch1_reg, ch2_reg, ch3_reg, ch4_reg, ch5678s_reg)
	begin
		case state_reg_send is
			when idle_send =>
				tff_in <= '0';
				
			when send1 =>
				tff_in <= ch1_reg(29);
				
			when send2 =>
				tff_in <= ch2_reg(29);
				
			when send3 =>
				tff_in <= ch3_reg(29);
				
			when send4 =>
				tff_in <= ch4_reg(29);
				
			when send5 =>
				tff_in <= ch5678s_reg;
				
			when send6 =>
				tff_in <= ch5678s_reg;
		end case;
	end process;
				
end adatmitter_arch;

