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
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;
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
	begin
		if(not finished) then
			resetSim;	

			p_valid <= '1';
			n_ready0 <= '1';
			n_ready1<= '0';
			waitPeriod(0.1); -- cannot assert directly on signals depending on an immediate assignment
			assert valid0 = '1' report "there is valid data, we should send it" severity error;
			assert valid1 = '1' report "there is valid data, we should announce it" severity error;
			assert ready = '0' report "fork should stop, channel 1 not ready" severity error;
			waitPeriod(0.9);
			assert valid0 = '0' report "data has been sent but channel1 is blocking the fork" severity error;
			assert valid1 = '1' report "there is valid data, we still should announce it" severity error;
			assert ready = '0' report "fork should stop, channel 1 still not ready" severity error;
			n_ready1 <= '1';
			waitPeriod(1);
			assert valid0 ='1' report "no channels are blocked, data shoudl flow" severity error;
			assert valid1 ='1' report "no channels are blocked, data shoudl flow (2)" severity error;
			assert ready = '1'report "no channels are blocked, data shoudl flow (3)" severity error;
			
			waitPeriod(2);
			
		
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
	
	signal p_valid, n_stop, otherBlock_stop, fork_stop, forkStopAndPValid : std_logic;
	signal valid, block_stop : std_logic; -- out
	
begin
	
	fork_stop <= block_stop or otherBlock_stop;
	forkStopAndPValid <= p_valid and fork_stop;
	
	-- run simulation
	sim : process
		procedure resetSim is
			begin
				reset <= '1';
				p_valid <= '0';
				n_stop <= '1';
				otherBlock_stop <= '1';
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;
		procedure waitPeriod(constant i : in real) is
		begin
			wait for i * CLK_PERIOD;
		end procedure;		
		procedure waitPeriod(constant i : in integer) is
		begin
			wait for i * CLK_PERIOD;
		end procedure;
	begin
	if(not finished)then 
		
		resetSim;
		
		p_valid <= '1';
		otherBlock_stop <='1';
		n_stop <= '0';	
		waitPeriod(0.1); --can't assert directly on those signals, since dependant on the assignment we just did
		assert block_stop='0' report "when the other channel is not ready, this block doesn't stop the fork" severity error;
		assert valid='1' report"on the first cycle, it transmits the data since the next block is ready" severity error;
		waitPeriod(0.9);
		assert valid='0' report "since it transmitted data, it now has no more valid data until next channel unlocks" severity error;
		otherBlock_stop <= '0';
		waitPeriod(1);
		assert valid='1' report "other channel unlocked, P-valid still 1, so new data has arrived and we should now be valid" severity error;
		waitPeriod(1);
		
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

