---------------------------------------------------------------- Circuit
------------------------------------------------------------------------
-- implementation of the circuit described in cortadella's papers
-- architectures : 	- elasticBasic
--					- elasticBasic_delayedResultWriteback
-- 					- elasticBasic_delayedResult3
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity circuit is port(
	reset, clk : in std_logic;
	IFDready : out std_logic;
	dataValid : in std_logic;
	data : in std_logic_vector(31 downto 0);
	instrOut, resOut : out std_logic_vector(31 downto 0); -- to allow us to look what's going on inside during tests
	resValid,ifdEmpty : out std_logic;	--same
	rf_a, rf_b: out std_logic_vector(31 downto 0)); --same
end circuit;



------------------------------------------------------------------------
-- first elastic implementation, cf cortadella's paper, p8, fig 13a
------------------------------------------------------------------------
architecture elasticBasic of circuit is
	
	--output and control signals of the IFD
	signal adrA, adrB, adrW, argI, oc : std_logic_vector(31 downto 0);
	signal IFDvalidArray : bitArray_t(4 downto 0);
	-- result of the operation, for writeback
	signal opResult : std_logic_vector(31 downto 0);
	-- registerFile control signals
	signal RFreadyArray : bitArray_t(3 downto 0);
	signal RFvalidArray : bitArray_t(1 downto 0);
	signal RFreadyForWrdata : std_logic;
	-- registerFile output
	signal operandA, operandB : std_logic_vector(31 downto 0);	
	--OP unit control signals
	signal OPUresultValid : std_logic;
	signal OPUreadyArray : bitArray_t(3 downto 0);
	
begin

	instructionFetchedDecoder : entity work.instructionFetcherDecoder(elastic) 
			port map(	clk, reset, 
						data, 						-- instr_in
						adrB, adrA, adrW, argI, oc, 
						dataValid,					-- pValid
						(RFreadyArray(3 downto 1), OPUreadyArray(1 downto 0)),	-- nReadyArray
						IFDready, 					-- ready
						IFDvalidArray,				-- ValidArray
						instrOut,	-- outputs the instruction for observation purpose
						ifdEmpty);	-- for simulation purpose, decides when to stop the sim
	
	regFile : entity work.registerFile(elastic)
			port map(	clk, reset, 
						adrB, adrA, adrW, opResult, 
						(IFDvalidArray(4 downto 2), OPUresultValid),-- pValidArray
						OPUreadyArray(3 downto 2), 					-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 								-- readyArray
						RFvalidArray);								-- validArray
	--	(IFDnReadyArray(4 downto 2), RFreadyForWrdata) <= RFreadyArray;--debug : now useless
	
	OPU : entity work.OPunit(elasticEagerFork)
			port map(	clk, reset,
						operandB, operandA, argI, oc, 
						opResult, 
						(RFvalidArray, IFDvalidArray(1 downto 0)),	-- pValidArray
						RFreadyArray(0), 							-- nReady
						OPUresultValid,								-- valid
						OPUreadyArray);
						
	rf_a <= operandA;	-- for debug
	rf_b <= operandB;
						
	-- signals for observation purpose
	resOut <= opResult;
	resValid <= OPUresultValid;
						
end elasticBasic;



  
------------------------------------------------------------------------
-- based on elasticBasic implementation
-- added a delayChannel after the OPunit, so that the result (both 
-- output in the testbench and for writeback into the register file)
-- is delayed by 3 cycles
-- should make the pipeline stall for 3 cycles at start, since the 
-- registerFile will wait on data to write
------------------------------------------------------------------------
architecture elasticBasic_delayedResult3 of circuit is
	
	--output and control signals of the IFD
	signal adrA, adrB, adrW, argI, oc : std_logic_vector(31 downto 0);
	signal IFDvalidArray : bitArray_t(4 downto 0);
	-- result of the operation, for writeback
	signal opResult : std_logic_vector(31 downto 0);
	-- registerFile control signals
	signal RFreadyArray : bitArray_t(3 downto 0);
	signal RFvalidArray : bitArray_t(1 downto 0);
	signal RFreadyForWrdata : std_logic;
	-- registerFile output
	signal operandA, operandB : std_logic_vector(31 downto 0);	
	--OP unit control signals
	signal OPUresultValid : std_logic;
	signal OPUreadyArray : bitArray_t(3 downto 0);
	
	--signals for the delay channel
	signal delayChannelOutput : vectorArray_t(3 downto 0)(31 downto 0);
	signal delayChannelValidArray : bitArray_t(3 downto 0);
	signal delayChannelReady : std_logic;
	
begin

	instructionFetchedDecoder : entity work.instructionFetcherDecoder(elastic) 
			port map(	clk, reset, 
						data, 						-- instr_in
						adrB, adrA, adrW, argI, oc, 
						dataValid,					-- pValid
						(RFreadyArray(3 downto 1), OPUreadyArray(1 downto 0)),	-- nReadyArray
						IFDready, 					-- ready
						IFDvalidArray,				-- ValidArray
						instrOut,	-- outputs the instruction for observation purpose
						ifdEmpty);	-- for simulation purpose, decides when to stop the sim
	
	regFile : entity work.registerFile(elastic)
			port map(	clk, reset, 
						adrB, adrA, adrW, opResult, 
						(IFDvalidArray(4 downto 2), delayChannelValidArray(3)),-- pValidArray
						OPUreadyArray(3 downto 2), 					-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 								-- readyArray
						RFvalidArray);								-- validArray
	--	(IFDnReadyArray(4 downto 2), RFreadyForWrdata) <= RFreadyArray;--debug : now useless
	
	OPU : entity work.OPunit(elasticEagerFork)
			port map(	clk, reset,
						operandB, operandA, argI, oc, 
						opResult, 
						(RFvalidArray, IFDvalidArray(1 downto 0)),	-- pValidArray
						delayChannelReady, 							-- nReady
						OPUresultValid,								-- valid
						OPUreadyArray);
						
	delayChan : entity work.delayChannel(vanilla) generic map(32, 3)
			port map(	clk, reset,
						opResult,
						delayChannelOutput, 
						delayChannelValidArray,
						OPUresultValid, RFreadyArray(0),
						delayChannelReady);
						
	rf_a <= operandA;	-- for debug
	rf_b <= operandB;
						
	-- signals for observation purpose
	resOut <= delayChannelOutput(3);
	resValid <= delayChannelValidArray(3);
						
end elasticBasic_delayedResult3;





------------------------------------------------------------------------
-- based on the elasticBasic implementation.
-- added an elastic buffer to delay the arrival of the OPresult to the
-- register file for writeback
------------------------------------------------------------------------
architecture elasticBasic_delayedResult1 of circuit is
	
	--output and control signals of the IFD
	signal adrA, adrB, adrW, argI, oc : std_logic_vector(31 downto 0);
	signal IFDvalidArray : bitArray_t(4 downto 0);
	-- result of the operation, for writeback
	signal opResult : std_logic_vector(31 downto 0);
	-- registerFile control signals
	signal RFreadyArray : bitArray_t(3 downto 0);
	signal RFvalidArray : bitArray_t(1 downto 0);
	signal RFreadyForWrdata : std_logic;
	-- registerFile output
	signal operandA, operandB : std_logic_vector(31 downto 0);	
	--OP unit control signals
	signal OPUresultValid : std_logic;
	signal OPUreadyArray : bitArray_t(3 downto 0);
	
	-- elastic buffer's signals
	signal ebValid, ebReady : std_logic;
	signal ebOut : std_logic_vector(31 downto 0);
	
begin

	instructionFetchedDecoder : entity work.instructionFetcherDecoder(elastic) 
			port map(	clk, reset, 
						data, 						-- instr_in
						adrB, adrA, adrW, argI, oc, 
						dataValid,					-- pValid
						(RFreadyArray(3 downto 1), OPUreadyArray(1 downto 0)),	-- nReadyArray
						IFDready, 					-- ready
						IFDvalidArray,				-- ValidArray
						instrOut,	-- outputs the instruction for observation purpose
						ifdEmpty);	-- for simulation purpose, decides when to stop the sim
	
	regFile : entity work.registerFile(elastic)
			port map(	clk, reset, 
						adrB, adrA, adrW, opResult, 
						(IFDvalidArray(4 downto 2), ebValid),-- pValidArray
						OPUreadyArray(3 downto 2), 					-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 								-- readyArray
						RFvalidArray);								-- validArray
	--	(IFDnReadyArray(4 downto 2), RFreadyForWrdata) <= RFreadyArray;--debug : now useless
	
	OPU : entity work.OPunit(elasticEagerFork)
			port map(	clk, reset,
						operandB, operandA, argI, oc, 
						opResult, 
						(RFvalidArray, IFDvalidArray(1 downto 0)),	-- pValidArray
						ebReady, 							-- nReady
						OPUresultValid,								-- valid
						OPUreadyArray);
						
	eb : entity work.elasticBuffer(vanilla) generic map(32)
			port map(	clk, reset,
						opResult, ebOut,
						OPUresultValid, RFreadyArray(0),
						ebReady, ebValid);
						
	rf_a <= operandA;	-- for debug
	rf_b <= operandB;
						
	-- signals for observation purpose
	resOut <= ebOut;
	resValid <= ebValid;
						
end elasticBasic_delayedResult1;
