-----------------------------------------------------------------  ForkN
------------------------------------------------------------------------
-- size-generic fork bloc, made with the same logic as fork2
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity forkN is generic( SIZE : integer);
port(	clk, reset,		-- the eager implementation uses registers
		pValid : in std_logic;
		nReadyArray : in bitArray_t(SIZE-1 downto 0);
		ready : out std_logic;
		validArray : out bitArray_t(SIZE-1 downto 0));
end forkN;

------------------------------------------------------------------------
-- generic lazy implementation from cortadellas paper
------------------------------------------------------------------------
architecture lazy of forkN is
	signal allnReady : std_logic;
begin

	genericAnd : entity work.andn generic map (SIZE)
			port map(nReadyArray, allnReady);
	
	valids : process(pValid, nReadyArray, allnReady)
	begin	
		for i in 0 to SIZE-1 loop
			validArray(i) <= pValid and allnReady;
		end loop;
	end process;
	
	ready <= allnReady;
	
end lazy;

------------------------------------------------------------------------
-- generic eager implementation
------------------------------------------------------------------------
architecture eager of forkN is
-- wrapper signals (internals use "stop" signals instead of "ready" signals)
	signal forkStop : std_logic;
	signal nStopArray : bitArray_t(SIZE-1 downto 0);
-- internal combinatorial signals
	signal blockStopArray : bitArray_t(SIZE-1 downto 0);
	signal anyBlockStop : std_logic;
	signal pValidAndForkStop : std_logic;
begin
	
	--can't adapt the signals directly in port map
	wrapper : process(forkStop, nReadyArray)
	begin
		ready <= not forkStop;
		for i in 0 to SIZE-1 loop
			nStopArray(i) <= not nReadyArray(i);
		end loop;
	end process;
	
	genericOr : entity work.orN generic map (SIZE)
		port map(blockStopArray, anyBlockStop);
		
	-- internal combinatorial signals
	forkStop <= anyBlockStop; 
	pValidAndForkStop <= pValid and forkStop;
	
	--generate blocks
	generateBlocks : for i in SIZE-1 downto 0 generate
		regblock : entity work.eagerFork_RegisterBLock(vanilla)
				port map(	clk, reset,
							pValid, nStopArray(i),
							pValidAndForkStop,
							validArray(i), blockStopArray(i));
	end generate;
end eager;





-----------------------------------------------  eagerFork_RegisterBLock
------------------------------------------------------------------------
-- this block contains the register and the combinatorial logic 
-- around it, as in the design in cortadella elastis systems (paper 2)
-- page 3
-- a simple 2 way eager for uses 2 of those blocks
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity eagerFork_RegisterBLock is
port(	clk, reset, 
		p_valid, n_stop, 
		p_valid_and_fork_stop : in std_logic;
		valid, 	block_stop : out std_logic);
end eagerFork_RegisterBLock;

architecture vanilla of eagerFork_RegisterBLock is
	signal reg_value, reg_in, block_stop_internal : std_logic;
begin
	
	block_stop_internal <= n_stop and reg_value;
	
	block_stop <= block_stop_internal;
	
	reg_in <= block_stop_internal or (not p_valid_and_fork_stop);
	
	valid <= reg_value and p_valid; 
	
	reg : process(clk, reset, reg_in)
	begin
		if(reset='1') then
			reg_value <= '1'; --contains a "stop" signal - must be 1 at reset
		else
			if(rising_edge(clk))then
				reg_value <= reg_in;
			end if;
		end if;
	end process reg;
	
end vanilla;














------------------------------------------------------------------------------------   non size-generic versions




------------------------------------------------------------------  Fork
------------------------------------------------------------------------
-- forks signals from one register controller to several other register
-- controllers
-- contains both implementations from "Cortadella elastic systems", 
-- paper 2, p3
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fork is
port(	clk, reset,		-- the eager implementation uses registers
		p_valid,
		n_ready0, n_ready1 : in std_logic;
		ready, 
		valid0, valid1 : out std_logic);
end fork;

------------------------------------------------------------------------
-- lazy implementation
------------------------------------------------------------------------
architecture cortadellas of fork is
begin

	valid0 <= p_valid and n_ready0 and n_ready1;
	valid1 <= p_valid and n_ready0 and n_ready1;
	
	ready <= n_ready0 and n_ready1;
	
end cortadellas;

------------------------------------------------------------------------
-- lazy implementation (2) -- doesn't work
------------------------------------------------------------------------
architecture try of fork is
begin

	valid0 <= p_valid and n_ready1;
	valid1 <= p_valid and n_ready0;
	
	ready <= (n_ready0 and n_ready1) and p_valid;
	
end try;




------------------------------------------------------------------------
-- eager implementation
------------------------------------------------------------------------
architecture eager of fork is	
	signal fork_stop, block_stop0, block_stop1, n_stop0, n_stop1, pValidAndForkStop : std_logic;
begin

	--can't combine the signals directly in the port map
	n_stop0 <= not n_ready0;
	n_stop1 <= not n_ready1;
	fork_stop <= block_stop0 or block_stop1;
	pValidAndForkStop <=  p_valid and fork_stop;
					
	ready <= not fork_stop;

	regBlock0 : entity work.eagerFork_RegisterBLock 
					port map(clk, reset, p_valid, n_stop0, pValidAndForkStop, valid0, block_stop0);

	regBlock1 : entity work.eagerFork_RegisterBLock 
					port map(clk, reset, p_valid, n_stop1, pValidAndForkStop, valid1, block_stop1);
	
end eager;

