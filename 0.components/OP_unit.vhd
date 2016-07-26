---------------------------------------------------------------- OP unit
------------------------------------------------------------------------
-- groups together the various operations we want and the selector block
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OP_unit is
	port(
		clk, reset : in std_logic;
		argA, argB : in std_logic_vector (31 downto 0);
		immArg : in std_logic_vector (15 downto 0);
		
		instr, oc : in std_logic_vector(31 downto 0); -- instr just in case
		
		res : out std_logic_vector (31 downto 0);
		
		p_valid, n_ready : in std_logic;
		ready, valid : out std_logic
	);
end OP_unit;


------------------------------------------------------------------------
-- version with simple elastic control signals implementation
------------------------------------------------------------------------
architecture elastic of OP_unit is
	signal imm_ext, addi_res, res_op0, res_op1 : std_logic_vector (31 downto 0);
begin
	
						-- TODOOOOOOOOOOOO                                                   -- big todo
	
end elastic;





------------------------------------------------------------------------
-- vanilla implementation without elastic control signals
------------------------------------------------------------------------
architecture vanilla of OP_unit is
	signal imm_ext, addi_res, res_op0, res_op1 : std_logic_vector (31 downto 0);
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
	
-- instantiate operations
	addi : entity work.adder port map(imm_ext, argA, addi_res, open);
	op0 : entity work.sample_op_0 port map (argA, argB, res_op0);
	op1 : entity work.adder port map(argA, X"00000001", res_op1, open);
-- extend the immediate argument to a 32 bits signal
	imm_ext <= X"0000" & immArg;
end vanilla;










