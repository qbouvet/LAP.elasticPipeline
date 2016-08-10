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
	joinResAndOc : entity work.joinN(vanilla) generic map(3)
			port map (pValidArray, nReady, valid, readyArray);
	
	-- multiplexer for the data
	process(res0, res1, oc, pValidArray, nReady)
		-- op is oc(5 downto 0) and opx is oc(11 downto 6)
	begin
		case oc(5) is 
			-- immediate instruction (addi)
			when '0' => res <= res0;
			-- other instructions
			when '1' => 
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
-- architectures : 	- elasticEagerFork
--					- elastic
--					- debug 1-4
--					- elastic2 (debug)
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
-- version elastic control signals and an eager fork
------------------------------------------------------------------------
architecture elasticEagerFork of OPunit is
	signal fork_nReadyArray, fork_validArray : bitArray_t(1 downto 0);	-- (res1, res0), (op1, op0)
	signal res0, res1 : std_logic_vector(31 downto 0);
	signal selector_readyArray : bitArray_t(2 downto 0); 				-- (res1, res0, oc)
	signal op0Ready, op1Ready, op0Valid, op1Valid : std_logic;
	
	signal forkReady, joinArgsValid : std_logic;
	signal joinArgsReadyArray : bitArray_t(2 downto 0);
	
begin

	-- join arguments' control signals 
	joinArgs : entity work.joinN(vanilla) generic map (3)
			port map(	pValidArray(3 downto 1),	-- pValid
						forkReady,					-- nReady
						joinArgsValid,
						joinArgsReadyArray);
	
	-- fork arguments to all operations
	forkA : entity work.forkN(eager) generic map(2)
			port map (	clk, reset, 
						joinArgsValid,			-- pValid
						(op1Ready, op0Ready),	-- nReadyArray
						forkReady,				-- ready
						fork_validArray);		-- validArray	
	
	addi : entity work.op0(forwarding)
			port map (	clk, reset,
						argA, argI, res0, 
						fork_validArray(0),			-- pValid
						selector_readyArray(1), 	-- nReady
						op0Ready, 					-- ready
						op0Valid);					-- valid
			
	sampleOp1 : entity work.op1(forwarding)
			port map (	clk, reset,
						argA, argB, res1, 
						fork_validArray(1),		-- pValid
						selector_readyArray(2), -- n_ready
						op1Ready, 				-- readyArray
						op1Valid);				-- valid
	
	--prends dans l'ordre les control signals de : (2)res1, (1)res0, (0)oc				
	selector : entity work.selectorBlock
			port map (	res1, res0, oc, 
						res, 
						(op1Valid, op0Valid, pValidArray(0)),	-- pValidArray
						nReady, 								-- nReady
						selector_readyArray, 					-- readyArray	-- (op1, op0, oc)
						valid);									-- valid
	readyArray(0) <= selector_readyArray(0);
	
end elasticEagerFork;

------------------------------------------------------------------------
-- version with simple elastic control signals implementation
-- NB : not sure if it works well
------------------------------------------------------------------------
architecture elastic of OPunit is
	signal fork_nReadyArray, fork_validArray : bitArray_t(1 downto 0);	-- (res1, res0), (op1, op0)
	signal res0, res1 : std_logic_vector(31 downto 0);
	signal selector_readyArray : bitArray_t(2 downto 0); 				-- (res1, res0, oc)
	signal op0_readyArray, op1_readyArray : bitArray_t(1 downto 0);		-- (argA, argI), (argB, argA)
	signal op0_valid, op1_valid : std_logic;
begin
	
	-- fork for argument A
	forkA : entity work.forkN generic map(2)
			port map (	clk, reset, 
						pValidArray(2), 					-- p_valid
						fork_nReadyArray, 					-- nReadyArray
						readyArray(2),						-- ready
						fork_validArray);					-- validArray	
	
	addi : entity work.op0
			port map (	clk, reset,
						argA, argI, 
						res0, 
						(fork_validArray(0), pValidArray(1)),	--pValidArray
						selector_readyArray(1), 				-- nReady
						op0_readyArray, 						-- readyArray
						op0_valid);								-- valid
	(fork_nReadyArray(0), readyArray(1)) <= op0_readyArray;
			
	sampleOp1 : entity work.op1
			port map (	clk, reset, 
						argA, argB, 
						res1, 
						(fork_validArray(1), pValidArray(3)),	--p_valid_array
						selector_readyArray(2), 				-- n_ready
						op1_readyArray, 						-- readyArray
						op1_valid);								-- valid
	(fork_nReadyArray(1), readyArray(3)) <= op1_readyArray;
	
	--prends dans l'ordre les control signals de : (2)res1, (1)res0, (0)oc				
	selector : entity work.selectorBlock
			port map (	res1, res0, oc, 
						res, 
						(op1_valid, op0_valid, pValidArray(0)),	-- pValidArray
						nReady, 								-- nReady
						selector_readyArray, 					-- readyArray	-- (op1, op0, oc)
						valid);									-- valid
	readyArray(0) <= selector_readyArray(0);
	
end elastic;
