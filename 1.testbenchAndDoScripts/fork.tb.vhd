----------------------------------------------------------------- tb_fork
------------------------------------------------------------------------
-- set of tests for the different implementations of fork we have
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.customTypes.all;

entity tb_fork is 
end tb_fork;






------------------------------------------------------------------------
-- tests the generic fork, SIZE=2 ,lazy version (same tests as fork2(lazy)
------------------------------------------------------------------------
architecture generic_size2_lazy of tb_fork is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;	
	
	signal pValid, ready : std_logic;
	signal nReadyArray, validArray : bitArray_t(1 downto 0);
	
begin
	
	-- run simulation
	sim : process
		--simulation reset
		procedure resetSim is
			begin
				reset <= '1';
				pValid <= '0';
				nReadyArray <= (others => '0');
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
		--waiting procedures
		procedure waitPeriod(constant i : in real) is
		begin
			wait for i * CLK_PERIOD;
		end procedure;		
		procedure waitPeriod(constant i : in integer) is
		begin
			wait for i * CLK_PERIOD;
		end procedure;	
		--text output procedures
		variable console_out : line;
		procedure newline is
		begin
			console_out := new string'("");
			writeline(output, console_out);
		end procedure newline;
		procedure print(msg : in string) is
		begin
			console_out := new string'(msg);
			writeline(output, console_out);
		end procedure print;
		-- finished procedures
	begin
	if(not finished)then 
		resetSim;
		newline; print("simulation begins");
		
		pValid <= '1';
		waitPeriod(1);
		assert ready='0' severity error;
		assert validArray="00" severity error;
		
		nReadyArray <= "01";
		waitPeriod(1);
		assert ready='0' severity error;
		assert validArray="00" severity error;
		
		nReadyArray <= "01";
		waitPeriod(1);
		assert ready='0' severity error;
		assert validArray="00" severity error;
		
		nReadyArray <= "11";
		waitPeriod(1);
		assert ready='1' severity error;
		assert validArray="11" severity error;
		
		pValid <= '0';
		waitPeriod(1);
		assert ready='1' severity error;
		assert validArray="00" severity error;
		
	end if;
	newline;print("simulation finished");
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.forkN(lazy) generic map(2)
			port map( 	clk, reset,
						pValid,
						nReadyArray,	
						validArray,
						ready );
	
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
      
end generic_size2_lazy;








------------------------------------------------------------------------
-- tests the fork2, lazy version
------------------------------------------------------------------------
architecture lazy of tb_fork is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;	
	
	signal pValid, nReady0, nReady1, ready, valid0, valid1 : std_logic;
	
begin
	-- run simulation
	sim : process
		--simulation reset
		procedure resetSim is
			begin
				reset <= '1';
				pValid <= '0';
				nReady1 <= '0';
				nReady0 <= '0';
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
		--waiting procedures
		procedure waitPeriod(constant i : in real) is
		begin
			wait for i * CLK_PERIOD;
		end procedure;		
		procedure waitPeriod(constant i : in integer) is
		begin
			wait for i * CLK_PERIOD;
		end procedure;	
		--text output procedures
		variable console_out : line;
		procedure newline is
		begin
			console_out := new string'("");
			writeline(output, console_out);
		end procedure newline;
		procedure print(msg : in string) is
		begin
			console_out := new string'(msg);
			writeline(output, console_out);
		end procedure print;
		-- finished procedures
	begin
	if(not finished)then 
		resetSim;
		newline; print("simulation begins");
		
		pValid <= '1';
		waitPeriod(1);
		assert ready='0' report "1" severity error;
		assert valid0='0' report "2" severity error;
		assert valid1='0' report "2" severity error;
		
		nReady0 <= '1';
		waitPeriod(1);
		assert ready='0' report "3" severity error;
		assert valid0='0' report "4" severity error;
		assert valid1='0' report "4" severity error;
		
		nReady1 <= '1';
		waitPeriod(1);
		assert ready='1' report "5" severity error;
		assert valid0='1' report "6" severity error;
		assert valid1='1' report "6" severity error;
		
		pValid <= '0';
		waitPeriod(1);
		assert ready='1' report "7" severity error;
		assert valid0='0' report "8" severity error;
		assert valid1='0' report "8" severity error;
		

	end if;
	newline;print("simulation finished");
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.fork(lazy)
			port map( 	clk, reset,
						pValid,
						nReady0, nReady1,
						ready, 
						valid0, valid1);
	
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
      
end lazy;
