----------------------------------------------------------------  DDU
---------------------------------------------------------------------
-- the Dependancy Detection Unit solves data hasard by selecting 
-- the correct memory bypass , knowing the read address and all 
-- then previous pending write addresses.
-- cf Cortadelle RTL synth (paper 1) fig 17b, page 11
library ieee;
use ieee.std_logic_1164.all;

type ADDR_ARRAY is array(integer range <>) of std_logic_vector(4 downto 0);

entity DDU is
GENERIC (	NUM_INPUT_WR_ADDR : integer );
port(	read_addr : in std_logic_vector(4 downto 0);
		wr_addr_array : in ADDR_ARRAY(NUM_INPUT_WR_ADDR-1 downto 0);
		res_sel : out std_logic_vector(NUM_INPUT_WR_ADDR));
end DDU;

architecture DDU1 of DDU is

begin

end DDU1;
