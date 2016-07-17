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
		
		res : out std_logic_vector (31 downto 0)
	);
end OP_unit;

architecture OP_unit1 of OP_unit is
	component sample_op_0 is port (
		a, b : in std_logic_vector(31 downto 0);
		output : out std_logic_vector(31 downto 0)); 
	end component;
	component adder is port(
		a, b : in std_logic_vector(31 downto 0);
		res : out std_logic_vector(31 downto 0);
		carry : out std_logic);
	end component;
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
	addi : adder port map(imm_ext, argA, addi_res, open);
	op0 : sample_op_0 port map (argA, argB, res_op0);
	op1 : adder port map(argA, X"00000001", res_op1, open);
-- extend the immediate argument to a 32 bits signal
	imm_ext <= X"0000" & immArg;
end OP_unit1;


-----------------------------------------------------------------------------  f(a,b) = 2*a+b
library ieee;
use ieee.std_logic_1164.all;

entity sample_op_0 is 
port(
	a, b : in std_logic_vector(31 downto 0);
	output : out std_logic_vector(31 downto 0));
end sample_op_0;

architecture s1 of sample_op_0 is
	signal temp1 : std_logic_vector(31 downto 0);
	signal waste1, waste2 : std_logic;
	component adder is port(
			a, b : in std_logic_vector(31 downto 0); 
			res : out std_logic_vector(31 downto 0);
			carry : out std_logic); 
	end component;
begin
	a1 : adder port map (a, b, temp1, waste1);
	a2 : adder port map (temp1, a, output, waste2);
end s1;


-----------------------------------------------------------------------------   Multiplier - fucked up
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity multiplier is 
	port(
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		res : out std_logic_vector(31 downto 0);
		overflow : out std_logic
	);
end multiplier;

architecture multiplier1 of multiplier is	
	signal res_temp : std_logic_vector (63 downto 0);
begin
	res_temp <= a * b;
	res <= res_temp(31 downto 0);
	overflow <= '0' when res_temp(63 downto 31) = X"00000000" else '1';	
end multiplier1;


-----------------------------------------------------------------------------   Adder
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity adder is
	port (
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		res : out std_logic_vector(31 downto 0);
		carry : out std_logic
	);
end adder;

architecture adder1 of adder is

	signal temp_res : std_logic_vector(32 downto 0);

begin
	
	temp_res <= ('0' & a) + ('0' & b);
	
	res <= temp_res(31 downto 0);
	carry <= temp_res(32);
	
end adder1;








