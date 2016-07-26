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
	
end package;



