-------------------------------------------------------------  branch
---------------------------------------------------------------------
-- a branch block
-- announces valid data on either branch according to the condition,
-- and allows either of the branches to stall in the same manner






---------------------------------------------------------------------
-- simple 2-branches implementation based on the "elastic GCRAs" paper (p4)
-- implements an additional set of control signals for 'condition'
-- implemented as an additional join block
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity branchHybrid is port(
	condition,
	conditionValid,
	dataValid 		: in std_logic;
	nReadyArray 	: in bitArray_t(1 downto 0);	-- (branch1, branch0)
	validArray 		: out bitArray_t(1 downto 0);	-- (branch1, branch0)
	readyArray  	: out bitArray_t(1 downto 0));	-- (data, condition)
end branchHybrid;

architecture vanilla of branchHybrid is
	signal joinValid, branchReady 	: std_logic;
begin

	j : entity work.joinN(vanilla) generic map(2)
			port map(	(dataValid, conditionValid),
						branchReady,
						joinValid,
						readyArray);

	br : entity work.branch(vanilla)
			port map(	condition,
						joinValid,
						nReadyArray,
						validArray,
						branchReady);

end vanilla;












---------------------------------------------------------------------
-- simple 2-branches implementation from "elastic GCRAs" paper (p4)
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity branch is port(
	condition,
	pValid : in std_logic;
	nReadyArray : in bitArray_t(1 downto 0);	-- (branch1, branch0)
	validArray : out bitArray_t(1 downto 0);
	ready : out std_logic);
end branch;

architecture vanilla of branch is

begin
	
	-- only one branch can announce ready, according to condition
	validArray(0) <= (not condition) and pValid;		
	validArray(1) <= condition and pValid;
	
	ready <= 	(nReadyArray(0) and not condition)-- 	branch0 decides the ready signal if condition is '0'
			 or	(nReadyArray(1) and condition);	  -- or	branch1 decides the ready signal if condition is '1'
		--	 or	(readyArray(0) and readyArray(1)) -- or ready='1' if all branches are ready
		-- but one of the conditions above is necessarily true if the last one is true -> useless
		
end vanilla;
