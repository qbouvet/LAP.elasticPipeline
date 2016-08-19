-----------------------------------------  fwd path resolution unit
---------------------------------------------------------------------
-- A block that stalls control signals depending on an additional input
-- stalls when stall='1'

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
