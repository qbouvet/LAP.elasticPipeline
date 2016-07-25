---------------------------------------------------------------  join
---------------------------------------------------------------------
-- joins the control signals of 2 elastic buffers into a single 
-- control signal. Simple version without anti-tokens stuff.
-- implementation from "Cortadella elastic systems", paper 2, p3
library ieee;
use ieee.std_logic_1164.all;

entity join is
port(
	p_valid1, p_valid0, n_ready : in std_logic;
	valid, ready0, ready1 : out std_logic);
end join;

architecture lazy of join is
begin

	valid <= p_valid0 and p_valid1;
	-- is the first term necessary ??          
	ready0 <= (not p_valid0) or (p_valid0 and p_valid1 and n_ready); 
	ready1 <= (not p_valid1) or (p_valid0 and p_valid1 and n_ready); 

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
