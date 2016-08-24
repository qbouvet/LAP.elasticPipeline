-----------------------------------------------------------------------
-- tip : use _eargerFork version instead
-- stalls the channel it is connected to on demand of the "stall" signal
-- typically meant to be used to prevent the new wrAdress to be sent to 
-- the forwarding unit if all the data for the corresponding operation
-- can't be provided right now.
-- NB : won't work with eager forks
-- kept for backup purpose
-----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity staller is port(
	stall,
	pValid, nReady 	: in std_logic;
	valid, ready 	: out std_logic
); end staller;

architecture vanilla of staller is
begin

	-- forward the signals when stall='0', set the output to 0 when stall='1'
	valid <= pValid when stall='0' else '0';
	ready <= nReady when stall='0' else '0';

end vanilla;






----------------------------------------------------------------------
-- since eager forks can provide all data, but not all at once, we need 
-- registers to keep track of which data has been provided.
-- this version of the staller does that
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity staller_eagerFork is port(
	clk, reset, 
	data0Transit, data1Transit,
	pValid, nReady				: in std_logic;
	valid, ready 				: out std_logic
); end stallerMem;

architecture vanilla of staller_eagerFork is
	signal stall, regOut0, regOut1 : std_logic;
begin

	-- 2 registers to keep track of which data has been served
	reg0 : process(reset, clk, stall, data0Transit, data1Transit)
	begin
		if(reset='1') then
			regOut0 <= '0';
			regOut1 <= '0';
		else 
			if rising_edge(clk) then
				if(stall='0') then 
					regOut0 <= '0';
					regOut1 <= '0';
				else
					if data0Transit='1' then
						regOut0 <=  data0Transit;
					end if;
					if data1Transit ='1' then
						regOut1 <=  data1Transit;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	stall <= not ((regOut0 or data0Transit) and (regOut1 or data1Transit));
	
	valid <= pValid when stall='0' else '0';
	ready <= nReady when stall='0' else '0';
	
end vanilla;








