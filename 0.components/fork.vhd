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

architecture eagerFork_RegisterBLock1 of eagerFork_RegisterBLock is
	signal reg_value, reg_in, block_stop_internal : std_logic;
begin
	
	block_stop_internal <= n_stop and reg_value;
	
	block_stop <= block_stop_internal;
	
	reg_in <= block_stop_internal or (not p_valid_and_fork_stop);
	
	valid <= reg_value and p_valid; 
	
	reg : process(clk, reset)
	begin
		if(reset='1') then
			reg_value <= '1'; --contains a "stop" signal - must be 1 at reset
		else
			if(rising_edge(clk))then
				reg_value <= reg_in;
			end if;
		end if;
	end process reg;
	
end eagerFork_RegisterBLock1;





------------------------------------------------------------------  Fork
------------------------------------------------------------------------
-- forks signals from one register controller to two other register
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
architecture lazy of fork is
begin

	valid0 <= p_valid and n_ready0 and n_ready1;
	valid1 <= p_valid and n_ready0 and n_ready1;
	
	ready <= n_ready0 and n_ready1;
	
end lazy;

------------------------------------------------------------------------
-- eager implementation (not functionnal)
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
					port map(clk, reset, p_valid, n_stop0, pValidAndForkStop, valid1, block_stop1);
	
end eager;





-----------------------------------------------------------------  andN
------------------------------------------------------------------------
-- size-generic AND gate used in the size-generic lazy fork
------------------------------------------------------------------------
LIBRARY IEEE;
USE ieee.std_logic_1164.all;
use work.customTypes.all;

ENTITY andN IS
GENERIC (n : INTEGER := 4);
PORT (	x : IN bitArray_t(N-1 downto 0);
		res : OUT STD_LOGIC);
END andN;

ARCHITECTURE vanilla OF andn IS
	SIGNAL tmp : bitArray_t(n-1 downto 0);
BEGIN
	tmp <= (OTHERS => '1');
	res <= '1' WHEN x = tmp ELSE '0';
END vanilla;





-----------------------------------------------------------------  ForkN
------------------------------------------------------------------------
-- size-generic fork bloc, made with the same logic as fork2
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity forkN is
generic( SIZE : integer);
port(	clk, reset,		-- the eager implementation uses registers
		pValid : in std_logic;
		nReadyArray : in bitArray_t(SIZE-1 downto 0);
		validArray : out bitArray_t(SIZE-1 downto 0);
		ready : out std_logic);
end forkN;

------------------------------------------------------------------------
-- lazy implementation
------------------------------------------------------------------------
architecture lazy of forkN is
	signal allPReady : std_logic;
begin

	genericAnd : entity work.andn generic map (SIZE)
			port map(nReadyArray, allPReady);
	
	valids : process(pValid, nReadyArray, allPReady)
	begin	
		for i in 0 to SIZE-1 loop
			validArray(i) <= pValid and allPReady;
		end loop;
	end process;
	
	ready <= allPReady;
	
end lazy;














