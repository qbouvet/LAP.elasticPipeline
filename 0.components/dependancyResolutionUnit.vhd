-----------------------------------------  Dependance resolution unit
---------------------------------------------------------------------
-- the Dependancy Resolution Unit solves data hasards by selecting 
-- the correct memory bypass , receiving the read address and all 
-- the previous pending write addresses.
-- Uses a valid signal to make sur the received addresses are valid, 
-- but sends no ready signal, since it should not be allowed to 
-- stall the execution
-- cf Cortadella RTL synth (paper 1) fig 17d, page 11

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real."log2";
use work.customTypes.all;

entity dependancyResolutionUnit is
GENERIC ( NUM_INPUT_WR_ADDR : integer );
port(	read_adr : in std_logic_vector(4 downto 0);
		wr_adr_array : in ADDR_ARRAY(NUM_INPUT_WR_ADDR downto 1);
		validAdr : in bitArray_t(NUM_INPUT_WR_ADDR downto 1);															-- TODO
		res_sel : out std_logic_vector(integer(log2(real(NUM_INPUT_WR_ADDR))) downto 1));
end dependancyResolutionUnit;

architecture vanilla of dependancyResolutionUnit is

begin

	process(read_adr, wr_adr_array)
	begin
	for i in 1 to NUM_INPUT_WR_ADDR loop
		if(read_adr = wr_adr_array(i)) then
			res_sel <= std_logic_vector(to_unsigned(i,integer(log2(real(NUM_INPUT_WR_ADDR)))));
		end if;
	end loop;
	end process;

end vanilla;  
