library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_forkEager is 
end tb_forkEager;

architecture testbench of tb_forkEager is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;
	
	signal 	p_valid, n_ready0, n_ready1 : std_logic := '0'; --in
	signal	ready, valid0, valid1 : std_logic; --out
	
begin
	
	-- run simulation
	sim : process
		procedure resetSim is
			begin
				reset <= '1';
				wait until rising_edge(clk);
				wait for(3 * CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;
		procedure waitPeriod(constant i : in integer) is
		begin
			for n in 1 to i loop
				wait for CLK_PERIOD;
			end loop;
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
	begin
		if(not finished) then
			resetSim;	
			waitPeriod(2);
			
			p_valid <= '1';
			n_ready0 <= '1';
			n_ready1 <= '1';
			waitPeriod(2);
			
			n_ready0 <= '0';
			waitPeriod(1);
			n_ready0 <='1';
			waitPeriod(1);
			
			n_ready0 <= '0';
			n_ready1 <= '0';
			waitPeriod(1);
			n_ready0 <= '1';
			waitPeriod(1);
			
		
		end if;		
		finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.fork(eager) 
		port map(clk, reset, p_valid, n_ready0, n_ready1, ready, valid0, valid1);
		--port(	clk, reset,		-- the eager implementation uses registers
		--		p_valid,
		--		n_ready0, n_ready1 : in std_logic;
		--		ready, valid0, valid1 : out std_logic);
	
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







-- quick testbench for the registerblock component of fork(eager)
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_forkEager_RegisterBLock is 
end tb_forkEager_RegisterBLock;

architecture testbench of tb_forkEager_RegisterBLock is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;	
	
	signal p_valid, n_stop, fork_stop, forkStopAndPValid : std_logic;
	signal valid, block_stop : std_logic;
	
begin
	
	forkStopAndPValid <= p_valid and fork_stop;
	
	-- run simulation
	sim : process
		procedure resetSim is
			begin
				reset <= '1';
				p_valid <= '0';
				n_stop <= '1';
				fork_stop <= '1';
				wait until rising_edge(clk);
				wait for(3 * CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;
		procedure waitPeriod(constant i : in integer) is
		begin
			for n in 1 to i loop
				wait for CLK_PERIOD;
			end loop;
		end procedure;		
	begin
	if(not finished)then 
		
		resetSim;
		waitPeriod(2);
		
		n_stop <= '0';
		p_valid <= '1';
		fork_stop <='0';
		
		waitPeriod(2);		
		
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.eagerFork_RegisterBLock 
		port map( clk, reset, p_valid, n_stop, forkStopAndPValid, valid, block_stop);
		--port(	clk, reset, 
		--p_valid, n_stop, 
		--p_valid_and_fork_stop : in std_logic;
		--valid, 	block_stop : out std_logic);
	
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

