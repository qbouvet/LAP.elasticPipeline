-----------------------------------------  fwd path resolution unit
---------------------------------------------------------------------
-- the Dependancy Resolution Unit solves data hasards by selecting 
-- the correct memory bypass , receiving the read address and all 
-- the previous pending write addresses.
-- Uses a valid signal to make sur the received addresses are valid, 
-- but sends no ready signal, since it should not be allowed to 
-- stall the execution
-- DATASIZE is the width of data buses used
-- INPUT_NB  is the number of data sources to select from, including the
-- registerFile output, the memory bypass and any forwarding path 
--
-- NB : the forwarding paths only have a 'valid' control signal

library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity FwdPathResolutionUnit is
GENERIC ( DATASIZE 		: integer; INPUT_NB : integer );
port(	readAdr 		: in std_logic_vector(31 downto 0);
		wAdrArray 		: in vectorArray_t(INPUT_NB-1 downto 1)(31 downto 0);			-- (oldest(mem bypass) -> newest write addresses)
		adrValidArray	: in bitArray_t(0 to INPUT_NB-1);								-- (oldest(mem bypass) -> newest write addresses, readAdr)
		
		inputArray 		: in vectorArray_t(INPUT_NB-1 DOWNTO 0)(DATASIZE-1 downto 0);	-- (oldest(mem bypass) -> newest instruction's results, RF output)
		inputValidArray : in bitArray_t(INPUT_NB-1 downto 0);							-- (oldest(mem bypass) -> newest instruction's results, RF output)
		output 			: out std_logic_vector(DATASIZE-1 downto 0);		
		nReady 			: in std_logic;		
		valid, ready	: out std_logic	-- only the register file's input had full control signals				
);
end FwdPathResolutionUnit;

architecture vanilla of FwdPathResolutionUnit is
begin

	-- this control signal is directly forwarded to the register file, regardless of from where we read the output
	ready <= nReady;

	process(readadr, wAdrArray, inputArray, inputValidArray)
	begin
	output <= inputArray(0);		-- by default, we select the data read from the register file
	valid <= inputValidArray(0);
																											
	for i in INPUT_NB-1 downto 1 loop			-- order of exploration : oldest (memoy bypass) to newest instructions
		if(readAdr = wAdrArray(i)) then		-- if the address we want to read matches with one that is currently being written
		-- select the correct input
		output <= inputArray(i);	
		-- forward its 'valid0' control signal
		valid <= inputValidArray(i) and adrValidArray(i);
		end if;
	end loop;
	end process;

end vanilla;  


architecture try1 of FwdPathResolutionUnit is
begin

	-- this control signal is directly forwarded to the register file, regardless of from where we read the output
	ready <= nReady;

	process(readadr, wAdrArray, inputArray, inputValidArray)
		variable temp : integer;
	begin
	output <= inputArray(0);		-- by default, we select the data read from the register file
	valid <= inputValidArray(0);
																											
	for i in INPUT_NB-1 downto 1 loop			-- order of exploration : oldest (memoy bypass) to newest instructions
		if(readAdr = wAdrArray(i)) then		-- if the address we want to read matches with one that is currently being written
			temp := i;
		end if;
	end loop;
		-- select the correct input
		output <= inputArray(temp);	
		-- forward its 'valid0' control signal
		valid <= inputValidArray(temp) and adrValidArray(temp);
	end process;

end try1;  
