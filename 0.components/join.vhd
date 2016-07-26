---------------------------------------------------------------  join
---------------------------------------------------------------------
-- joins the control signals of 2 elastic buffers into a single 
-- control signal. Simple version without anti-tokens stuff.
-- implementation from "Cortadella elastic systems", paper 2, p3
---------------------------------------------------------------------
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





--------------------------------------------------------------  join3
---------------------------------------------------------------------
-- and adapted version of the join, based on the same logic 
-- equations, to join the control signals from 3 inputs
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity join3 is
port(	pValidArray : in bitArray_t(2 downto 0);
		n_ready : in std_logic;
		valid : out std_logic;
		readyArray : out bitArray_t(2 downto 0));
end join3;

architecture lazy of join3 is
		-- internal valud for readybility
	signal allPValid : std_logic;
begin

	valid <= pValidArray(0) and pValidArray(1) and pValidArray(2);
	
	allPValid <= (pValidArray(0) and pValidArray(1) and (pValidArray2));
	
	readyArray(0) <= (not pValidArray(0)) or allPValid
	readyArray(1) <= (not pValidArray(1)) or allPValid
	readyArray(2) <= (not pValidArray(2)) or allPValid
	
	
end lazy;
		
