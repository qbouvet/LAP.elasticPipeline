-------------------------------------------------------  customTypes
---------------------------------------------------------------------
-- customTypes are declared here (can't use array types directly in
-- entities' port
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
package customTypes is

	-- array of vectors used especially with delay channels
	type vectorArray_t is array (integer range <>) of std_logic_vector; -- data size and latency must be specified when used

	-- array of bits useed mostly for grouping elastic control signals. used in many components. Almost an alias for std_logic_vector
	type bitArray_t is array (integer range <>) of std_logic;

	-- the address array used as input to the dependancy detection unit
	type ADDR_ARRAY is array(integer range <>) of std_logic_vector(4 downto 0);
	
	-- data type used in the register file
	type register_t is array(63 downto 0) of std_logic_vector(31 downto 0);
	
end package;



