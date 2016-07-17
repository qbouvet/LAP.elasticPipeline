library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity TB_reg is
end TB_reg;

architecture testbench of TB_reg is

	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic;
	signal clk : std_logic := '0';
	
	constant CLK_PERIOD : time := 10 ns;
	
	-- component reg is port(
		-- clk : in std_logic;	
		-- reset : in std_logic;
		-- d_in : in std_logic_vector (31 downto 0);
		-- enable : in std_logic;
		-- d_out : out std_logic_vector(31 downto 0));
	-- end component;
	
	signal d_in, d_out : std_logic_vector (31 downto 0);
	signal enable : std_logic;
	
begin
	-- ticks the clock
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
	
-- run simulation
	sim : process is	
		procedure reset_sim is
		begin
			reset <= '1';
			enable <= '0';
			d_in <= (others => '0');
			wait until rising_edge(clk);
			wait for 3 * CLK_PERIOD / 4;
			reset <= '0';
		end procedure reset_sim;
	begin
		reset_sim;
		
		d_in <= X"00000005";
		wait until rising_edge(clk);
		enable <= '1';
		wait for 2 * CLK_PERIOD;
				
		finished <= true;
	end process;
	
-- instantiate component
	DUT : entity work.reg(reg1) port map(clk, reset, d_in, enable, d_out);
	
end testbench;
