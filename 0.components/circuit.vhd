library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity circuit is port(
	reset, clk : in std_logic;
	read_instr : out std_logic;
	rddata : in std_logic_vector(31 downto 0);
	rd_adr, instr_out, result_out : out std_logic_vector (31 downto 0));
end circuit;


architecture vanilla of circuit is

	signal op, opx : std_logic_vector(5 downto 0);
	signal  oc, adrA, adrB, wr_adr, argA, argB : std_logic_vector (31 downto 0);
	signal instr, op_res : std_logic_vector(31 downto 0);
	signal rf_wren : std_logic;
	
begin

-- components instantiation
	IFD1 : entity work.IFD port map(reset, clk, rddata, rd_adr, read_instr, instr, rf_wren, adrA, adrB, wr_adr, op, opx, oc);
	RF1 : entity work.regFile port map(clk, reset, adrA, adrB, argA, argB, rf_wren, wr_adr, op_res);
	OPU1 : entity work.OP_unit port map(clk, reset, argA, argB, instr(21 downto 6), op, opx, instr, oc, op_res);
	
-- signals used for checks during simulation
	instr_out <= instr;
	result_out <= op_res;
	
end vanilla;
	
	
	
	
	
	
	
	
