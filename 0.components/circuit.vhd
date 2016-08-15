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
	resValid, ifdEmpty 							: out std_logic; 					-- idem + to decide when to finish the simulation
	RFreadyArray_out 							: out bitArray_t(3 downto 0);		-- debug
	FPRUaValidOut, FPRUbValidOut 				: out std_logic;
	FRPUaInputValidArray, FRPUbInputValidArray,
		FRPUaAdrValidArray, FRPUbAdrValidArray 	: out bitArray_t(3 downto 0);
	IFDvalidArray_out 							: out bitArray_t(4 downto 0);
	OPUreadyArray_out 							: out bitArray_t(3 downto 0)
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
						adrB, adrA, adrW, opResult, 
						(IFDvalidArray(4 downto 3), 				-- pValidArray :  (adrB, adrA, adrW, wrData)
								adrWDelayChannelValidArray(3),
								resDelayChannelValidArray(3)),
						FPRUreadyArray, 							-- nReadyArray
						operandA, operandB, 
						RFreadyArray, 								-- readyArray : (adrB, adrA, adrW, wrData)
						RFvalidArray);								-- validArray : (a, b)
	
	-- can use elastic, elasticEagerFork, branchmerge
	OPU : entity work.OPunit(branchmerge)
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
						
	FPRUadrValidArray_temp 	<= (adrWDelayChannelValidArray(3 downto 1), IFDvalidArray(4), IFDvalidArray(3));	-- adrValidArray : 	(oldest(mem bypass) -> newest WrAdress, readAdrB, readAdrA)
	FPRUinputArray_temp 	<= (resDelayChannelOutput(3 downto 1), operandB, operandA); 						-- inputArray : 	(oldest(mem bypass) -> newest result, RF_B, RF_A)
	FPRUinputValidArray_temp<= (resDelayChannelValidArray(3 downto 1), RFvalidArray(1), RFvalidArray(0)); 		-- inputValidArray:	(oldest(mem bypass) -> newest WrAdress, rfValid_B, rfValid_A)
	
	-- dependancy resolution unit
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
	OPU : entity work.OPunit(branchmerge)
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


