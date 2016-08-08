-------------------------------------------------------  delayChannel
---------------------------------------------------------------------
-- Basically a generic bunch of elastic buffers chained together.
-- will delay the input data by the generic DELAY given, and 
-- also outputs each piece of data in the buffers in the 
-- data_out array of std_logic_vectors to be able to bypass 
-- unnecessary buffers.
-- on the output signal 'signal', signal(i) is the signal of delay i
-- NB i=0 -> straight input signal
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity delayChannel is
generic( 	DATA_SIZE : integer;
			DELAY : integer);
port(	clk, reset : in std_logic;
		data_in : in std_logic_vector(DATA_SIZE-1 downto 0);
		-- all the delayed outputs
		data_out : out vectorArray_t(DELAY downto 0)(DATA_SIZE-1 DOWNTO 0); -- we want data_out(0) to select the signal with 0 delay
		--elastic control signals
		valid : out bitArray_t(DELAY downto 0); -- same as data_out
		p_valid, n_ready : in std_logic;
		ready : out std_logic
); 
end delayChannel;



architecture vanilla of delayChannel is
	type bitArray is array(integer range <>) of std_logic;
	--signals used to link the buffers together	
	signal data : vectorArray_t (DELAY-1 downto 0)(DATA_SIZE-1 downto 0);
	signal buffer_ready : bitArray_t(DELAY-1 downto 1); -- only between two buffers from the chain
	signal buffer_valid : bitArray_t(DELAY-1 downto 0); -- we need one more to map the valid signal of the last buffer
begin

	-- instantiate the chain of buffers
	inputBuffer : entity work.elasticBuffer(vanilla)  generic map(DATA_SIZE)
			port map(	clk, reset, 
						data_in, data(DELAY-1), 
						p_valid, buffer_ready(DELAY-1), 	-- pValid, nReady
						ready, buffer_valid(DELAY-1)); 		-- ready, valid
	
	genBuffers : for n in DELAY-1 downto 2 generate
		intermediateBuffer : entity work.elasticBuffer(vanilla)  generic map(DATA_SIZE)
				port map (	clk, reset, 
							data(n), data(n-1), 
							buffer_valid(n), buffer_ready(n-1), 	-- pValid, nReady
							buffer_ready(n), buffer_valid(n-1));	-- ready, valid
	end generate;
	
	outputBuffer : entity work.elasticBuffer(vanilla) generic map(DATA_SIZE)
			port map(	clk, reset, 
						data(1), data(0), 
						buffer_valid(1), n_ready, 			-- pValid, nReady
						buffer_ready(1), buffer_valid(0));	-- ready, valid
	
	
	-- map the delayed data and control output signals to the intermediate signals linking the buffers	
	process(data, data_in, clk, reset, p_valid, buffer_valid)
	begin
		data_out(0) <= data_in;
		valid(0) <= p_valid;
		for n in 1 to DELAY loop
			data_out(n) <= data(DELAY-n);
			valid(n) <= buffer_valid(DELAY-n);
		end loop;
	end process;
	
end vanilla;





-- to remove if all works well
architecture backup of delayChannel is
	type bitArray is array(integer range <>) of std_logic;
	--signals used to link the buffers together	
	signal data : vectorArray_t (DELAY-1 downto 0)(DATA_SIZE-1 downto 0);
	signal buffer_ready : bitArray_t(DELAY-1 downto 1); -- only between two buffers from the chain
	signal buffer_valid : bitArray_t(DELAY-1 downto 0); -- we need one more to map the valid signal of the last buffer
begin

	-- instantiate the chain of buffers
	inputBuffer : entity work.elasticBuffer(vanilla)  generic map(DATA_SIZE)
			port map(	clk, reset, 
						data_in, data(DELAY-1), 
						p_valid, buffer_ready(DELAY-1), 	-- pValid, nReady
						ready, buffer_valid(DELAY-1)); 		-- ready, valid
	
	genBuffers : for n in DELAY-1 downto 2 generate
		intermediateBuffer : entity work.elasticBuffer(vanilla)  generic map(DATA_SIZE)
				port map (	clk, reset, 
							data(n), data(n-1), 
							buffer_valid(n), buffer_ready(n-1), 	-- pValid, nReady
							buffer_ready(n), buffer_valid(n-1));	-- ready, valid
	end generate;
	
	outputBuffer : entity work.elasticBuffer(vanilla) generic map(DATA_SIZE)
			port map(	clk, reset, 
						data(1), data(0), 
						buffer_valid(1), n_ready, 			-- pValid, nReady
						buffer_ready(1), buffer_valid(0));	-- ready, valid
	
	
	-- map the delayed data and control output signals to the intermediate signals linking the buffers	
	process(data, data_in, clk, reset, p_valid)
	begin
		data_out(0) <= data_in;
		valid(0) <= p_valid;
		for n in 1 to DELAY loop
			data_out(n) <= data(DELAY-n);
			valid(n) <= buffer_valid(DELAY-n);
		end loop;
	end process;
	
end backup;
