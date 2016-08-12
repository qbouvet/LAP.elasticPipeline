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
--use ieee.numeric_std.all;
--use IEEE.math_real."log2";
use work.customTypes.all;

entity FwdPathResolutionUnit is
GENERIC ( DATASIZE 		: integer; INPUT_NB : integer );
port(	readAdr 		: in std_logic_vector(4 downto 0); -- adress = vector of size 5
		wAdrArray 		: in ADDR_ARRAY(INPUT_NB-1 downto 1);							-- (memory bypass, newest -> oldest write addresses)
		adrValidArray	: in bitArray_t(INPUT_NB-1 downto 0);							-- (memory bypass, newest -> oldest write addresses, readAdr)
		
		-- keep ?
		-- sel : out std_logic_vector(integer(log2(real(NUM_INPUT_WR_ADDR))) downto 1);
		
		inputArray 		: in vectorArray_t(INPUT_NB-1 DOWNTO 0)(DATASIZE-1 downto 0);	-- (memory bypass, forwarding paths in "newest instructions leftmost" order, RF output)
		output 			: out std_logic_vector(DATASIZE-1 downto 0);		
		inputValidArray : in bitArray_t(INPUT_NB-1 downto 0);							-- (memory bypass, newwest->oldest instruction result, registerFile)
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
																											
	for i in 1 to INPUT_NB-1 loop			-- order of exploration : oldest to newest instructions, then memory bypass
		if(readAdr = wAdrArray(i)) then		-- if the address we want to read matches with one that is currently being written
		
			-- select the correct input
			output <= inputArray(i);	
			-- forward its 'valid0' control signal
			valid <= inputValidArray(i) and adrValidArray(i);
			
			-- keep ?
			--res_sel <= std_logic_vector(to_unsigned(i,integer(log2(real(NUM_INPUT_WR_ADDR)))));
		end if;
	end loop;
	end process;

end vanilla;  
