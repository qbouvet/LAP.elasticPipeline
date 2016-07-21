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

architecture join1 of join is
begin

	valid <= p_valid0 and p_valid1;
	-- is the first term necessary ??          
	ready0 <= (not p_valid0) or (p_valid0 and p_valid1 and n_ready); 
	ready1 <= (not p_valid1) or (p_valid0 and p_valid1 and n_ready); 

end join1;
