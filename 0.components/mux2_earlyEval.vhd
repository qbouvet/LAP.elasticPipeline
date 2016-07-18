---------------------------------------------------------------  TODO
---------------------------------------------------------------------
-- todo in component below
-- add the latency parameter through the multiplexer interface
-- adapt the 'join' to have only one antitoken channel




------------------------------------------------------- earlyEvalMux2
---------------------------------------------------------------------
-- multiplexer with early evaluation and antitoken mechanism
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux2_earlyEval is
port(
	clk, reset : in std_logic;
	a, b : in std_logic_vector(31 downto 0);
	sel : in std_logic;
	n_ready, p_valid0, p_valid1 : in std_logic;
	d_in0 : in std_logic_vector(31 downto 0);
	d_in1 : in std_logic_vector(31 downto 0);
	d_out : out std_logic_vector(31 downto 0);
	readyOnChan0, readyOnChan1, valid : out std_logic);
end mux2_earlyEval;

architecture mux2_earlyEval1 is
	signal antiT0, antiT1, ready_internal, chan0_valid_internal, chan1_valid1_internal : std_logic;
begin
	
	d_out <= d_in0 when sel='0' else d_in1;
	
	entity join2_eem port map(clk, reset, sel, chan0_valid_internal, chan1_valid_internal, n_ready, antiT0, antiT1, valid, ready_internal);
	
	-- channel 1 : antitoken of latency 2 in our example
	entity antitokenChannel port map(clk, reset, antiT1, n_ready, "010", chan1_valid_internal1, readyOnChan1);
	-- channel 0 : no antitoken in our example
	readyOnChan0 <= ready;
	chan0_valid_internal <= p_valid_1;	
	
end mux2_earlyEval1;



----------------------------------------------------------  join2_eem
---------------------------------------------------------------------
-- joins the control signals of 2 elastic buffers into a single 
-- control signal
-- NB : it implements early evaluation and antitokens management
library ieee;
use ieee.std_logic_1164.all;

entity join2_eem is
port(
	clk, reset,
	sel, 
	p_valid1, p_valid0, n_ready : in std_logic;
	antiT1, antiT0, valid, ready : out std_logic);
end join2_eem;

architecture j2 of join2_eem is
begin

	valid <= p_valid1 when sel='1' else p_valid0;
	ready <= n_ready; -- the "ready when active antitoken" is done at the antitoken channel

	process(clk, reset,	p_valid1, p_valid0, sel, n_ready)
	begin
		-- reset previous antitokens signals and issue new antitoken if early evaluating
		if(rising_edge(clk))then
			antiT0 <='0';
			antiT2 <='0';
			if(n_ready)then
				if(p_valid0='1' and sel='0' and p_valid1='0')then
					antiT1 <= '1';
				elsif(p_valid1='1' and sel='1' and p_valid0='0')then
					antiT0<='1';
				end if;
			end if;
		end if;
	end process;
	
	-- async reset
	process(reset)
	begin
		if(reset='1')then
			valid <= '0';
			ready <= '0';
			antiT1 <= '0';
			antiT2 <= '0';
		end if;
	end process;

end j2_eem;



--------------------------------------------------   antiTokenChannel
---------------------------------------------------------------------
-- implements the anti-tokens functionality by discarding the p_valid 
-- signal on the channel
-- then countdown and multiple tokens is implemented as follows : 
-- 	1. each token is represented by a 1 in a shift register
--  2. $latency determines in which register new tokens are inserted
-- 	3. registers shift at each clock, discard data when '1' in last
-- NB : $latency should not be changed once the component is instanciated - it
-- 		only exists to implement channels of different latencies 
--
-- 				cf. paper for much easier understanding
library ieee;
use ieee.std_logic_1164.all;

entity antitokenChannel is
port( 	clk, reset,
		antiT,
		p_valid, n_ready : in std_logic;
		tokenLatency : in std_logic_vector(2 downto 0);
		valid, ready : out std_logic);
end antitoken_channel;

architecture atc of antitokenChannel is 
	signal tokenTimeOut : std_logic;
	signal enableShift : std_logic;
begin

	-- when do we enable shifting ?																-- TODO
	
	-- shift register that permits latency countdown and multiple tokens 
	entity antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiT, tokenLatency, tokenTimeout);
	
	-- stop shifting when timed out until we discarded one valid='1' signal
	process(clk, reset, tokenTimeOut)
	begin
		enableShift <= tokenTimedOut;
		if(rising_edge(p_valid))then
			enableShift <= '1';												-- timing issues ?? (pass it through a register of some kind ?)
		end if;
	end process;
	
	-- signals mapping (cf paper doc)
	valid <= '0' when tokenTimeOut else p_valid;	
	ready <= n_ready;

	-- asynchronous reset
	process(reset)
	begin
		if(reset='1')then
			--reset everything
		end if
	end process;
end atc;



--------------------------------------------------  ATC_shiftRegister
---------------------------------------------------------------------
-- a shift register composed of the register units described below
-- contains 8 registers -> up to a latency 7 antitoken
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity antitokenChannel_shiftRegister is
port(	clk, reset,
		enableShift,
		antiToken : in std_logic;
		tokenLatency : in std_logic_vector(2 downto 0);
		timeout : out std_logic);
end antitokenChannel_shiftRegister;

architecture antitokenChannel_shiftRegister1 of antitokenChannel_shiftRegister is
	signal tokenInsertionSpot : std_logic_vector(7 downto 0); 
	-- we could possible add one more register with the same size for tokenLatency
	-- since having a 'latency 0' antitoken channel is useless (and mokes no sense)
	--																					-- or does it ???
	signal d_in_internal : std_logic_vector(6 downto 0);
	signal clockSubstitute : std_logic;
begin

	--will shift only when allowed to
	clockSubstitute <= clock and enableShift

	--sets the tokenInsertionSpot vector
	process(clk, reset, tokenLatency)
	begin
		tokenInsertionSpot <= (others => '0');
		tokenInsertionSpot(unsigned(tokenLatency)) <= '1';
	end process;

	-- 8 registers instanciation
	entity work.antitokenChannel_reg port map(clockSubstitute, reset, antiToken, tokenInsertionSpot(0), d_in_internal(0), timeout);
	for i in 1 to 6 loop
		entity work.antitokenChannel_reg port map(clockSubstitute, reset, antiToken, tokenInsertionSpot(i), d_in_internal(i+1), d_in_internal(i));
	end loop;
	entity work.antitokenChannel_reg port map(clockSubstitute, reset, antiToken, tokenInsertionSpot(7), '0', d_in_internal(7);
	
	-- async reset done by port mapping the reset signal
	
end antitokenChannel_shiftRegister1;



------------------------------------------------------------  ATC_reg
---------------------------------------------------------------------
-- a single single flip-flop for the shift register we'll use 
-- in the antitoken channel
library ieee;
use ieee.std_logic_1164.all;

entity antitokenChannel_reg is 
port(	clk, reset,
		antitoken,
		isInsertionSpot,
		d_in : in std_logic;
		d_ou : out std_logic);
end antitoken_reg;

architecture antitokenChannel_reg1 of antitokenChannel_reg is
	heldVal : std_logic;
	clockSubstitute : std_logic;
	d_in_internal : std_logic;
begin

	-- internal "enable" and "data to write" change wether the register
	-- is at the spot matching the latency of the antitoken or not
	d_in_internal <= d_in when isInsertionSpot='0' else '1';
		-- the trick here is : we receive AT at/shortly after clk edge
		-- at this time, clk should be up
		-- this 'and' permits to bring the signal down with the clock, 
		-- so that at the new clock cycle, we can get a new rising edge 
		-- to 'write enable' the register with (cf paper schematics)
	clockSubstitute <= clk and antitoken when isInsertionSpot='1' else clk;
	
	process(clk, reset, antitoken, isInsertionSpot, d_in)
	begin
		if(rising_edge(clockSubstitute))then
			heldVal <= d_in_internal;
		end if;
	end process;

	-- async reset
	process(reset)
	begin
		if(reset='1')then
			heldVal <= '0';
		end if;
	end process;

end antitokenChannel_reg1;
