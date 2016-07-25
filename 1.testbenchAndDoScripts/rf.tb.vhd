library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity TB_rf is
end TB_rf;

architecture testbench of TB_rf is
	
	signal finished : boolean := false;
	signal currenttime : time := 0 ns;
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 10 ns;
	
	signal wr_enable : std_logic;
	signal adr_a, adr_b, wr_adr, wr_data, aa, ab : std_logic_vector(31 downto 0);
	signal reset : std_logic; --not used by the component
	
begin
	
	sim : process
		procedure reset_sim is
		begin
			reset <= '1';
			wr_enable <= '0';
			adr_a <= (others => '0');
			adr_b <= (others => '0');
			wr_adr <= (others => '0');
			wr_data <= (others => '0');
			wait until rising_edge(clk);
			wait for 3 * CLK_PERIOD / 4;
			reset <= '0';
		end procedure reset_sim;
	begin
		reset_sim;
	-- basic simulation
		wr_enable <= '1';
		adr_a <= X"00000001";
		adr_b <= X"00000002";
		wr_data <= X"00000001";
		wr_adr <= X"00000001";
		wait for CLK_PERIOD;
		wr_data <= X"00000002";
		wr_adr <= X"00000002";
		wait for CLK_PERIOD;
		wait for CLK_PERIOD / 4;
		assert aa = X"00000001" report "incorrect output a" severity error;
		assert ab = X"00000002" report "incorrect output b" severity error;
		
	-- some more
		wait until rising_edge(clk);
		wait for CLK_PERIOD / 4;
		wr_adr <= X"00000001";
		wr_data <= X"0000000F";
		wait for CLK_PERIOD;
		wr_adr <= X"00000002";
		assert aa = X"0000000F" report "incorrect output a" severity error;
		wait for CLK_PERIOD;
		assert ab = X"0000000F" report "incorrect output b" severity error;
		
		
		wait for CLK_PERIOD;
		finished <= true;
		assert false report "simulation finished" severity note;
	end process sim;
	
	-- design under test
	DUT : entity work.regFile(regFile1) port map (
		clk, reset, adr_a, adr_b, aa, ab, wr_enable, wr_adr, wr_data, '1', '1', '1', '1', open, open, open, open, open);
	--entity regFile is port(
	--clk, reset : in std_logic;
	--adr_a, adr_b : in std_logic_vector(31 downto 0);
	--aa, ab : out std_logic_vector(31 downto 0);
	--adr_validWr : in std_logic; -- replaces wr_enable : we now write whenever there's valid data incomming 
	--wr_adr, wr_data : in std_logic_vector(31 downto 0);		
	--adr_validA, n_readyA, adr_validB, n_readyB : in std_logic;
	--readyA, validA, readyB, validB, readyWr : out std_logic
	--);
		
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
