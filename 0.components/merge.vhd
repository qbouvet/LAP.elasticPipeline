--------------------------------------------------------------  merge
---------------------------------------------------------------------
-- a merge block
-- receiving data & ctl signals from several source, picks one source
-- ((acording to the valid signal) whose data and control signals
-- will be passed to the next components
-- exists as a "from the paper" implemantation and a "hybrid" implementation
-- that has a 'sel' signal and behaves like a join to an extent



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
	data1, data0 : in std_logic_vector(31 downto 0);
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



---------------------------------------------------------------------
-- the hybrid implementation. Solves the "first arrived, first out ->
-- reordering possible if different latencies -> elasticity broken" 
-- issue
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity mergeHybrid is port(
	data1, data0 	: in std_logic_vector(31 downto 0);
	dataOut 		: out  std_logic_vector(31 downto 0);
	condition		: in std_logic;
	
	pValidArray 	: in bitArray_t(2 downto 0);	-- (data1, data0, condition)
	nReady 			: in std_logic;
	valid 			: out std_logic;
	readyArray 		: out bitArray_t(2 downto 0));	-- (data1, data0, condition)
end mergeHybrid;

architecture vanilla of mergeHybrid is
	signal  mergeValid 		: std_logic;
	signal joinReadyArray 	: bitArray_t(1 downto 0);
begin

	mrg : entity work.merge(vanilla)
			port map(	data1, data0,
						dataOut,
						pValidArray(2 downto 1),
						joinReadyArray(1),
						mergeValid,
						readyArray(2 downto 1));
						
	join : entity work.joinN(vanilla) generic map (2)
			port map(	(mergeValid, pValidArray(0)),	-- pValidArray
						nReady,
						valid,
						joinReadyArray);				-- readyArray : (mergedStuff, condition)
	
	-- ready signal for condition
	readyArray(0) <= joinReadyArray(0);

end vanilla;



---------------------------------------------------------------------
-- mergeHybrid version which uses a bufferedJoin instead of a vanilla 
-- could help fixing circuit fwdPathResolution
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use work.

entity mergeHybridBuffered is port(
	clk, reset		: in std_logic;
	data1, data0 	: in std_logic_vector(31 downto 0);
	dataOut 		: out  std_logic_vector(31 downto 0);
	condition		: in std_logic;
	
	pValidArray 	: in bitArray_t(2 downto 0);	-- (data1, data0, condition)
	nReady 			: in std_logic;
	valid 			: out std_logic;
	readyArray 		: out bitArray_t(2 downto 0));	-- (data1, data0, condition)
end mergeHybridBuffered;

architecture vanilla of mergeHybridBuffered is
	signal mergeValid 		: std_logic;
	signal joinReadyArray 	: bitArray_t(1 downto 0);
	signal mergeOut 		: std_logic_vector(31 downto 0);
	signal joinOut 			: vectorArray_t(1 downto 0)(31 downto 0);	--(oc, mergeOut)
begin

	mrg : entity work.merge(vanilla)
			port map(	data1, data0,
						mergeOut,
						pValidArray(2 downto 1),
						joinReadyArray(1),
						mergeValid,
						readyArray(2 downto 1));
						
	join : entity work.bufferedJoinN(vanilla) generic map (2)
			port map(	clk, reset,
						((zero(31 downto 1), condition), mergeOut),	-- dataInt : (oc, mergeOut)
						joinOut,
						(mergeValid, pValidArray(0)),	-- pValidArray
						nReady,
						valid,
						joinReadyArray);				-- readyArray : (mergedStuff, condition)
	
	-- ready signal for condition
	readyArray(0) <= joinReadyArray(0);
	
	-- we're only interrested in the result of the merge, after it went through the bufferedJoin (recall, 1 cycle delay)
	dataOut <= joinOut(0);

end vanilla;
