library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.customTypes.all;

entity tb_forkEager is 
end tb_forkEager;

------------------------------------------------------------------------
-- testbench for the generic eager fork, size 2
------------------------------------------------------------------------
architecture size5 of tb_forkEager is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;
	
	signal 	pValid : std_logic := '0'; --in
	signal nReadyArray, validArray : bitArray_t(4 downto 0);
	signal	ready : std_logic; --out
	
begin
	
	-- run simulation
	sim : process
		procedure resetSim is
			begin
				reset <= '1';
				pValid <= '0';
				nReadyArray <= (others => '0');
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
			assert validArray = "00000" report "(1)";
			assert ready = '0' report "(2)";
			
			nReadyArray <= "00001";		-- branch 0 is ready, but there's no valid data yet
			waitPeriod(1);
			assert validArray = "00000" report "(2)";
			assert ready = '0' report "(3)";
			
			pValid <= '1';		-- now there's valid data
			waitPeriod(0.5);
			assert validArray = "11111" report "(4)"; --all branhces must announce the valid data
			waitPeriod(0.5);
			assert validArray = "11110" report "(5)"; -- branch 0 received the data, so fork no longer announces valid data to it
			
			waitPeriod(1);
			assert validArray = "11110" report "(5)"; -- still in the same situation
			
			nReadyArray <= "01111";
			assert validArray = "11110" report "(6)"; -- none of the remaining branches received the data
			waitPeriod(1);
			assert validArray = "10000" report "(7)"; -- all ready branches received the data, only branch 4 hasn't received yet 
			assert ready = '0' report "(8)";	-- branch 4 stops the fork
			
			nReadyArray <= "11111";
			waitPeriod(0.5); -- wait because ready depends directly on nReady0
			assert ready <= '1' report "(10)"; -- at rising edge, all branches will have been served, so the fork can ask for the next piece of data
			assert validArray = "10000" report "(11)"; -- only the 4th branch hadn't received data
			waitPeriod(0.5); --rising edge happens there 
			
			pValid <= '0'; -- the data has been transmitted through the fork, there's no more valid data
			waitPeriod(1);
			assert validArray = "00000" report "(12)";
			
			nReadyArray <= "11111"; -- was already 11111 before, just to make sure
			pValid <= '1';
			waitPeriod(1);
			assert validArray = "11111" report "(13)";	-- data should flow as long as all is ready
			assert ready = '1' report "(14)";
			waitPeriod(1);
			assert validArray = "11111" report "(13)";
			assert ready = '1' report "(14)";
			waitPeriod(1);
			assert validArray = "11111" report "(13)";
			assert ready = '1' report "(14)";
			
			
			print("simulation finished");
			
		end if;		
		finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.forkN(eager) generic map(5)
		port map(	clk, reset, 
					pValid, 
					nReadyArray, 
					ready, 
					validArray);
	
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
      
end size5;

------------------------------------------------------------------------
-- testbench for the generic eager fork, size 2
------------------------------------------------------------------------
architecture size2 of tb_forkEager is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;
	
	signal 	pValid, nReady0, nReady1 : std_logic := '0'; --in
	signal	ready, valid0, valid1 : std_logic; --out
	
	signal internalNReadyArray, internalValidArray : bitArray_t(1 downto 0);
	
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

			pValid <= '0';
			nReady0 <= '0';
			nReady1 <= '0';
			waitPeriod(1);
			assert valid0 = '0' report "(1)";
			assert valid1 = '0' report "(2)";
			assert ready = '0' report "(3)";
			
			nReady1 <= '1';		-- branch 1 is ready, but there's no valid data yet
			waitPeriod(1);
			assert valid0 = '0' report "(4)";
			assert valid1 = '0' report "(5)"; -- pValid still = 0
			
			pValid <= '1';		-- now there's valid data
			waitPeriod(0.5);
			assert valid0 = '1' report "(6)"; -- both branches should announce the valid data
			assert valid1 = '1' report "(7)";
			waitPeriod(0.5);
			assert valid1 = '0' report "(7.5)"; -- after rising edge, branch 1 got the data, so there's no more valid data for this branch
			
			waitPeriod(1);
			assert valid1 = '0' report "(8)"; -- still only the old data
			
			nReady0 <= '1';
			assert valid0 = '1' report "(9)"; -- the data was announced for a while on this branch
			waitPeriod(0.5); --because ready depends directly on nReady0
			assert ready <= '1' report "(10)"; -- at rising edge, all branches will have been served, so the fork can ask for the next piece of data
			waitPeriod(0.5);
			
			pValid <= '0'; -- there's no more valid data
			waitPeriod(1);
			assert valid0 = '0' report "(11)";
			assert valid1 = '0' report "(12)";
			
			pValid <= '1';
			nReady0 <= '1';
			nReady1 <= '1';
			waitPeriod(1);
			assert valid0 = '1' report "(13)";
			assert valid1 = '1' report "(14)";
			waitPeriod(1);
			assert valid0 = '1' report "(15)";
			assert valid1 = '1' report "(16)";
			waitPeriod(1);
			assert valid0 = '1' report "(17)";
			assert valid1 = '1' report "(18)";
			
			print("simulation finished");
			
		end if;		
		finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.forkN(eager) generic map(2)
		port map(	clk, reset, 
					pValid, 
					internalNReadyArray, 
					ready, 
					internalValidArray);
	-- wrapping signals
	internalNReadyArray <= (nReady1, nReady0);
	(valid1, valid0) <= internalValidArray;
	
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
      
end size2;







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
	
	signal pValid, n_stop, otherBlock_stop, fork_stop, forkStopAndPValid : std_logic;
	signal valid, block_stop : std_logic; -- out
	
begin
	
	fork_stop <= block_stop or otherBlock_stop;
	forkStopAndPValid <= pValid and fork_stop;
	
	-- run simulation
	sim : process
		procedure resetSim is
			begin
				reset <= '1';
				pValid <= '0';
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
	resetSim;
	if(not finished)then 
		
		pValid <= '1';		-- valid data, but next not ready
		waitPeriod(1);
		assert valid = '1' report "(0)";
		
		n_stop <= '0';		-- next gets ready
		waitPeriod(1);
		assert block_stop = '0' report "(1)"; -- got data, should no longer be able to block the fork
		assert forkStopAndPValid = '1' report "(2)"; -- the other block still blocks though
		assert valid='0' report"(3)"; -- due to forkStopAndPValid='1' and n_stop='0', the register should have taken a 0, hence...
		
		otherBlock_stop <= '0';
		waitPeriod(1); -- the other block got data, now we can remain valid as long as the other block doesn't stop and there's valid data
		assert valid='1' report "(4)"; 
		
		waitPeriod(1);
		assert valid='1' report "(5)";
		
		waitPeriod(1);
		assert valid='1' report "(6)";
		
		pValid <= '0';
		waitPeriod(1);
		assert valid='0' report "(7)"; -- there's no longer valid data
		
		pValid <= '1';
		n_stop <= '1';	-- now we're blocking the fork
		waitPeriod(1);
		assert valid='1' report "(8)"; --there's valid data...
		assert block_stop='1' report "(9)"; -- ...but we're blocking the fork
		
		waitPeriod(1);
		assert valid='1' report "(10)"; -- still blocking
		assert block_stop='1' report "(11)";
		
		n_stop <= '0';
		waitPeriod(1);	-- we're no longer blocking
		assert block_stop='0' report "(12)";
		
		waitPeriod(1);
		assert false report "simulation finished" severity warning;
		
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.eagerFork_RegisterBLock 
		port map( clk, reset, pValid, n_stop, forkStopAndPValid, valid, block_stop);
		--port(	clk, reset, 
		--pValid, n_stop, 
		--pValid_and_fork_stop : in std_logic;
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

