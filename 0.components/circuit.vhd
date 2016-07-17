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
--components
	component IFD is port(
		reset, clk : in std_logic;
		rddata : in std_logic_vector(31 downto 0);
		rd_addr : out std_logic_vector(31 downto 0);
		read_instr : out std_logic;
		instr : out std_logic_vector(31 downto 0);
		rf_wren : out std_logic;
		adrA, adrB, wr_adr : out std_logic_vector(31 downto 0);
		op,opx : out std_logic_vector(5 downto 0); --may be replaced by oc
		oc : out std_logic_vector(31 downto 0));
	end component;
	component regFile is port (
		clk, reset : in std_logic;
		adr_a, adr_b : in std_logic_vector(31 downto 0);
		aa, ab : out std_logic_vector(31 downto 0);
		wr_enable : in std_logic;
		wr_adr, wr_data : in std_logic_vector(31 downto 0));
	end component;
	component OP_unit is port ( 
		clk, reset : in std_logic;
		argA, argB : in std_logic_vector (31 downto 0);
		immArg : in std_logic_vector (15 downto 0);		
		op, opx : in std_logic_vector (5 downto 0);
		instr, oc : in std_logic_vector(31 downto 0);
		res : out std_logic_vector (31 downto 0));
	end component;
-- signals
	signal op, opx : std_logic_vector(5 downto 0);
	signal  oc, adrA, adrB, wr_adr, argA, argB : std_logic_vector (31 downto 0);
	signal instr, op_res : std_logic_vector(31 downto 0);
	signal rf_wren : std_logic;
begin
-- components
	IFD1 : IFD port map(reset, clk, rddata, rd_adr, read_instr, instr, rf_wren, adrA, adrB, wr_adr, op, opx, oc);
	RF1 : regFile port map(clk, reset, adrA, adrB, argA, argB, rf_wren, wr_adr, op_res);
	OPU1 : OP_unit port map(clk, reset, argA, argB, instr(21 downto 6), op, opx, instr, oc, op_res);
-- interface signals 
	--none actually, everything is done through the mappings
-- signals used for checks during simulation
	instr_out <= instr;
	result_out <= op_res;
end vanilla;
	
	
	
	
	
	
	
	
	
