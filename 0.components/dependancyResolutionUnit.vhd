----------------------------------------------------------------  DDU
---------------------------------------------------------------------
-- the Dependancy Detection Unit solves data hasard by selecting 
-- the correct memory bypass , knowing the read address and all 
-- then previous pending write addresses.
-- cf Cortadella RTL synth (paper 1) fig 17b, page 11
library ieee;
use ieee.std_logic_1164.all;

package DDU_types is
	type ADDR_ARRAY is array(integer range <>) of std_logic_vector(4 downto 0);
end DDU_types;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real."log2";
use work.DDU_types.all;

entity DDU is
GENERIC ( NUM_INPUT_WR_ADDR : integer );
port(	read_adr : in std_logic_vector(4 downto 0);
		wr_adr_array : in ADDR_ARRAY(NUM_INPUT_WR_ADDR downto 1);
		res_sel : out std_logic_vector(integer(log2(real(NUM_INPUT_WR_ADDR))) downto 1));
end DDU;

architecture DDU1 of DDU is

begin

	process(read_adr, wr_adr_array)
	begin
	for i in 1 to NUM_INPUT_WR_ADDR loop
		if(read_adr = wr_adr_array(i)) then
			res_sel <= std_logic_vector(to_unsigned(i,integer(log2(real(NUM_INPUT_WR_ADDR)))));
		end if;
	end loop;
	end process;

end DDU1;  
