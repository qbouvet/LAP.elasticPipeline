--------------------------------------------------------------- Selector
------------------------------------------------------------------------
-- joins together controls signals of the results and chose the wanted 
-- result according to oc. Basically a multiplexer with elastic control 
-- signals
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity selectorBlock is
port(	res1, res0, oc : in std_logic_vector(31 downto 0);
		res : out std_logic_vector(31 downto 0);
		pValid : in bitArray_t(2 downto 0);
		nReady : in std_logic;
		readyArray : out bitArray_t(2 downto 0);
		valid : out std_logic);
end selectorBlock;

architecture vanilla of selectorBlock is
begin

	-- a join3 handles control signals 
	joinResAndOc : entity work.join3
			port map (pValid, nReady, valid, readyArray);
	
	-- multiplexer for the data
	process(res0, res1, oc, pValid, nReady)
		-- op is oc(5 downto 0) and opx is oc(11 downto 6)
	begin
		case oc(5) is 
			-- immediate instruction (addi)
			when '1' => res <= res0;
			-- other instructions
			when '0' => 
				case oc(6) is	
					when '1' => res <= res1;
					when others => res <= (others => 'U');
				end case;
			when others => res <= (others => 'U');
		end case;
	end process;
	
end vanilla;





---------------------------------------------------------------- OP unit
------------------------------------------------------------------------
-- groups together the various operations we want and the selector block
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity OP_unit is
	port(
		clk, reset : in std_logic;
		argA, argB : in std_logic_vector (31 downto 0);
		instr, oc : in std_logic_vector(31 downto 0); -- instr for the immediate arguemnt
		res : out std_logic_vector (31 downto 0);
		
		--control signals for argB, argA, instr, oc
		pValidArray : in bitArray_t(3 downto 0);
		nReady : in std_logic;
		valid : out std_logic;
		readyArray : out bitArray_t(3 downto 0));
end OP_unit;

------------------------------------------------------------------------
-- version with simple elastic control signals implementation
------------------------------------------------------------------------
architecture elastic of OP_unit is
	signal argImm, res0, res1 : std_logic_vector (31 downto 0);
	signal forkA_nReady, forkA_valid : bitArray_t(1 downto 0);
	signal forkA_ready : std_logic;
	signal op0_valid, op1_valid : std_logic;
	-- contient les bits n_ready pour op1, op0; oc is done via the entity's signal
	signal selector_opReady : bitArray_t(1 downto 0);
	-- temporary signals since I cant aggregate outputs directly in entities' port maps
	signal addi_ready_array, op1_ready_array : bitArray_t(1 downto 0);
	signal selector_ready_array : bitArray_t(2 downto 0);	
begin
	
	-- extract immediate argument from instruction
	argImm <= X"0000" & instr(21 downto 6);
	
	-- fork for argument A
	forkA : entity work.fork
			port map (clk, reset, pValidArray(2), forkA_nReady(0), forkA_nReady(1), readyArray(2), forkA_valid(0), forkA_valid(1));
	
	addi : entity work.op0
			--port map (argA, argB, res0, forkA_valid(0) & pValidArray(1), selector_opReady(0), (forkA_nReady(0), readyArray(1)), op0_valid);
			port map (argA, argB, res0, forkA_valid(0) & pValidArray(1), selector_opReady(0), addi_ready_array, op0_valid);
			(forkA_nReady(0), readyArray(1)) <= addi_ready_array;
			
	sampleOp1 : entity work.op1
			--port map (argA, argB, res1, forkA_valid(1) & pValidArray(3), selector_opReady(1), (forkA_nReady(1), readyArray(3)), op1_valid);
			port map (argA, argB, res1, forkA_valid(1) & pValidArray(3), selector_opReady(1), op1_ready_array, op1_valid);
			(forkA_nReady(1), readyArray(3)) <= op1_ready_array;
	
	--prends dans l'ordre les control signals de : (2)res1, (1)res0, (0)oc				
	selector : entity work.selectorBlock
			--port map (res1, res0, oc, res, op1_valid & op0_valid & pValidArray(0), nReady, (selector_opReady, readyArray(0)), valid);
			port map (res1, res0, oc, res, op1_valid & op0_valid & pValidArray(0), nReady, selector_ready_array, valid);
			(selector_opReady, readyArray(0)) <= selector_ready_array;
	
end elastic;
