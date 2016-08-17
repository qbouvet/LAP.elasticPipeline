---------------------------------------------------------------- Circuit
------------------------------------------------------------------------
-- implementation of the circuit described in cortadella's papers
-- architectures : 	- elasticBasic
--					- fwdPathResolution
--
-- test versions :	- elasticBasic_delayedResult1
-- 					- elasticBasic_delayedResult3
-- 					- elasticBasic_delayedOc3
-- 					- elasticBasic_delayedAdrW1
--					- elasticBasic_delay1AdrWandWrdata
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity circuit is port(
	reset, clk 									: in std_logic;
	IFDready 									: out std_logic;
	dataValid 									: in std_logic;
	data 										: in std_logic_vector(31 downto 0);
	instrOut, resOut 							: out std_logic_vector(31 downto 0); 	-- to allow us to look what's going on inside during tests
	resValid, ifdEmpty 							: out std_logic		 					-- idem + to decide when to finish the simulation
);end circuit;








------------------------------------------------------------------------
-- simpler version of the (b) circuit of cortadella's paper
-- using a single forwarding path
------------------------------------------------------------------------
architecture singleFwdPath of circuit is
	
	--output and control signals of the IFD
	signal adrA, adrB, adrW, argI, oc 			: std_logic_vector(31 downto 0);
	signal IFDvalidArray 						: bitArray_t(4 downto 0);
	
	-- result of the operation, for writeback
	signal opResult 							: std_logic_vector(31 downto 0);
	
	-- registerFile control signals
	signal RFreadyArray 						: bitArray_t(3 downto 0);
	signal RFvalidArray 						: bitArray_t(1 downto 0);
	signal RFreadyForWrdata 					: std_logic;
	
	-- registerFile output
	signal operandA, operandB 					: std_logic_vector(31 downto 0);	
	
	--OP unit control signals
	signal OPUresultValid 						: std_logic;
	signal OPUreadyArray 						: bitArray_t(3 downto 0);
	
	--fwdUnit's signals
	signal fwdUnitValidArray, 
			fwdUnitReadyArray 					: bitArray_t(1 downto 0);					-- (b, a)
	signal fwdUnitOutput						: vectorArray_t(1 downto 0)(31 downto 0); 	-- (b, a)
			
	-- signals that permit a single element to be considered as an array of size one
	signal adrWarrayWrapper 					: vectorArray_t(1 downto 0)(31 downto 0);
	
	-- ugly stuff the fixes the "questa unknown error"
	signal FUinputArray_temp 					: vectorArray_t(2 downto 0)(31 downto 0);
	signal FUadrValidArray_temp, FUinputValidArray_temp : bitArray_t(2 downto 0);
	
	--elastic buffers' signal
	signal resBufferOut 								: std_logic_vector(31 downto 0);
	signal resBufferReady, resBufferValid				: std_logic;
	signal adrBufferOut 								: std_logic_vector(31 downto 0);
	signal adrBufferReady, adrBufferValid				: std_logic;
		
begin

	instructionFetchedDecoder : entity work.instructionFetcherDecoder(elastic) 
			port map(	clk, reset, 
						data, 						-- instr_in
						adrB, adrA, adrW, argI, oc, 
						dataValid,					-- pValid
						(RFreadyArray(3 downto 2), adrBufferReady, OPUreadyArray(1 downto 0)),	-- nReadyArray
						IFDready, 					-- ready
						IFDvalidArray,				-- ValidArray
						instrOut,	-- outputs the currentl instruction for observation purpose
						ifdEmpty);	-- allows to decide when to stop the simulation
	
	regFile : entity work.registerFile(elastic)
			port map(	clk, reset, 
						adrB, adrA, adrBufferOut, resBufferOut, 
						(IFDvalidArray(4 downto 3), adrBufferValid, resBufferValid),		-- pValidArray
						fwdUnitReadyArray, 							-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 								-- readyArray
						RFvalidArray);								-- validArray
	
	-- can use elastic, elasticEagerFork, branchmerge
	OPU : entity work.OPunit(branchmerge)
			port map(	clk, reset,
						operandB, operandA, argI, oc, 
						opResult, 
						(fwdUnitValidArray, IFDvalidArray(1 downto 0)),	-- pValidArray
						resBufferReady,		 							-- nReady
						OPUresultValid,									-- valid
						OPUreadyArray);
						
						
	-- ugly typecast stuff
	adrWarrayWrapper <= (adrW, X"00000000");	
	
	-- ugly stuff the fixes the "questa unknown error"
	FUadrValidArray_temp <= (IFDvalidArray(2), IFDvalidArray(4 downto 3));
	FUinputArray_temp <= (opResult, operandB, operandA);
	FUinputValidArray_temp <= (OPUresultValid, RFvalidArray);		
						
	fwdUnit : entity work.fwdPathResolutionUnit(vanilla) generic map(32, 3)
			port map(	adrB, adrA,
						adrWarrayWrapper(1 downto 1),
						FUadrValidArray_temp,							-- adrValidArray : 	(adrW, adrB, adrA)
						FUinputArray_temp,								-- inputArray : 	(result, rf_b, rf_a)
						FUinputValidArray_temp,							-- inputValidArray: idem
						fwdUnitOutput,
						OPUreadyArray(3 downto 2),						-- nReadyArray : 	(B, A)
						fwdUnitValidArray, fwdUnitReadyArray);			-- valid/readyArray:(B, A)
			
	resultbuffer : entity work.elasticBuffer(vanilla) generic map(32)
			port map(	clk, reset,	
						opResult, resBufferOut,
						OPUresultValid, RFreadyArray(0),
						resBufferReady, resBufferValid);
	
	adrBuffer : entity work.elasticBuffer(vanilla) generic map(32)
			port map(	clk, reset,	
						adrW,  adrBufferOut,
						IFDvalidArray(2), RFreadyArray(1),
						adrBufferReady, adrBufferValid);
					
	-- signals for observation purpose
	resOut <= opResult;
	resValid <= OPUresultValid;
	
end singleFwdPath;









------------------------------------------------------------------------
-- elastic implementation with forwarding path resolution
------------------------------------------------------------------------
architecture fwdPathResolution of circuit is
	
	--output and control signals of the IFD
	signal adrA, adrB, adrW, argI, oc 	: std_logic_vector(31 downto 0);
	signal IFDvalidArray 				: bitArray_t(4 downto 0);
	
	-- result of the operation, for writeback
	signal opResult 					: std_logic_vector(31 downto 0);
	
	-- registerFile control signals
	signal RFreadyArray 				: bitArray_t(3 downto 0);
	signal RFvalidArray 				: bitArray_t(1 downto 0);
	signal RFreadyForWrdata 			: std_logic;
	
	-- registerFile output
	signal operandA, operandB 			: std_logic_vector(31 downto 0);	
	
	--OP unit control signals
	signal OPUresultValid 				: std_logic;
	signal OPUreadyArray 				: bitArray_t(3 downto 0);
	
	--resDelayChannel signals
	signal resDelayChannelOutput 		: vectorArray_t(3 downto 0)(31 downto 0);
	signal resDelayChannelValidArray 	: bitArray_t(3 downto 0);
	signal resDelayChannelReady			: std_logic;
	
	--adrWDelayChannel signals
	signal adrWDelayChannelOutput 		: vectorArray_t(3 downto 0)(31 downto 0);
	signal adrWDelayChannelValidArray 	: bitArray_t(3 downto 0);
	signal adrWDelayChannelReady		: std_logic;
	
	-- fwd path resolution units signals
	signal FPRUoutputArray				: vectorArray_t(1 downto 0)(31 downto 0);
	signal FPRUvalidArray,FPRUreadyArray: bitArray_t(1 downto 0);					-- (B, A)
			
	-- temporary signals used to avoid aggregating signals in the port map, which leads to a bug at compilation
	signal FPRUinputValidArray_temp,
				FPRUadrValidArray_temp	: bitArray_t(4 downto 0);
	signal FPRUinputArray_temp			: vectorArray_t(4 downto 0)(31 downto 0);
	
begin

	instructionFetchedDecoder : entity work.instructionFetcherDecoder(elastic) 
			port map(	clk, reset, 
						data, 						-- instr_in
						adrB, adrA, adrW, argI, oc, 
						dataValid,					-- pValid
						(RFreadyArray(3 downto 2), 	-- nReadyArray : (adrB, adrA, adrW, argI, oc)
								adrWDelayChannelReady,
								OPUreadyArray(1 downto 0)),
						IFDready, 					-- ready
						IFDvalidArray,				-- ValidArray : (adrB, adrA, adrW, argI, oc)
						instrOut,	-- outputs the currentl instruction for observation purpose
						ifdEmpty);	-- allows to decide when to stop the simulation
	
	regFile : entity work.registerFile(elastic)
			port map(	clk, reset, 
						adrB, adrA, adrWDelayChannelOutput(3), resDelayChannelOutput(3), 
						(IFDvalidArray(4 downto 3), 				-- pValidArray :  (adrB, adrA, adrW, wrData)
								adrWDelayChannelValidArray(3),
								resDelayChannelValidArray(3)),
						FPRUreadyArray, 							-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 								-- readyArray : (adrB, adrA, adrW, wrData)
						RFvalidArray);								-- validArray : (a, b)
	
	-- can use elastic, elasticEagerFork, branchmerge
	OPU : entity work.OPunit(elasticEagerFork)
			port map(	clk, reset,
						FPRUoutputArray(1), FPRUoutputArray(0), argI, oc, 	-- (argB, argA, argI, oc)
						opResult, 
						(FPRUvalidArray, IFDvalidArray(1 downto 0)),		-- pValidArray
						resDelayChannelReady,								-- nReady
						OPUresultValid,										-- valid
						OPUreadyArray);										-- readyArray : (argB, argA, argI, oc)
						
						
	-- delay channels for both operation's result and write address
	resDelayChannel : entity work.delayChannel(vanilla) generic map(32, 3)
			port map(	clk, reset, 
						opResult, resDelayChannelOutput,-- dataIn, dataOut
						resDelayChannelValidArray,		-- validArray
						OPUresultValid, RFreadyArray(0),-- pValid, nReady
						resDelayChannelReady);			-- ready
						
	adrWDelayChannel : entity work.delayChannel(vanilla) generic map(32, 3)
			port map(	clk, reset,
						adrW, adrWDelayChannelOutput,
						adrWDelayChannelValidArray,
						IFDvalidArray(2), RFreadyArray(1),
						adrWDelayChannelReady);				
						
	FPRUadrValidArray_temp 	<= (adrWDelayChannelValidArray(3 downto 1), IFDvalidArray(4), IFDvalidArray(3));	-- adrValidArray : 	(oldest(mem bypass) -> newest WrAdress, readAdrB, readAdrA)1
	FPRUinputArray_temp 	<= (resDelayChannelOutput(3 downto 1), operandB, operandA); 						-- inputArray : 	(oldest(mem bypass) -> newest result, RF_B, RF_A)
	FPRUinputValidArray_temp<= (resDelayChannelValidArray(3 downto 1), RFvalidArray(1), RFvalidArray(0)); 		-- inputValidArray:	(oldest(mem bypass) -> newest WrAdress, rfValid_B, rfValid_A)
	
	-- forwarding unit
	FPRU : entity work.FwdPathResolutionUnit(vanilla) generic map(32, 5)
			port map(	adrB, adrA,
						adrWDelayChannelOutput(3 downto 1),		-- wAdrArray : 				(oldest(mem bypass) -> newest write addresses)
						FPRUadrValidArray_temp,					-- adrValidArray : 			(oldest(mem bypass) -> newest WrAdress, readAdrB, readAdrA)
						fpruInputArray_temp, 					-- inputArray : 			(oldest(mem bypass) -> newest results, RF_B, RF_A)
						FPRUinputValidArray_temp,				-- inputValidArray : 		(oldest(mem bypass) -> newest WrAdress, rfValid_B, rfValid_A)
						FPRUoutputArray,						-- outputArray 				(b, a)
						(OPUreadyArray(3),OPUreadyArray(2)),	-- nReady
						FPRUvalidArray, FPRUreadyArray);		-- validArray, readyArray	(b, a)
						
	-- signals for observation purpose
	resOut <= opResult;
	resValid <= OPUresultValid;
						
end fwdPathResolution;






















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
						instrOut,	-- outputs the currentl instruction for observation purpose
						ifdEmpty);	-- allows to decide when to stop the simulation
	
	regFile : entity work.registerFile(elastic)
			port map(	clk, reset, 
						adrB, adrA, adrW, opResult, 
						(IFDvalidArray(4 downto 2), OPUresultValid),-- pValidArray
						OPUreadyArray(3 downto 2), 					-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 								-- readyArray
						RFvalidArray);								-- validArray
	--	(IFDnReadyArray(4 downto 2), RFreadyForWrdata) <= RFreadyArray;--debug : now useless
	
	-- can use elastic, elasticEagerFork, branchmerge
	OPU : entity work.OPunit(elasticEagerFork)
			port map(	clk, reset,
						operandB, operandA, argI, oc, 
						opResult, 
						(RFvalidArray, IFDvalidArray(1 downto 0)),	-- pValidArray
						RFreadyArray(0), 							-- nReady
						OPUresultValid,								-- valid
						OPUreadyArray);
						
	-- signals for observation purpose
	resOut <= opResult;
	resValid <= OPUresultValid;
						
end elasticBasic;
















------------------------------------------------------------------------------------------------ test implementations
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------



------------------------------------------------------------------------
-- based on elasticBasic implementation
-- delays the adrW and wrData of 1 cycle
-- should not stall at all (only delay result by one cycle at start), 
--	since the buffers delay "dependant" data  together (buffers add a 
-- delay, but their control signals combined permit not to stall)
------------------------------------------------------------------------
architecture elasticBasic_delay1AdrWandWrdata of circuit is
	
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
	
	-- adrW buffer's signals
	signal awbValid, awbReady : std_logic;
	signal awbOut : std_logic_vector(31 downto 0);
	-- wrdata buffer's signals
	signal wdbValid, wdbReady : std_logic;
	signal wdbOut : std_logic_vector(31 downto 0);
	
begin

	instructionFetchedDecoder : entity work.instructionFetcherDecoder(elastic) 
			port map(	clk, reset, 
						data, 						-- instr_in
						adrB, adrA, adrW, argI, oc, 
						dataValid,					-- pValid
						(RFreadyArray(3 downto 2), awbReady, OPUreadyArray(1 downto 0)),	-- nReadyArray
						IFDready, 					-- ready
						IFDvalidArray,				-- ValidArray
						instrOut,	-- outputs the instruction for observation purpose
						ifdEmpty);	-- allows us to stop the simulation
	
	regFile : entity work.registerFile(elastic)
			port map(	clk, reset, 
						adrB, adrA, awbOut, wdbOut, 
						(IFDvalidArray(4 downto 3), awbValid, wdbValid),-- pValidArray
						OPUreadyArray(3 downto 2), 					-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 								-- readyArray
						RFvalidArray);								-- validArray
	--	(IFDnReadyArray(4 downto 2), RFreadyForWrdata) <= RFreadyArray;--debug : now useless
	
	OPU : entity work.OPunit(branchmerge)
			port map(	clk, reset,
						operandB, operandA, argI, oc, 
						opResult, 
						(RFvalidArray, IFDvalidArray(1 downto 0)),	-- pValidArray
						wdbReady, 									-- nReady
						OPUresultValid,								-- valid
						OPUreadyArray);
						
	adrwBuffer : entity work.elasticBuffer(vanilla) generic map(32)
			port map(	clk, reset,
						adrW, awbOut,
						IFDvalidArray(2), RFreadyArray(1),	-- pValid, nReady
						awbReady, awbValid);				-- ready, valid
					
	wrDataBuffer : entity work.elasticBuffer(vanilla) generic map(32)
			port map(	clk, reset, 
						opResult, wdbOut,
						OPUresultValid, RFreadyArray(0),	-- pValid, nReady
						wdbReady, wdbValid);				-- ready, valid
						
	-- signals for observation purpose
	resOut <= wdbOut;
	resValid <= wdbValid;
						
end elasticBasic_delay1AdrWandWrdata;


------------------------------------------------------------------------
-- based on elasticBasic implementation
-- delays the adrW of 1 cycle
-- should stall every other cycle
-- Rq : the result remains valid during the stall cycle (?) 
-- 		-> normal, since we don't have a buffer to store the result 
--		   before it's written in the register file
------------------------------------------------------------------------
architecture elasticBasic_delayedAdrW1 of circuit is
	
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
						(RFreadyArray(3 downto 2), ebReady, OPUreadyArray(1 downto 0)),	-- nReadyArray
						IFDready, 					-- ready
						IFDvalidArray,				-- ValidArray
						instrOut,	-- outputs the instruction for observation purpose
						ifdEmpty);	-- for simulation purpose, decides when to stop the sim
	
	regFile : entity work.registerFile(elastic)
			port map(	clk, reset, 
						adrB, adrA, ebOut, opResult, 
						(IFDvalidArray(4 downto 3), ebValid, OPUresultValid),-- pValidArray
						OPUreadyArray(3 downto 2), 					-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 								-- readyArray
						RFvalidArray);								-- validArray
	--	(IFDnReadyArray(4 downto 2), RFreadyForWrdata) <= RFreadyArray;--debug : now useless
	
	OPU : entity work.OPunit(branchmerge)
			port map(	clk, reset,
						operandB, operandA, argI, oc, 
						opResult, 
						(RFvalidArray, IFDvalidArray(1 downto 0)),	-- pValidArray
						RFreadyArray(0), 							-- nReady
						OPUresultValid,								-- valid
						OPUreadyArray);
						
	eb : entity work.elasticBuffer(vanilla) generic map(32)
			port map(	clk, reset,
						adrW, ebOut,
						IFDvalidArray(2), RFreadyArray(1),	-- pValid, nReady
						ebReady, ebValid);					-- ready, valid
						
	-- signals for observation purpose
	resOut <= opResult;
	resValid <= OPUresultValid;
						
end elasticBasic_delayedAdrW1;




------------------------------------------------------------------------
-- based on elasticBasic implementation
-- delay the oc by 3 cycles
-- should stall for 3 cycles at every instuction
-- NB : won't work with the branchmerge OPunit as long as oc=condition 
--		doesn't have control signals
------------------------------------------------------------------------
architecture elasticBasic_delayedOc3 of circuit is
	
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
						(RFreadyArray(3 downto 1), OPUreadyArray(1), delayChannelReady),	-- nReadyArray
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
	
	OPU : entity work.OPunit(branchmerge)
			port map(	clk, reset,
						operandB, operandA, argI, delayChannelOutput(3), 
						opResult, 
						(RFvalidArray, IFDvalidArray(1), delayChannelValidArray(3)),	-- pValidArray
						RFreadyArray(0), 							-- nReady
						OPUresultValid,								-- valid
						OPUreadyArray);
						
	dc : entity work.delayChannel(vanilla) generic map(32, 3)
			port map(	clk, reset, 
						oc, delayChannelOutput,
						delayChannelValidArray,
						IFDvalidArray(0),
						OPUreadyArray(0),
						delayChannelReady);
						
	-- signals for observation purpose
	resOut <= opResult;
	resValid <= OPUresultValid;
						
end elasticBasic_delayedOc3;

  
  
  
------------------------------------------------------------------------
-- based on elasticBasic implementation
-- added a delayChannel after the OPunit, so that the result (both 
-- output in the testbench and for writeback into the register file)
-- is delayed by 3 cycles
-- should stall for 3 cycles at every instruction
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
						adrB, adrA, adrW, delayChannelOutput(3), 
						(IFDvalidArray(4 downto 2), delayChannelValidArray(3)),-- pValidArray
						OPUreadyArray(3 downto 2), 					-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 								-- readyArray
						RFvalidArray);								-- validArray
	
	OPU : entity work.OPunit(branchmerge)
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
						
	-- signals for observation purpose
	resOut <= delayChannelOutput(3);
	resValid <= delayChannelValidArray(3);
						
end elasticBasic_delayedResult3;




------------------------------------------------------------------------
-- based on the elasticBasic implementation.
-- added an elastic buffer to delay the arrival of the OPresult to the
-- register file for writeback
-- should stall every other cycle
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
						adrB, adrA, adrW, ebOut, 
						(IFDvalidArray(4 downto 2), ebValid),-- pValidArray
						OPUreadyArray(3 downto 2), 					-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 								-- readyArray
						RFvalidArray);								-- validArray
	
	OPU : entity work.OPunit(branchmerge)
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
						
	-- signals for observation purpose
	resOut <= ebOut;
	resValid <= ebValid;
						
end elasticBasic_delayedResult1;

