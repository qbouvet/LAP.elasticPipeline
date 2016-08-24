--------------------------------------------------------------- Selector
------------------------------------------------------------------------
-- sub-component
-- joins together controls signals of the results and chose the wanted 
-- result according to oc. Basically a multiplexer with elastic control 
-- signals
-- replaced by the merge in branchmerge and branchmergeHybrid versions
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


---------------------------------------------------------------- OP unit
------------------------------------------------------------------------
-- groups together the various operations we want + the selector block
-- architectures : 	- elasticEagerFork
--					- branchmergeHybrid	
--					- branchmerge		(doesn't work whenever some latency changes in the circuit)
--					- elastic 			(maybe not functionnal)
--					- debug 1-4
--					- elastic2 			(debug)
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity OPunit is port(
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
-- version elastic control signals and an eager fork and a "big join" 
-- that joins all arguments at first
------------------------------------------------------------------------
architecture branchmergeHybrid of OPunit is
	
	-- standard signals
	signal joinArgsValid, addiReady, addiValid, op1Ready, 
			op1Valid			 							: std_logic;
	signal branchValidArray, branchReadyArray, ocForkValidArray	: bitArray_t(1 downto 0);
	signal mergeReadyArray 									: bitArray_t(2 downto 0);	-- (data1, data0, condition)
	signal res0, res1 										: std_logic_vector(31 downto 0);
	
	-- signals for the bufferedJoin
	signal bufferedJoinOutput								: vectorArray_t(2 downto 0)(31 downto 0);	-- (argB, argA, argI)

begin

	-- join all arguments' control signals at first
	joinArgs : entity work.joinN(vanilla) generic map (3)
			port map(	pValidArray(3 downto 1),	-- pValid
						branchReadyArray(1),		-- nReady
						joinArgsValid,
						readyArray(3 downto 1));
--	joinArgs : entity work.bufferedJoinN(vanilla) generic map (3)
--			port map(	clk, reset,
--						(argB, argA, argI), bufferedJoinOutput,	-- dataIn, dataOut	: 	(argB, argA, argI)
--						pValidArray(3 downto 1),				-- pValid
--						branchReadyArray(1),					-- nReady
--						joinArgsValid,
--						readyArray(3 downto 1));
						
	-- sends arguments to the wanted operation (only to it)
	branchArgs : entity work.branchHybrid(vanilla)
			port map(	oc(6) and oc(5),		-- condition : op1
						ocForkValidArray(1),	-- conditionValid
						joinArgsValid,			-- pValid		
						(op1Ready, addiReady),	-- nReadyArray		(branch1, branch0)
						branchValidArray, 		-- validArray 		(branch1, branch0)
						branchReadyArray);		-- readyArray		(data, condition)
	
	-- addi operation	
	-- can be : forwarding, delay1				
	addi : entity work.op0(delay1)
			port map(	clk, reset,
						argA, argI, res0,
						branchValidArray(0),-- pValid
						mergeReadyArray(0),	-- nReady
						addiReady, addiValid);	-- (ready, valid)
	-- other operation					
	sampleOp1 : entity work.op1(forwarding)
			port map(	clk, reset,
						argA, argB, res1,
						branchValidArray(1),-- pValid
						mergeReadyArray(1),	-- nReady
						op1Ready, op1Valid);-- (ready, valid)
						
	-- merge the results
	mergeRes : entity work.mergeHybrid(vanilla)
			port map(	res1, res0, res,
						oc(6) and oc(5),							-- condition
						(op1Valid, addiValid, ocForkValidArray(0)),	-- pValidArray
						nReady,										-- nReady
						valid,										-- valid
						mergeReadyArray);							-- readyArray	(res1, res0, condition)
--	mergeRes : entity work.mergeHybridBuffered(vanilla)
--			port map(	clk,reset,
--						res1, res0, res,
--						oc(6) and oc(5),							-- condition
--						(op1Valid, addiValid, ocForkValidArray(0)),	-- pValidArray
--						nReady,										-- nReady
--						valid,										-- valid
--						mergeReadyArray);							-- readyArray	(res1, res0, condition)						
												
	-- fork 'oc' to the branch and merge		
	forkOpCode : entity work.forkN(eager) generic map(2)
			port map(	clk, reset,	
						pValidArray(0),
						(branchReadyArray(0), mergeReadyArray(0)),	-- nReadyArray (branch, merge)
						readyArray(0),
						ocForkValidArray);							-- validArray (branch, merge)

end branchmergeHybrid;






------------------------------------------------------------------------
-- version elastic control signals and an eager fork and a "big join" 
-- that joins all arguments at first
------------------------------------------------------------------------
architecture elasticEagerFork of OPunit is
	signal fork_validArray : bitArray_t(1 downto 0);			-- (op1, op0)
	signal res0, res1 : std_logic_vector(31 downto 0);
	signal selector_readyArray : bitArray_t(2 downto 0); 		-- (res1, res0, oc)
	signal op0Ready, op1Ready, op0Valid, op1Valid : std_logic;
	
	signal forkReady, joinArgsValid : std_logic;
	
begin

	-- join all arguments' control signals at first
	joinArgs : entity work.joinN(vanilla) generic map (3)
			port map(	pValidArray(3 downto 1),	-- pValid
						forkReady,					-- nReady
						joinArgsValid,
						readyArray(3 downto 1));
	
	-- fork arguments to all operations
	forkArgs : entity work.forkN(eager) generic map(2)
			port map (	clk, reset, 
						joinArgsValid,			-- pValid
						(op1Ready, op0Ready),	-- nReadyArray
						forkReady,				-- ready
						fork_validArray);		-- validArray	
	
	-- can be : forwarding, delay1
	addi : entity work.op0(delay1)
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
	signal op0Ready, op1Ready, op0Valid, op1Valid : std_logic;
	
	signal forkReady, joinArgsValid : std_logic;
begin

	-- join arguments' control signals 
	joinArgs : entity work.joinN(vanilla) generic map (3)
			port map(	pValidArray(3 downto 1),	-- pValid
						forkReady,					-- nReady
						joinArgsValid,
						readyArray(3 downto 1));
	
	-- fork arguments
	forkArgs : entity work.forkN generic map(2)
			port map (	clk, reset, 
						joinArgsValid,			-- pValid
						(op1Ready, op0Ready),	-- nReadyArray
						forkReady,				-- ready
						fork_validArray);		-- validArray	
	
	-- can be : forwarding, delay1
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
	
end elastic;











------------------------------------------------------------------------
-- version elastic control signals and an eager fork and a "big join" 
-- that joins all arguments at first
-- DOESN'T WORK WELL
------------------------------------------------------------------------
architecture branchmerge of OPunit is
	
	signal joinArgsValid, branchReady, mergeReady, addiReady, addiValid, op1Ready, op1Valid : std_logic;
	signal branchValidArray, mergeReadyArray : bitArray_t(1 downto 0);
	signal res0, res1  : std_logic_vector(31 downto 0);

begin

	-- join all arguments' control signals at first
	joinArgs : entity work.joinN(vanilla) generic map (3)
			port map(	pValidArray(3 downto 1),	-- pValid
						branchReady,				-- nReady
						joinArgsValid,
						readyArray(3 downto 1));
						
	-- sends arguments to the wanted operation (only to it)
	branchArgs : entity work.branch(vanilla)
			port map(	oc(6) and oc(5),		-- condition : op1
						joinArgsValid,			-- pValid		
						(op1Ready, addiReady),	-- nReadyArray		(branch1, branch0)
						branchValidArray, 		-- ready
						branchReady);			-- validArray 		(branch1, branch0)
	
	-- addi operation			
	-- can be : forwarding, delay1		
	addi : entity work.op0(forwarding)
			port map(	clk, reset,
						argA, argI, res0,
						branchValidArray(0),-- pValid
						mergeReadyArray(0),	-- nReady
						addiReady, addiValid);	-- (ready, valid)
	-- other operation					
	sampleOp1 : entity work.op1(forwarding)
			port map(	clk, reset,
						argA, argB, res1,
						branchValidArray(1),-- pValid
						mergeReadyArray(1),	-- nReady
						op1Ready, op1Valid);-- (ready, valid)
						
	-- merge the results
	mergeRes : entity work.merge(vanilla)
			port map(	res1, res0, res,
						(op1Valid, addiValid),	-- pValidArray
						nReady,					-- nReady
						valid,					-- valid
						mergeReadyArray);		-- readyArray		
						
	-- should add control signal for branch's condition and remove this ugly assignment
	readyArray(0) <= '1';		

end branchmerge;
























------------------------------------------------------------------------
-- architecture for the selectorBlock
------------------------------------------------------------------------
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
