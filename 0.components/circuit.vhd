---------------------------------------------------------------- Circuit
------------------------------------------------------------------------
-- implementation of the circuit described in cortadella's papers
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
