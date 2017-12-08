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

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity boardTest is
	port (
		mclk : in std_logic;
		hwClk : in std_logic;
		Din : in std_logic;
		--Selector : in std_logic;
		mclk_out : out std_logic;
		hwClk_out : out std_logic;
		ffclk_out : out std_logic;
		systemClk_out : out std_logic;
		Dout : out std_logic
	);	
end boardTest;

architecture boardTest_arch of boardTest is	
	type systemStates is (idle, state1, state2, state3, state4);
	signal machineState, machineState_next : systemStates;
	
	-- input of T-flipflop
	signal tff_in : std_logic;
	signal tff_out : std_logic;
	
	-- clock divider
	signal fs_clock : std_logic;
	signal fs_counter : unsigned(7 downto 0) := "00000000";
	
	-- declaring system clock
	signal systemClk : std_logic;
	

begin	
	-- Clk selection
	-- systemClk <= mclk;
	systemClk <= hwClk;
	
	-- logic connections
	tff_in <= Din;
	
	process(systemClk)
	begin
		if (systemClk'event and systemClk='1') then
			-- state registers
			machineState <= machineState_next;
			
			-- T flip flop
			tff_out <= tff_in xor tff_out;
			
			-- clock divider for 48khz sample rate
			if (fs_counter=128) then
				fs_clock <= not(fs_clock);
				fs_counter <= (others => '0');
			else
				fs_counter <= fs_counter + 1;
			end if;
		end if;
	end process;
	
	-- next-state logic
	process(machineState)
	begin
		case machineState is
			when idle =>
				machineState_next <= state1;
			when state1 =>
				machineState_next <= state2;
			when state2 =>
				machineState_next <= state3;
			when state3 =>
				machineState_next <= state4;
			when state4 =>
				machineState_next <= idle;
		end case;
	end process;

	-- Sending out clocks
	mclk_out <= mclk;
	hwClk_out <= hwClk;
	systemClk_out <= systemClk;
	ffclk_out <= fs_clock;	
	
	-- output logic
	Dout <= tff_out;
				
end boardTest_arch;

