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
	instr_out, res_out : out std_logic_vector(31 downto 0); -- to allow us to look what's going on inside during tests
end circuit;





------------------------------------------------------------------------
-- first elastic implementation, cf cortadella's paper, p8, fig 13a
------------------------------------------------------------------------
architecture elasticBasic of circuit is

	--output and control signals of the IFD
	signal adrA, adrB, adrW, argI, oc : std_logic_vector;
	signal IFDvalidArray : bitArray_t(4 downto 0);
	-- result of the operation, for writeback
	signal opResult : std_logic_vector(31 downto 0);
	-- registerFile control signals
	signal RFreadyArray : bitArray_t(3 downto 0);
	signal RFvalidArray : bitArray_t(1 downto 0);
	signal RFreadyForWrdata : std_logic;
	-- registerFile output
	signal operandA, operandeB : std_logic_vector(31 downto 0);	
	--OP unit control signals
	signal OPUresultValid : std_logic;
	signal OPUreadyArray : bitArray_t(3 downto 0);
	
begin

	instructionFetchedDecoder : entity work.IFD 
			port map(	clk, reset, 
						data, 						-- instr_in
						adrB, adrA, adrW, argI, oc, 
						dataValid,					-- pValid
						(RFreadyArray(3 downto 1), OPUreadyArray(1 downto 0)),	-- nReadyArray
						IFDready, 					-- ready
						IFDvalidArray);				-- ValidArray
	
	regFile : entity work.registerFile 
			port map(	clk, reset, 
						adrB, adrA, adrW, opResult, 
						(IFDvalidArray(4 downto 2), OPU_resValid), 	-- pValidArray
						OPUreadyArray(3 downto 2), 					-- nReadyArray
						operandeA, operandeB, 
						RFreadyArray, 								-- readyArray
						RFvalidArray);								-- validArray
	(IFDnReadyArray(4 downto 2), RFreadyForWrdata) <= RFreadyArray;
	
	OPU : entity work.OPunit
			port map(	clk, reset,
						operandeB, operandeA, argI, oc, 
						opResult, 
						(RFvalidArray, IFDvalidArray(1 downto 0)),	-- pValidArray
						RFreadyForWrdata, 							-- nReady
						OPUresultValid,								-- valid
						OPUreadyArray);
						
end elasticBasic;
