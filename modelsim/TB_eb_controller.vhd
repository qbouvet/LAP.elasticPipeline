library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity TB_eb_controller is
end TB_eb_controller;

architecture testbench of TB_eb_controller is

	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;
	signal reset : std_logic := '1';
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 5 ns;
	
	signal selectBuggyScenario : boolean := true;
	
	component EB_controller is port (
		reset : in std_logic;
		clk : in std_logic;

		n_ready : in std_logic;
		p_valid : in std_logic;
		ready : out std_logic;
		valid : out std_logic;
		
		aux_wren : out std_logic;
		main_wren : out std_logic;
		mux_sel : out std_logic);
	end component;
	signal p_valid, n_ready : std_logic := '0';
	signal ready, valid : std_logic;
	signal aux_wren, main_wren, mux_sel : std_logic := '0';
			
begin
	
	simulation : process
		procedure reset_sim is 
		begin
			reset <= '1';
			p_valid <= '0';
			n_ready <= '0';
			wait until falling_edge(clk);
			wait for CLK_PERIOD / 4;
			reset <= '0';
		end procedure reset_sim;
	begin
		reset_sim;
			if(selectBuggyScenario) then
				--changes happen on rising clock
				wait until rising_edge(clk);
				p_valid <= '1';
				
				wait for CLK_PERIOD;
				wait for CLK_PERIOD;
			else
				-- changes happen mid-clock
				p_valid <= '1';
				wait for CLK_PERIOD;
				wait for CLK_PERIOD;
				
				n_ready <= '1';
				wait for CLK_PERIOD;
				
				p_valid <= '0';
				wait for CLK_PERIOD;
				wait for CLK_PERIOD;
				
				reset_sim;
			end if;		
		
		finished <= true;
	end process simulation;

	clock : process
    begin
        if (finished) then
            wait;
        else
            clk <= not clk;
            wait for CLK_PERIOD / 2;
            currenttime <= currenttime + CLK_PERIOD / 2;
        end if;
    end process clock;	
		
	DUT : EB_controller port map(
		reset, clk, n_ready, p_valid, 
		ready, valid, aux_wren, main_wren, mux_sel);
end testbench;