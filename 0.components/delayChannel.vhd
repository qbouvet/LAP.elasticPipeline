-------------------------------------------------------  delayChannel
---------------------------------------------------------------------
-- Basically a generic bunch of elastic buffers chained together.
-- will delay the input data by the generic DELAY given, and 
-- also outputs each piece of data in the buffers in the 
-- data_out array of std_logic_vectors to be able to bypass 
-- unnecessary buffers.
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
		data_out : out vectorArray_t(0 to DELAY)(DATA_SIZE-1 DOWNTO 0);
		--elastic control signals
		p_valid, n_ready : in std_logic;
		ready, valid : out std_logic
); 
end delayChannel;

architecture generique of delayChannel is
	type bitArray is array(integer range <>) of std_logic;
	--signals used to link the buffers together	
	signal data : vectorArray_t (DELAY-1 downto 0)(DATA_SIZE-1 downto 0);
	signal buffer_ready : bitArray(DELAY-1 downto 1);
	signal buffer_valid : bitArray(DELAY-1 downto 1);
begin

	-- instantiate the chain of buffers
	inputBuffer : entity work.elasticBuffer_reg generic map(DATA_SIZE)
			port map(clk, reset, data_in, data(DELAY-1), p_valid, buffer_ready(DELAY-1), ready, buffer_valid(DELAY-1));
	
	genBuffers : for n in DELAY-1 downto 1 generate
		intermediateBuffer : entity work.elasticBuffer_reg generic map(DATA_SIZE)
				port map (clk, reset, data(n), data(n-1), buffer_valid(n), buffer_ready(n-1), buffer_ready(n), buffer_valid(n-1));
	end generate;
	
	outputBuffer : entity work.elasticBuffer_reg generic map(DATA_SIZE)
			port map(clk, reset, data(1), data(0), buffer_valid(1), n_ready, buffer_ready(1), valid);
	
	
	-- map the delayed output signals to the intermediate signals linking the buffers	
	process(data)
	begin
		data_out(0) <= data_in;
		for n in 1 to DELAY loop
			data_out(n) <= data(DELAY-n);
		end loop;
	end process;
	
end generique;
