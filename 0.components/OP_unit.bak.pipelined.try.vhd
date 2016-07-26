-----------------------------------------------------------   OP_unit
---------------------------------------------------------------------
-- the unit that actually executes instructions
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OP_unit is
	port(
		clk, reset : in std_logic;
		argA, argB : in std_logic_vector (31 downto 0);
		immArg : in std_logic_vector (15 downto 0);
		
		op, opx : in std_logic_vector (5 downto 0); --may be replaced by oc
		instr, oc : in std_logic_vector(31 downto 0); -- instr just in case, oc as possible replacement for op, opx
		
		res : out std_logic_vector (31 downto 0);
		
		p_valid, n_ready : in std_logic;
		ready, valid : out std_logic
	);
end OP_unit;

architecture pipelined of OP_unit is
	signal imm_ext, addi_res, op0_res, op1_res : std_logic_vector (31 downto 0);
	signal f_valid, f_nready, j_pvalid, j_ready : array (1 downto 0) of std_logic;
	signal f_ready, f_pvalid, j_valid, j_nready : std_logic;
begin
	
-- choose the output according to the op/opx/oc
	process(addi_res, res_op0, res_op1, op, opx, oc)
	begin
		case op(5) is 
			-- immediate instruction (addi)
			when '1' => res <= addi_res;
			-- other instructions
			when '0' => 
				case opx(1) is	
					when '0' => res <= res_op0;
					when '1' => res <= res_op1;
					when others => res <= (others => 'U');
				end case;
			when others => res <= (others => 'U');
		end case;
	end process;

-- datapath
	forkOP : entity work.fork(lazy)
			port map(clk, reset, p_valid, f_nready(0), f_nready(1), f_ready, f_valid(0), f_valid(1));
			
	addi : entity work.adderWithBuffers 
			port map(clk, reset, imm_ext, argA, addi_res, open, f_valid(0), j_ready(0), f_nready(0), j_pvalid(0));
	op1 : entity work.sample_op_1(pipelined) 
			port map (clk, reset, argA, argB, op1_res, f_valid(1), j_ready(1), f_nready(1), j_pvalid(1));
			
	joinOP : entity work.join(lazy)
			port map(j_pvalid(0), j_pvalid(1), n_ready, valid, j_ready(0), j_ready(1));
			
-- extend the immediate argument to a 32 bits signal
	imm_ext <= X"0000" & immArg;
	
end pipelined;



-----------------------------------------------------------------------------  the selector signal path & select block
library ieee;
use ieee.std_logic_1164.all;

entity OP_unit_selectorBlock is
port(	clk, reset : in std_logic;
		op, opx : in std_logic_vector(5 downto 0);
		instr, oc : in std_logic_vector(31 downto 0); 
		ops_results : in array (2 downto 0) of std_logic_vector(31 downto 0);
		results : out std_logic_vector(31 downto 0);
		
		--elastic control signals
		ifd_valid, n_ready : in std_logic;
		 
);
end OP_unit_selectorBlock;

architecture OP_unit_selectorBlock1 of OP_unit_selectorBlock is
	signal delayed_sel : array (1 downto 0) of std_logic_vector(31 downto 0);
	signal zero : std_logic_vector(19 downto 0) := (others => '0');
begin

	b0 : entity work.elasticBuffer_reg generic map(31 downto 0);
			port map(reset, clk, zero&op&opx, delayed_sel, );
	b1 : entity work.elasticBuffer_reg generic map(31 downto 0);
			port map(reset, clk, );
	b2 : entity work.elasticBuffer_reg generic map(31 downto 0);
			port map(reset, clk, );

end OP_unit_selectorBlock1;










