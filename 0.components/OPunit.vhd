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
		pValidArray : in bitArray_t(2 downto 0);
		nReady : in std_logic;
		readyArray : out bitArray_t(2 downto 0);
		valid : out std_logic);
end selectorBlock;

architecture vanilla of selectorBlock is
begin

	-- a join3 handles control signals 
	joinResAndOc : entity work.join3
			port map (pValidArray, nReady, valid, readyArray);
	
	-- multiplexer for the data
	process(res0, res1, oc, pValidArray, nReady)
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
-- groups together the various operations we want + the selector block
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity OPunit is
	port(
		clk, reset : in std_logic;
		argB, argA, argI, oc : in std_logic_vector (31 downto 0); -- operande, immediate argument and opcode
		res : out std_logic_vector (31 downto 0);
		
		--control signals for argB, argA, argI, oc
		pValidArray : in bitArray_t(3 downto 0);
		nReady : in std_logic;
		valid : out std_logic;
		readyArray : out bitArray_t(3 downto 0));
end OPunit;

------------------------------------------------------------------------
-- version with simple elastic control signals implementation
------------------------------------------------------------------------
architecture elastic of OPunit is
	-- results
	signal res0, res1 : std_logic_vector (31 downto 0);
	--fork control signals
	signal forkA_nReadyArray, forkA_validArray : bitArray_t(1 downto 0);
	signal forkA_ready : std_logic;
	signal op0_valid, op1_valid : std_logic;
	-- contient les bits n_ready pour op1, op0; oc is done via the entity's signal
	signal selector_opReady : bitArray_t(1 downto 0);
	-- temporary signals since I cant aggregate outputs directly in entities' port maps
	signal addi_ready_array, op1_ready_array : bitArray_t(1 downto 0);
	signal selector_ready_array : bitArray_t(2 downto 0);	
begin
	
	-- fork for argument A
	forkA : entity work.forkN generic map(2)
			port map (	clk, reset, 
						pValidArray(2), 					-- p_valid
						forkA_nReadyArray, 					-- nReadyArray
						forkA_validArray,					-- validArray
						readyArray(2));						-- ready
	
	addi : entity work.op0
			port map (	argA, argI, 
						res0, 
						forkA_validArray(0) & pValidArray(1),--pValidArray
						selector_opReady(0), 				-- nReady
						addi_ready_array, 					-- readyArray
						op0_valid);							-- valid
	(forkA_nReadyArray(0), readyArray(1)) <= addi_ready_array;
			
	sampleOp1 : entity work.op1
			port map (	argA, argB, 
						res1, 
						forkA_validArray(1) & pValidArray(3),--p_valid_array
						selector_opReady(1), 				-- n_ready
						op1_ready_array, 					-- readyArray
						op1_valid);							-- valid
	(forkA_nReadyArray(1), readyArray(3)) <= op1_ready_array;
	
	--prends dans l'ordre les control signals de : (2)res1, (1)res0, (0)oc				
	selector : entity work.selectorBlock
			port map (	res1, res0, oc, 
						res, 
						op1_valid & op0_valid & pValidArray(0),	-- pValidArray
						nReady, 								-- nReady
						selector_ready_array, 					-- readyArray
						valid);									-- valid
	(selector_opReady, readyArray(0)) <= selector_ready_array;
	
end elastic;
