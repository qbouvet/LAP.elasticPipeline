--------------------------------------------------------------  joinN
---------------------------------------------------------------------
-- generic version of Join block
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity joinN is generic (SIZE : integer);
port (
	pValidArray 	: in bitArray_t(SIZE-1 downto 0);
	nReady 			: in std_logic;
	valid 			: out std_logic;
	readyArray 		: out bitArray_t(SIZE-1 downto 0));	
end joinN;

architecture vanilla of joinN is
	signal allPValid : std_logic;
begin
	
	allPValidAndGate : entity work.andN generic map(SIZE)
			port map(	pValidArray,
						allPValid);
	
	valid <= allPValid;
	
	process (pValidArray, allPValid, nReady)
	begin
	for i in 0 to SIZE-1 loop
		readyArray(i) <= (not pValidArray(i)) or (allPValid and nReady);
	end loop;
	end process;
			
end vanilla;





--------------------------------------------------------------  joinN
---------------------------------------------------------------------
-- this version of the joinN stores each of its inputs in an elastic 
-- buffer. It adds a delay of 1 cycle, and needs the actual data
-- (not only its control signals) as inputs/outputs.
-- made to try to fix the "fwdPathResolution" version of "circuit"
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity bufferedJoinN is generic (SIZE : integer);
port (
	clk, reset		: in std_logic;
	dataIn 			: in vectorArray_t(SIZE-1 downto 0)(31 downto 0);
	dataOut 		: out vectorArray_t(SIZE-1 DOWNTO 0)(31 downto 0);
	pValidArray 	: in bitArray_t(SIZE-1 downto 0);
	nReady 			: in std_logic;
	valid 			: out std_logic;
	readyArray 		: out bitArray_t(SIZE-1 downto 0));	
end bufferedJoinN;

architecture vanilla of bufferedJoinN is
	signal allPValid							: std_logic;
	signal bufferOut 							: vectorArray_t(SIZE-1 downto 0)(31 downto 0);
	signal bufferValidArray, joinReadyArray 	: bitArray_t(SIZE-1 downto 0);
	
begin	
	-- generate buffers for all inputs
	buffersGen : for i in SIZE-1 downto 0 generate
		inputBuffer : entity work.elasticBuffer(vanilla) generic map(32)
					port map(	clk, reset,
								dataIn(i), dataOut(i),
								pValidArray(i), joinReadyArray(i),
								readyArray(i), bufferValidArray(i));
	end generate;
	
	-- maps buffers to a joinN
	joinBuffers : entity work.joinN(vanilla) generic map(SIZE)
			port map(	bufferValidArray, nReady,
						valid, joinReadyArray);
			
end vanilla;






















--------------------------------------------------------------------- Older versions, kept for backup purpose only
---------------------------------------------------------------------
---------------------------------------------------------------------




---------------------------------------------------------------  join
---------------------------------------------------------------------
-- joins the control signals of 2 elastic buffers into a single 
-- control signal. Simple version without anti-tokens stuff.
-- implementation from "Cortadella elastic systems", paper 2, p3
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity join is
port(
	p_valid1, p_valid0, n_ready : in std_logic;
	valid, ready1, ready0 : out std_logic);
end join;

---------------------------------------------------------------------
-- the architecture as in cortadellas paper
---------------------------------------------------------------------
architecture cortadellas of join is
begin

	valid <= p_valid0 and p_valid1;
	-- is the first term necessary ??          
	ready0 <= (not p_valid0) or (p_valid0 and p_valid1 and n_ready); 
	ready1 <= (not p_valid1) or (p_valid0 and p_valid1 and n_ready); 

end cortadellas;

---------------------------------------------------------------------
-- the architecture that does not get ready when waiting on a pValid signal
-- (worked well with eager forks ?)
---------------------------------------------------------------------
architecture try of join is
begin

	valid <= p_valid0 and p_valid1;       
	ready0 <= (p_valid0 and p_valid1 and n_ready); 
	ready1 <= (p_valid0 and p_valid1 and n_ready); 

end try;


--------------------------------------------------------------  join3
---------------------------------------------------------------------
-- and adapted version of the join, based on the same logic equations
-- as cortadella's, to join the control signals from 3 inputs
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity join3 is
port(	pValidArray : in bitArray_t(2 downto 0);
		nReady : in std_logic;
		valid : out std_logic;
		readyArray : out bitArray_t(2 downto 0));
end join3;

architecture vanilla of join3 is
		-- internal value for readybility
	signal allPValid : std_logic;
begin

	valid <= allPValid;
	
	readyArray(0) <= (not pValidArray(0)) or (allPValid and nReady);
	readyArray(1) <= (not pValidArray(1)) or (allPValid and nReady);
	readyArray(2) <= (not pValidArray(2)) or (allPValid and nReady);
	
	allPValid <= (pValidArray(0) and pValidArray(1) and pValidArray(2));	
	
end vanilla;
		
