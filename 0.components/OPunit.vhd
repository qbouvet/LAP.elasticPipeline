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
	signal op0_readyArray, op1_readyArray : bitArray_t(1 downto 0);		-- (argA, argI), (argB, argA)
	signal op0_valid, op1_valid : std_logic;
begin
	
	-- fork for argument A
	forkA : entity work.fork(eager)
			port map (	clk, reset, 
						pValidArray(2), 					-- p_valid
						fork_nReadyArray(1),fork_nReadyArray(0),-- nReadyArray
						readyArray(2),						-- ready
						fork_validArray(1), fork_validArray(0));					-- validArray	
	
	addi : entity work.op0(forwarding)
			port map (	clk, reset,
						argA, argI, 
						res0, 
						(fork_validArray(0), pValidArray(1)),	--pValidArray
						selector_readyArray(1), 				-- nReady
						op0_readyArray, 						-- readyArray
						op0_valid);								-- valid
	(fork_nReadyArray(0), readyArray(1)) <= op0_readyArray;
			
	sampleOp1 : entity work.op1(forwarding)
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
	
end elasticEagerFork;

------------------------------------------------------------------------
-- version with simple elastic control signals implementation
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








------------------------------------------------------------------------
-- version with fewer blocks in it for debug purpose
------------------------------------------------------------------------
architecture debug4 of OPunit is

	signal fork_nReadyArray, fork_validArray : bitArray_t(1 downto 0);	-- (res1, res0), (op1, op0)
	signal res0, res1 : std_logic_vector(31 downto 0);
	signal selector_readyArray : bitArray_t(2 downto 0); 				-- (res1, res0, oc)
	signal op0_readyArray, op1_readyArray : bitArray_t(1 downto 0);		-- (argA, argI), (argB, argA)
	signal op0_valid, op1_valid : std_logic;
	
begin

	res1 <= argA;
	res0 <= argA;
	
	forkArgA : entity work.forkN generic map(2)
			port map(	clk, reset,
						pValidArray(2),
						fork_nReadyArray,
						readyArray(2),
						fork_validArray);
	fork_nReadyArray <= selector_readyArray(2 downto 1);
	
	--prends dans l'ordre les control signals de : (2)res1, (1)res0, (0)oc
	selector : entity work.selectorBlock
			port map (	res1, res0, oc, 
						res, 
						(fork_validArray, pValidArray(0)),		-- pValidArray
						nReady, 									-- nReady
						selector_readyArray, 						-- readyArray	-- (op1, op0, oc)
						valid);										-- valid
						
	readyArray(3) <= '1'; -- argB not used now
	readyArray(1) <= '1'; -- argI not used now
	readyArray(0) <= selector_readyArray(0);
	
end debug4;









------------------------------------------------------------------------
-- version with fewer blocks in it for debug purpose - exceeds iterations limits
------------------------------------------------------------------------
architecture debug3 of OPunit is

	signal fork_nReadyArray, fork_validArray : bitArray_t(1 downto 0);	-- (res1, res0), (op1, op0)
	signal res0, res1 : std_logic_vector(31 downto 0);
	signal selector_readyArray : bitArray_t(2 downto 0); 				-- (res1, res0, oc)
	signal op0_readyArray, op1_readyArray : bitArray_t(1 downto 0);		-- (argA, argI), (argB, argA)
	signal op0_valid, op1_valid : std_logic;
	
begin

	res1 <= argA;
	op1_valid <= fork_validArray(1);
	
	forkArgA : entity work.forkN generic map(2)
			port map(	clk, reset,
						pValidArray(2),
						fork_nReadyArray,
						readyArray(2),
						fork_validArray);
	fork_nReadyArray <= ( selector_readyArray(2), op0_readyArray(1));
	
	addi : entity work.op0
			port map (	clk, reset, 
						argA, argI, 
						res0, 
						(fork_validArray(0), pValidArray(1)),	--pValidArray
						selector_readyArray(1), 				-- nReady
						op0_readyArray, 						-- readyArray
						op0_valid);								-- valid
	readyArray(1) <= op0_readyArray(0);
	
	--prends dans l'ordre les control signals de : (2)res1, (1)res0, (0)oc				
	selector : entity work.selectorBlock
			port map (	res1, res0, oc, 
						res, 
						(op1_valid, op0_valid, pValidArray(0)),	-- pValidArray
						nReady, 									-- nReady
						selector_readyArray, 						-- readyArray	-- (op1, op0, oc)
						valid);										-- valid
	readyArray(3) <= '0'; --not used now
	readyArray(0) <= selector_readyArray(0);
	
end debug3;




------------------------------------------------------------------------
-- version without operations in it for debug purpose - doesn't exceed iteration limit
------------------------------------------------------------------------
architecture debug2 of OPunit is
	-- results
	signal res0, res1 : std_logic_vector (31 downto 0);
	--fork control signals
	--signal forkA_nReadyArray, forkA_validArray : bitArray_t(1 downto 0);
	--signal forkA_ready : std_logic;
	signal op0_valid, op1_valid : std_logic;
	-- temporary signals since I cant aggregate outputs directly in entities' port maps
	signal addi_ready_array, op1_ready_array : bitArray_t(1 downto 0);
	signal selector_readyArray : bitArray_t(2 downto 0);	
begin

	res1 <= argB;
	op1_valid <= pValidArray(3);
	
	addi : entity work.op0
			port map (	clk, reset, 
						argA, argI, 
						res0, 
						(pValidArray(2), pValidArray(1)),	--pValidArray
						selector_readyArray(1), 				-- nReady
						addi_ready_array, 						-- readyArray
						op0_valid);								-- valid
	(readyArray(2), readyArray(1)) <= addi_ready_array;
	
	--prends dans l'ordre les control signals de : (2)res1, (1)res0, (0)oc				
	selector : entity work.selectorBlock
			port map (	res1, res0, oc, 
						res, 
						(op1_valid, op0_valid, pValidArray(0)),	-- pValidArray
						nReady, 									-- nReady
						selector_readyArray, 						-- readyArray	-- (op1, op0, oc)
						valid);										-- valid
	readyArray(3) <= selector_readyArray(2);
	readyArray(0) <= selector_readyArray(0);
	
end debug2;




------------------------------------------------------------------------
-- version without operations in it for debug purpose - doesn't exceed iteration limit
------------------------------------------------------------------------
architecture debug1 of OPunit is
	-- results
	signal res0, res1 : std_logic_vector (31 downto 0);
	--fork control signals
	--signal forkA_nReadyArray, forkA_validArray : bitArray_t(1 downto 0);
	--signal forkA_ready : std_logic;
	signal op0_valid, op1_valid : std_logic;
	-- temporary signals since I cant aggregate outputs directly in entities' port maps
	--signal addi_ready_array, op1_ready_array : bitArray_t(1 downto 0);
	signal selector_readyArray : bitArray_t(2 downto 0);	
begin

	res0 <= argA;
	res1 <= argB;
	op0_valid <= pValidArray(2);
	op1_valid <= pValidArray(3);
	
	--prends dans l'ordre les control signals de : (2)res1, (1)res0, (0)oc				
	selector : entity work.selectorBlock
			port map (	res1, res0, oc, 
						res, 
						(op1_valid, op0_valid, pValidArray(0)),	-- pValidArray
						nReady, 									-- nReady
						selector_readyArray, 						-- readyArray	-- (op1, op0, oc)
						valid);										-- valid
	(readyArray(3), readyArray(2), readyArray(0)) <= selector_readyArray;
	readyArray(1) <= '1';
	
end debug1;





------------------------------------------------------------------------
-- for debug purpose - in the end, exactly the same thing as 'elastic' architecture
------------------------------------------------------------------------
architecture elastic2 of OPunit is
	
	signal fork_nReadyArray, fork_validArray : bitArray_t(1 downto 0);	-- (res1, res0), (argB, argA)
	signal res0, res1 : std_logic_vector(31 downto 0);
	signal selector_readyArray : bitArray_t(2 downto 0); 				-- (res1, res0, oc)
	signal op0_readyArray, op1_readyArray : bitArray_t(1 downto 0);		-- (argA, argI), (argB, argA)
	signal op0_valid, op1_valid : std_logic;
	
begin
	
	forkArgA : entity work.forkN generic map (2)
			port map (	clk, reset,
						pValidArray(2),
						fork_nReadyArray,
						readyArray(2),
						fork_validArray);
						
	addi : entity work.op0 
			port map(	clk, reset, 
						argA, argI,
						res0, 
						(fork_validArray(0), pValidArray(1)),
						selector_readyArray(1),
						op0_readyArray,	--(argA, argI)
						op0_valid);
	(fork_nReadyArray(0), readyArray(1)) <= op0_readyArray;
	
	sample_op1 : entity work.op1 
			port map(	clk, reset, 
						argB, argA,
						res1, 
						(fork_validArray(1), pValidArray(3)),
						selector_readyArray(2),
						op1_readyArray,
						op1_valid);
	(fork_nReadyArray(1), readyArray(3)) <= op1_readyArray;
	
	selector : entity work.selectorBlock
			port map( 	res1, res0, oc,
						res, 
						(op1_valid, op0_valid, pValidArray(0)),
						nReady,
						selector_readyArray,
						valid);
	readyArray(0) <= selector_readyArray(0);
	
end elastic2;
