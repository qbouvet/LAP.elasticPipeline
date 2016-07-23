----------------------------------------------------------------  DDU
---------------------------------------------------------------------
-- the Dependancy Detection Unit solves data hasard by selecting 
-- the correct memory bypass , knowing the read address and all 
-- then previous pending write addresses.
-- cf Cortadella RTL synth (paper 1) fig 17b, page 11
library ieee;
use ieee.std_logic_1164.all;

type ADDR_ARRAY is array(integer range <>) of std_logic_vector(4 downto 0);

entity DDU is
GENERIC (	NUM_INPUT_WR_ADDR : integer );
port(	read_addr : in std_logic_vector(4 downto 0);
		wr_addr_array : in ADDR_ARRAY(NUM_INPUT_WR_ADDR downto );
		res_sel : out std_logic_vector(NUM_INPUT_WR_ADDR));
end DDU;

architecture DDU1 of DDU is

begin

	for i in 1 to NUM_INPUT_WR_ADDR loop
		if(read_addr = wr_addr_array(i) then
			res_sel <= to_std_logic_vector(to_unsigned(i));
		end if;
	end loop;

end DDU1;
