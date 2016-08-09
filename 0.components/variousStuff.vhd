---------------------------------------------------------  misc.vhd
---------------------------------------------------------------------
-- this file contains simple components used here and there 
-- 							...
-- and also some maybe useless stuff for backup purpose
---------------------------------------------------------------------
---------------------------------------------------------------------







-----------------------------------------------------------------  andN
------------------------------------------------------------------------
-- size-generic AND gate used in the size-generic lazy fork and join
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
	SIGNAL dummy : bitArray_t(n-1 downto 0);
BEGIN
	dummy <= (OTHERS => '1');
	res <= '1' WHEN x = dummy ELSE '0';
END vanilla;

-----------------------------------------------------------------  orN
------------------------------------------------------------------------
-- size-generic OR gate used in the size-generic eager fork and join
------------------------------------------------------------------------
LIBRARY IEEE;
USE ieee.std_logic_1164.all;
use work.customTypes.all;

ENTITY orN IS
GENERIC (n : INTEGER := 4);
PORT (	x : IN bitArray_t(N-1 downto 0);
		res : OUT STD_LOGIC);
END orN;

ARCHITECTURE vanilla OF orN IS
	SIGNAL dummy : bitArray_t(n-1 downto 0);
BEGIN
	dummy <= (OTHERS => '0');
	res <= '0' WHEN x = dummy ELSE '1';
END vanilla;












------------------------------------------------------------------------ old stuff
------------------------------------------------------------------------




---------------------------------------------------------  forkBlock3
---------------------------------------------------------------------
-- rassembles 2 simple forks into a 3 way fork.
-- used in other components
library ieee;
use ieee.std_logic_1164.all;

entity forkBlock3 is
port(	clk, reset, 
		p_valid, n_ready0, n_ready1, n_ready2 : in std_logic;
		valid0, valid1, valid2, ready : out std_logic;
);

architecture lazy of forkBlock3 is

	signal f0_ready1, f0_valid1 : std_logic;
			
	
begin
	fork0 : entity work.fork(lazy) --the first fork outputs to the output and to the other fork
		port map(clk, reset, p_valid, n_ready0, f0_ready1, ready, valid0, f0_valid1);
	fork1 : entity work.fork(lazy) 
		port map(clk, reset, f0_valid1, n_ready1, n_ready2, f0_ready1, valid1, valid2);
end lazy;




---------------------------------------------------------  joinBlock3
---------------------------------------------------------------------
-- rassembles 2 simple joins into a 3 way join.
-- used in other components
library ieee;
use ieee.std_logic_1164.all;

entity joinBlock3 is
port(	p_valid0, p_valid1, p_valid2, n_ready : in std_logic;
		valid, ready0, ready1, ready2 : out std_logic
);

architecture lazy of joinBlock3 is
	signal j1_ready, j0_valid : std_logic;
begin

	join0 : entity work.join(lazy) 
			port map(p_valid0, p_valid1, j1_ready, j0_valid, ready0, ready1);
	join1 : entity work.join(lazy) 
			port map(j0_valid, p_valid2, n_ready, valid, j1_ready, ready2);

end lazy;
