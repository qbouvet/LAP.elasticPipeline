---------------------------------------------------------------- Circuit
------------------------------------------------------------------------
-- implementation of the circuit described in cortadella's papers
-- architectures : 	- elasticBasic
--					- fwdPathResolution
--					- singleFwdPath			(not working)
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
	signal opResultValid 				: std_logic;
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
	signal FUoutputArray				: vectorArray_t(1 downto 0)(31 downto 0);
	signal FUvalidArray,FUreadyArray	: bitArray_t(1 downto 0);					-- (B, A)
	-- temporary signals used to avoid aggregating signals in the port map, which leads to a bug at compilation
	signal FUinputValidArray_temp,
				FUadrValidArray_temp	: bitArray_t(4 downto 0);
	signal FUinputArray_temp			: vectorArray_t(4 downto 0)(31 downto 0);
	
	-- adrW staller block's signals
	signal adrWstallerValid, adrWstallerReady : std_logic;
	
begin

	instructionFetchedDecoder : entity work.instructionFetcherDecoder(elastic) 
			port map(	clk, reset, 
						data, 									-- instr_in
						adrB, adrA, adrW, argI, oc, 
						dataValid,								-- pValid
						(RFreadyArray(3 downto 2), 				-- nReadyArray : (adrB, adrA, adrW, argI, oc)
								adrWstallerReady,
								OPUreadyArray(1 downto 0)),
						IFDready, 								-- ready
						IFDvalidArray,							-- ValidArray : (adrB, adrA, adrW, argI, oc)
						instrOut,	-- outputs the currentl instruction for observation purpose
						ifdEmpty);	-- allows to decide when to stop the simulation
	
	regFile : entity work.registerFile(elastic)
			port map(	clk, reset, 
						adrB, adrA, adrWDelayChannelOutput(3), resDelayChannelOutput(3), 
						(IFDvalidArray(4 downto 3), 			-- pValidArray :  (adrB, adrA, adrW, wrData)
								adrWDelayChannelValidArray(3),
								resDelayChannelValidArray(3)),
						FUreadyArray, 							-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 							-- readyArray : (adrB, adrA, adrW, wrData)
						RFvalidArray);							-- validArray : (a, b)
	
	-- can use elastic, elasticEagerFork, branchmerge, branchmergeHybrid
	OPU : entity work.OPunit(elasticEagerFork)
			port map(	clk, reset,
						FUoutputArray(1), FUoutputArray(0), argI, oc, 	-- (argB, argA, argI, oc)
						opResult, 
						(FUvalidArray, IFDvalidArray(1 downto 0)),		-- pValidArray
						resDelayChannelReady,							-- nReady
						opResultValid,									-- valid
						OPUreadyArray);									-- readyArray : (argB, argA, argI, oc)
						
	-- stall the incoming new wrAdr as long as all the data can't be provided
	adrWstaller : entity work.stallerMem(forEagerFork)
			port map(	clk, reset,
						FUvalidArray(0) and OPUreadyArray(2),
						FUvalidArray(1) and OPUreadyArray(3),
						IFDvalidArray(2), adrWDelayChannelReady,
						adrWstallerValid, adrWstallerReady);
						
	-- ugly stuff that fixes the "unkown questa error"					
	FUadrValidArray_temp 	<= (adrWDelayChannelValidArray(3 downto 1), IFDvalidArray(4 downto 3));	-- adrValidArray : 	(oldest(mem bypass) -> newest WrAdress, readAdrB, readAdrA)1
	FUinputArray_temp 	<= (resDelayChannelOutput(3 downto 1), operandB, operandA); 				-- inputArray : 	(oldest(mem bypass) -> newest result, RF_B, RF_A)
	FUinputValidArray_temp<= (resDelayChannelValidArray(3 downto 1), RFvalidArray(1 downto 0)); 	-- inputValidArray:	(oldest(mem bypass) -> newest WrAdress, rfValid_B, rfValid_A)
	
	adrWDelayChannel : entity work.delayChannel(vanilla) generic map(32, 3)
			port map(	clk, reset,
						adrW, adrWDelayChannelOutput,
						adrWDelayChannelValidArray,
						adrWstallerValid, RFreadyArray(1),
						adrWDelayChannelReady);				
	
	-- delay channels for both operation's result and write address
	resDelayChannel : entity work.delayChannel(vanilla) generic map(32, 3)
			port map(	clk, reset, 
						opResult, resDelayChannelOutput,-- dataIn, dataOut
						resDelayChannelValidArray,		-- validArray
						opResultValid, RFreadyArray(0),	-- pValid, nReady
						resDelayChannelReady);			-- ready
						
	
	-- forwarding unit
	fwdUnit : entity work.forwardingUnit(vanilla) generic map(32, 5)
			port map(	adrB, adrA,
						adrWDelayChannelOutput(3 downto 1),	-- wAdrArray : 				(oldest(mem bypass) -> newest write addresses)
						FUadrValidArray_temp,				-- adrValidArray : 			(oldest(mem bypass) -> newest WrAdress, readAdrB, readAdrA)
						FUInputArray_temp, 					-- inputArray : 			(oldest(mem bypass) -> newest results, RF_B, RF_A)
						FUinputValidArray_temp,				-- inputValidArray : 		(oldest(mem bypass) -> newest WrAdress, rfValid_B, rfValid_A)
						FUoutputArray,						-- outputArray 				(b, a)
						(OPUreadyArray(3),OPUreadyArray(2)),-- nReady
						FUvalidArray, FUreadyArray);		-- validArray, readyArray	(b, a)
						
	-- signals for observation purpose
	resOut <= opResult;
	resValid <= opResultValid;
						
end fwdPathResolution;












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
	signal opResultValid 						: std_logic;
	signal OPUreadyArray 						: bitArray_t(3 downto 0);
	
	--fwdUnit's signals
	signal fwdUnitValidArray, fwdUnitReadyArray : bitArray_t(1 downto 0);					-- (b, a)
	signal fwdUnitOutput						: vectorArray_t(1 downto 0)(31 downto 0); 	-- (b, a)
			
	-- signals that permit a single element to be considered as an array of size one
	signal wAdrToArray							: vectorArray_t(0 downto 0)(31 downto 0);
	
	-- ugly stuff the fixes the "questa unknown error"
	signal FUinputArray_temp 					: vectorArray_t(2 downto 0)(31 downto 0);
	signal FUadrValidArray_temp, 
			FUinputValidArray_temp 				: bitArray_t(2 downto 0);
	
	--elastic buffers' signal
	signal resBufferOut 						: std_logic_vector(31 downto 0);
	signal resBufferReady, resBufferValid		: std_logic;
	signal adrBufferOut 						: std_logic_vector(31 downto 0);
	signal adrBufferReady, adrBufferValid		: std_logic;
		
begin

	instructionFetchedDecoder : entity work.instructionFetcherDecoder(elastic) 
			port map(	clk, reset, 
						data, 															-- instr_in
						adrB, adrA, adrW, argI, oc, 
						dataValid,														-- pValid		
						(RFreadyArray(3 downto 1), adrBufferReady, OPUreadyArray(0)),	-- nReadyArray 	(adrB, adrA, adrW, argI, oc)
						IFDready, 														-- ready
						IFDvalidArray,													-- ValidArray 	(adrB, adrA, adrW, argI, oc)
						instrOut,	-- outputs the currentl instruction for observation purpose
						ifdEmpty);	-- allows to decide when to stop the simulation
	
	regFile : entity work.registerFile(elastic)
			port map(	clk, reset, 
						adrB, adrA, adrBufferOut, resBufferOut, 
						(IFDvalidArray(4 downto 3), adrBufferValid, resBufferValid),	-- pValidArray		(adrB, adrA, adrW, wrData)
						fwdUnitReadyArray,		 										-- nReadyArray		(operandB, operandA)
						operandA, operandB, 
						RFreadyArray, 													-- readyArray		(adrB, adrA, adrW, wrData)
						RFvalidArray);													-- validArray		(operandB, operandA)
	
	-- can use elastic, elasticEagerFork, branchmerge (doesn't work well), branchmergeHybrid
	OPU : entity work.OPunit(branchMergeHybrid)
			port map(	clk, reset,
						fwdUnitOutput(1), fwdUnitOutput(0), argI, oc, 
						opResult, 
						(fwdUnitValidArray, IFDvalidArray(1 downto 0)),	-- pValidArray		(argB, argA, argI, oc)
						resBufferReady, 								-- nReady			
						opResultValid,									-- valid
						OPUreadyArray);									-- readyArray		(argB, argA, argI, oc)

	-- ugly stuff that fixes the "questa unknown error"
	FUadrValidArray_temp <= (adrBufferValid, IFDvalidArray(4 downto 3));
	FUinputArray_temp <= (resBufferOut, operandB, operandA);
	FUinputValidArray_temp <= (resBufferValid, RFvalidArray);							
	-- ugly typecast stuff - NB : wrAdrArray IS (NB_INPUT-1 downto 2), so here (2 downto 2) but it's not a problem to have the (*0* => adrw)
	wAdrToArray <= (0 => adrBufferOut);	-- necessary syntax for arrays of size 1	
						
	fwdUnit : entity work.forwardingUnit(vanilla) generic map(32, 3)
			port map(	adrB, adrA,
						wAdrToArray,
						FUadrValidArray_temp,							-- adrValidArray : 	(adrW, adrB, adrA)
						FUinputArray_temp,								-- inputArray : 	(result, rf_b, rf_a)
						FUinputValidArray_temp,							-- inputValidArray: idem
						fwdUnitOutput,
						OPUreadyArray(3 downto 2),						-- nReadyArray : 	(B, A)
						fwdUnitValidArray, fwdUnitReadyArray);			-- valid/readyArray:(B, A)
			
	resultbuffer : entity work.elasticBuffer(vanilla) generic map(32)
			port map(	clk, reset,	
						opResult, resBufferOut,
						opResultValid, RFreadyArray(0),
						resBufferReady, resBufferValid);
	
	wAdressBuffer : entity work.elasticBuffer(vanilla) generic map(32)
			port map(	clk, reset,	
						adrW,  adrBufferOut,
						IFDvalidArray(2), RFreadyArray(1),
						adrBufferReady, adrBufferValid);
					
	-- signals for observation purpose
	resOut <= opResult;
	resValid <= opResultValid;
	
end singleFwdPath;













------------------------------------------------------------------------
-- first elastic implementation, cf cortadella's paper, p8, fig 13a
------------------------------------------------------------------------
architecture elasticBasic of circuit is
	
	--output and control signals of the IFD
	signal adrA, adrB, adrW, argI, oc 	: std_logic_vector(31 downto 0);
	signal IFDvalidArray 				: bitArray_t(4 downto 0);
	-- result of the operation, for writeback
	signal opResult 					: std_logic_vector(31 downto 0);
	-- registerFile control signals
	signal RFreadyArray 				: bitArray_t(3 downto 0);
	signal RFvalidArray 				: bitArray_t(1 downto 0);
	signal RFreadyForWrdata				: std_logic;
	-- registerFile output
	signal operandA, operandB		 	: std_logic_vector(31 downto 0);	
	--OP unit control signals
	signal opResultValid 				: std_logic;
	signal OPUreadyArray 				: bitArray_t(3 downto 0);
	
begin

	instructionFetchedDecoder : entity work.instructionFetcherDecoder(elastic) 
			port map(	clk, reset, 
						data, 													-- instr_in
						adrB, adrA, adrW, argI, oc, 
						dataValid,												-- pValid		
						(RFreadyArray(3 downto 1), OPUreadyArray(1 downto 0)),	-- nReadyArray 	(adrB, adrA, adrW, argI, oc)
						IFDready, 												-- ready
						IFDvalidArray,											-- ValidArray 	(adrB, adrA, adrW, argI, oc)
						instrOut,	-- outputs the currentl instruction for observation purpose
						ifdEmpty);	-- allows to decide when to stop the simulation
	
	regFile : entity work.registerFile(elastic)
			port map(	clk, reset, 
						adrB, adrA, adrW, opResult, 
						(IFDvalidArray(4 downto 2), opResultValid),	-- pValidArray		(adrB, adrA, adrW, wrData)
						OPUreadyArray(3 downto 2), 					-- nReadyArray		(operandB, operandA)
						operandA, operandB, 
						RFreadyArray, 								-- readyArray		(adrB, adrA, adrW, wrData)
						RFvalidArray);								-- validArray		(operandB, operandA)
	
	-- can use elastic, elasticEagerFork, branchmerge
	OPU : entity work.OPunit(branchMergeHybrid)
			port map(	clk, reset,
						operandB, operandA, argI, oc, 
						opResult, 
						(RFvalidArray, IFDvalidArray(1 downto 0)),	-- pValidArray		(argB, argA, argI, oc)
						RFreadyArray(0), 							-- nReady			
						opResultValid,								-- valid
						OPUreadyArray);								-- readyArray		(argB, argA, argI, oc)
						
end elasticBasic;
