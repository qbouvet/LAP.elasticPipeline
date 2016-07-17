library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity TB_opu is 
end TB_opu;

architecture testbench of TB_opu is
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic;
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 10 ns;
	
	component OP_unit is port(
		clk, reset : in std_logic;
		argA, argB : in std_logic_vector (31 downto 0);
		immArg : in std_logic_vector (15 downto 0);
		op, opx : in std_logic_vector (5 downto 0);
		instr, oc : in std_logic_vector(31 downto 0);
		res : out std_logic_vector (31 downto 0));
	end component;

	signal instr, argA, argB, oc, res : std_logic_vector(31 downto 0);
	signal immArg : std_logic_vector(15 downto 0);
	signal op, opx : std_logic_vector (5 downto 0);
	
begin
	
	sim : process
		procedure reset_sim is
		begin
			reset <= '1';
			instr <= (others => '0');
			oc <= (others => '0');
			immArg <= (others => '0');
			op <= (others => '0');
			opx <= (others => '0');
			argA <= (others => '0');
			argB <= (others => '0');
			wait for CLK_PERIOD;
			wait until rising_edge(clk);
			reset <= '0';
		end procedure;
	begin
		reset_sim;
		
		op <= "100000";
		immArg <= X"0001";
		argA <= X"00000001";
		
		wait for 5 ns;
		
		op <= "000000";
		opx <= "000001";
		argA <= X"00000001";
		argB <= X"00000010";
		
		wait for 5 ns;
		finished <= true;
	end process sim;

	-- DUT insance
	opu : OP_unit port map (clk, reset, argA, argB, immArg, op, opx, instr, oc, res);
	
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
	
	
	
	
	
	
	
	
	
	
	
	
	
	