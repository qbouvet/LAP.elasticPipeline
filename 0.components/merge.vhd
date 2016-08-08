--------------------------------------------------------------  merge
---------------------------------------------------------------------
-- a merge block
-- receiving data & ctl signals from several source, picks one source
-- ((acording to the valid signal) whose data and control signals
-- will be passed to the next components



---------------------------------------------------------------------
-- simple 2-input channels implementation from "elastic GCRAs" paper 
-- (p4)
-- the 'and' gate used in the paper may be a typo, we will use a OR 
-- instead. But could use a XOR	.
-- OR will resolve the "not supposed to happen" (?) case where all 
-- channels are valid at once by selecting a channel per default (0
-- here and in the paper), while XOR will not transmit data, but
-- won't stall either, which will result in data transmitted on the 
-- datapath, but not announced as valid (eventually lost, possibly 
-- undetected)
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity merge is port(
	data0, data1 : in std_logic_vector(31 downto 0);
	dataOut : out  std_logic_vector(31 downto 0);
	
	pValidArray : in bitArray_t(1 downto 0);
	nReady : in std_logic;
	valid : out std_logic;
	readyArray : out bitArray_t(1 downto 0));
end merge;

architecture vanilla of merge is

begin
	
	dataOut <= data0 when pValidArray(0)='1' else data1;
	
	valid <= pValidArray(0) or pValidArray(1);
	
	readyArray(1) <= nReady;
	readyArray(0) <= nReady;
	
end vanilla;
