library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_adder is 
end tb_adder;

architecture testbench of tb_adder is 
	
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic;
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 10 ns;

	component adder is port (
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		res : out std_logic_vector(31 downto 0);
		carry : out std_logic);
	end component;
	signal a, b, res : std_logic_vector(31 downto 0);
	signal carry : std_logic;
begin
	
	--sim
	sim : process
		procedure reset_sim is
		begin
			reset <= '1';
			a <= (others => '0');
			b <= (others => '0');
			wait until rising_edge(clk);
			wait for CLK_PERIOD;
			reset <= '0';
		end procedure reset_sim;
	begin
		reset_sim;
		
		a <= X"00000001";
		b <= X"00000001";
		wait for CLK_PERIOD;
		wait for CLK_PERIOD * 3 / 4;
		a <= X"00000002";
		b <= X"00000002";
		wait for CLK_PERIOD;
		
		
	
		finished <= true;
	end process sim;
	
	-- DUT
	ad : adder port map(a, b, res, carry);
	
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
end testbench;
