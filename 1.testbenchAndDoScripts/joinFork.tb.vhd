-------------------------------------------------------- forkjoin.tb.vhd
------------------------------------------------------------------------
-- this file aims to test a join and a fork chaned together to make 
-- sure they behave as a normal wire
------------------------------------------------------------------------


------------------------------------------------------------------------
-- test joins and forks
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity testfork is port(	
	pValid, 
	nStop0, nStop1 : in std_logic;
	stop,
	valid0, valid1 : out std_logic);
end testfork;

architecture cortadellas of testfork is 
begin
	stop <= nStop0 or nStop1;
	valid0 <= pValid and not ( nStop0 or nStop1);
	valid1 <= pValid and not ( nStop0 or nStop1);
end cortadellas;

library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity testjoin is port(
	pValid0, pValid1,
	nStop : in std_logic;
	stop0, stop1,
	valid : out std_logic);
end testjoin;

architecture cortadellas of testjoin is
begin
	stop0 <= pValid0 and not (pValid0 and pValid1 and (not nStop));
	stop1 <= pValid1 and not (pValid0 and pValid1 and (not nStop));
	valid <= pValid0 and pValid1;
end cortadellas;


------------------------------------------------------------------------								-------
-- a bunch of joins and fork in the same configuration as in the OP unit
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity likeOPunit_forkjoin is port(
	clk, reset : in std_logic;
	pValidArray : in bitArray_t(3 downto 0); -- (argB, argA, argI, oc)
	nReady : in std_logic;
	readyArray: out bitArray_t(3 downto 0); -- (argB, argA, argI, oc)
	valid : out std_logic);
end likeOPunit_forkjoin;
	
architecture vanilla of likeOPunit_forkjoin is
	signal forkValidArray,	j0ReadyArray, j1ReadyArray : bitArray_t(1 downto 0); -- (branch0, branch1), (argA, argI), (argB, argA)
	signal j0Valid, j1Valid : std_logic;
	signal j3ReadyArray : bitArray_t(2 downto 0); -- (branch1, branch0, oc)
	signal pValidArrayForJoin3 : bitArray_t(2 downto 0);
begin
	
	forkA : entity work.fork(eager) 
			port map(	clk, reset,	
						pValidArray(2),
						j0ReadyArray(1), j1ReadyArray(0),
						readyArray(2),
						forkValidArray(0), forkValidArray(1));
	
	j0 : entity work.join(cortadellas)
			port map(	forkValidArray(1), pValidArray(1), j3ReadyArray(1),
						j0Valid, j0ReadyArray(1), j0ReadyArray(0));
	readyArray(1) <= j0ReadyArray(0);
	
	j1 : entity work.join(cortadellas)
			port map(	forkValidArray(0), pValidArray(3), j3ReadyArray(2),
						j1Valid, j1ReadyArray(1), j1ReadyArray(0));
	readyArray(3) <= j1ReadyArray(0);
	
	pValidArrayForJoin3 <= (j1Valid, j0Valid, pValidArray(0));
	j3 : entity work.join3(lazy)
			port map (	pValidArrayForJoin3,
						nReady,	
						valid, 
						j3ReadyArray);
	readyArray(0) <= j3ReadyArray(0);						
	
end vanilla;

------------------------------------------------------------------------
-- testbench for the "likeOPunit configuration
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity tb_likeOPunit_forkjoin is
end tb_likeOPunit_forkjoin;

architecture testbench of tb_likeOPunit_forkjoin is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;
	
	signal pValidArray : bitArray_t(3 downto 0); -- (argB, argA, argI, oc)
	signal nReady : std_logic;
	signal readyArray: bitArray_t(3 downto 0); -- (argB, argA, argI, oc)
	signal valid :  std_logic;
	
begin

	-- run simulation
	sim : process
		-- reset procedure
		procedure resetSim is
			begin
				reset <= '1';
				pValidArray <= (others => '0');
				nReady <= '0';
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
		--waiting procedures
		procedure waitPeriod(constant i : in real) is
		begin	wait for i * CLK_PERIOD;
		end procedure;		
		procedure waitPeriod is
		begin	wait for 2*CLK_PERIOD;
		end procedure;
		procedure waitPeriod(constant i : in integer) is
		begin	wait for i * CLK_PERIOD;
		end procedure;	
		-- finished procedures
	begin
	resetSim;
	if(not finished)then 
		
		nReady <= '0';	--when the next component is not ready
		pValidArray <= "0000";
		waitPeriod;
		
		pValidArray <= "1110";
		waitPeriod;
		
		pValidArray <= "1101";
		waitPeriod;
		
		pValidArray <= "1011";
		waitPeriod;
		
		pValidArray <= "0111";
		waitPeriod;
		
		pValidArray <= "1111";
		waitPeriod;
		
		nReady <= '1';	-- wwhen it is
		pValidArray <= "0000";
		waitPeriod;
		
		pValidArray <= "1110";
		waitPeriod;
		
		pValidArray <= "1101";
		waitPeriod;
		
		pValidArray <= "1011";
		waitPeriod;
		
		pValidArray <= "0111";
		waitPeriod;
		
		pValidArray <= "1111";
		waitPeriod;
		
	end if;
	finished <= true;
	end process;

	-- instantiate design under test
	DUT : entity work.likeOPunit_forkjoin
			port map(	clk, reset,	
						pValidArray, nReady, readyArray, valid);
	
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



------------------------------------------------------------------------								-------
-- the join and fork chained together	
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity forkjoin is port(
	clk, reset,
	pValid, nReady : in std_logic;
	ready, valid : out std_logic;
	validArray_out, readyArray_out : out bitArray_t(1 downto 0));  --for observation purpose
end forkjoin;

architecture vanilla of forkjoin is 
	signal validArray, readyArray : bitArray_t(1 downto 0);
begin

	f : entity work.fork(cortadellas)
			port map(	clk, reset,	
						pValid, 
						readyArray(1), readyArray(0),
						ready, 
						validArray(1), validArray(0));
	
	j : entity work.join(cortadellas)
			port map( 	validArray(1), validArray(0),
						nReady,
						valid,
						readyArray(1), readyArray(0));
						
	validArray_out <= validArray;
	readyArray_out <= readyArray;

end vanilla;

architecture eagerFork of forkjoin is 
	signal validArray, readyArray : bitArray_t(1 downto 0);
begin

	f : entity work.fork(eager)
			port map(	clk, reset,	
						pValid, 
						readyArray(1), readyArray(0),
						ready, 
						validArray(1), validArray(0));
	
	j : entity work.join(cortadellas)
			port map( 	validArray(1), validArray(0),
						nReady,
						valid,
						readyArray(1), readyArray(0));
						
	validArray_out <= validArray;
	readyArray_out <= readyArray;

end eagerFork;

architecture try of forkjoin is 
	signal validArray, readyArray : bitArray_t(1 downto 0);
begin

	f : entity work.fork(eager)
			port map(	clk, reset,	
						pValid, 
						readyArray(1), readyArray(0),
						ready, 
						validArray(1), validArray(0));
	
	j : entity work.join(try)
			port map( 	validArray(1), validArray(0),
						nReady,
						valid,
						readyArray(1), readyArray(0));
						
	validArray_out <= validArray;
	readyArray_out <= readyArray;

end try;

architecture testversions of forkjoin is
	signal nStop, stop, valid0, valid1, stop0, stop1 : std_logic;
begin
	nStop <= not nReady;
	ready <= not stop;
	
	f : entity work.testfork
			port map(	pValid,
						stop0, stop1,
						stop, 
						valid0, valid1);
	
	j : entity work.testjoin
			port map(	valid0, valid1,
						nStop, 
						stop0, stop1,
						valid);
end testversions;

			--entity forkN is generic( SIZE : integer);
			--port(	clk, reset,		-- the eager implementation uses registers
					--pValid : in std_logic;
					--nReadyArray : in bitArray_t(SIZE-1 downto 0);
					--ready : out std_logic;
					--validArray : out bitArray_t(SIZE-1 downto 0));
			--end forkN;

			--entity join is
			--port(
			--	p_valid1, p_valid0, n_ready : in std_logic;
			--	valid, ready1, ready0 : out std_logic);
			--end join;




------------------------------------------------------------------------
-- the testbench
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.customTypes.all;

entity tb_forkjoin is 
end tb_forkjoin;

architecture testbench of tb_forkjoin is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;	
	
	signal pValid, nReady, valid, ready : std_logic;
	signal validArray_out, readyArray_out : bitArray_t(1 downto 0);
	
begin
	
	-- run simulation
	sim : process
		-- reset procedure
		procedure resetSim is
			begin
				reset <= '1';
				pValid <= '0';
				nReady <= '0';
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
		--waiting procedures
		procedure waitPeriod(constant i : in real) is
		begin	wait for i * CLK_PERIOD;
		end procedure;		
		procedure waitPeriod(constant i : in integer) is
		begin	wait for i * CLK_PERIOD;
		end procedure;	
		-- finished procedures
	begin
	resetSim;
	if(not finished)then 
		
		pValid <= '0';
		nReady <= '0';
		waitPeriod(1);
		
		pValid <= '1';
		nReady <= '0';
		waitPeriod(1);
		
		pValid <= '0';
		nReady <= '1';
		waitPeriod(1);
		
		pValid <= '1';
		nReady <= '1';
		waitPeriod(1);
		
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.forkjoin(try) 
			port map(	clk, reset, pValid, nReady, ready, valid, validArray_out, readyArray_out);
	
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
