-------------------------------------------------------------  branch
---------------------------------------------------------------------
-- a branch block
-- announces valid data on either branch according to the condition,
-- and allows either of the branches to stall in the same manner



---------------------------------------------------------------------
-- simple 2-branches implementation from "elastic GCRAs" paper (p4)
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity branch is port(
	condition,
	pValid : in std_logic;
	nReady : in bitArray_t(1 downto 0);
	validArray : out std_logic;
	ready : out std_logic_vector(31 downto 0));
end branch;

architecture vanilla of branch is

begin
	
	-- only one branch can announce ready, according to condition
	validArray(0) <= (not condition) and valid;		
	validArray(1) <= condition and valid;
	
	ready <= 	(readyArray(0) and not condition) -- 	branch0 decides the ready signal if condition is '0'
			 or	(readyArray(1) and condition)	  -- or	branch1 decides the ready signal if condition is '1'
		--	 or	(readyArray(0) and readyArray(1)) -- or ready='1' if all branches are ready
		-- but one of the conditions above is necessarily true if the last one is true -> useless
		
end vanilla;
