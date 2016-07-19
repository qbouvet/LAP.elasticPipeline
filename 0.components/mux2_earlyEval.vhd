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
	d_in0, d_in1 : in std_logic_vector(31 downto 0);
	d_out : out std_logic_vector(31 downto 0);
	readyOnChan0, readyOnChan1, valid : out std_logic);
end mux2_earlyEval;

architecture mux2_earlyEval1 of mux2_earlyEval is
	signal antiT0, antiT1, ready_internal, chan0_valid_internal, chan1_valid_internal : std_logic;
begin
	
	d_out <= d_in0 when sel='0' else d_in1;
	
	comp0 : entity work.join2_eem(j2) port map(clk, reset, sel, chan0_valid_internal, chan1_valid_internal, n_ready, antiT0, antiT1, valid, ready_internal);
	
	-- channel 1 : antitoken of latency 2 in our example
	comp1 : entity work.antitokenChannel(atc) port map(clk, reset, antiT1, chan1_valid_internal, n_ready, "010", chan1_valid_internal, readyOnChan1);
	-- channel 0 : no antitoken in our example
	readyOnChan0 <= n_ready;
	chan0_valid_internal <= p_valid1;	
	
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

	antitokensGeneration : process(clk, reset,	p_valid1, p_valid0, sel, n_ready)
	begin
		-- reset previous antitokens signals and issue new antitoken if early evaluating
		if(rising_edge(clk))then
			antiT0 <='0';
			antiT1 <='0';
			if(n_ready='1')then
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
			antiT0 <= '0';
			antiT1 <= '0';
		end if;
	end process;

end j2;



--------------------------------------------------   antiTokenChannel
---------------------------------------------------------------------
-- implements the anti-tokens functionality by discarding the p_valid 
-- signal on the channel
-- then countdown and multiple tokens is implemented as follows : 
-- 	1. each token is represented by a 1 in a shift register
--  2. $latency determines in which register new tokens are inserted
-- 	3. registers shift at each clock, discard data when '1' in last
-- NB : $latency should not be changed once the component is instanciated 
--		it only exists to implement channels with different latencies 
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
end antitokenChannel;

architecture atc of antitokenChannel is 
	signal tokenTimeOut : std_logic;
	signal enableShift : std_logic;
begin

	-- shifting en/disabled by masking (and) the clock with the shiftEnable signal
	
	-- shift register that permits latency countdown and multiple tokens 
	shiftReg : entity work.antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiT, tokenLatency, tokenTimeout);
	
	-- stop shifting when timed out until we discarded one valid='1' signal
	controlShifting : process(clk, reset, tokenTimeOut)
	begin
		enableShift <= not tokenTimeOut;
		if(rising_edge(clk))then
			if(p_valid='1')then
				enableShift <= '1';												-- timing issues ?? (pass it through a register of some kind ?)
			end if;
		end if;
	end process;
	
	-- signals mapping (cf paper doc)
	valid <= '0' when tokenTimeOut='1' else p_valid;	
	ready <= n_ready;

	-- asynchronous reset - via signal mapping to shift register
end atc;



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
		wrenable,
		d_in : in std_logic;
		d_ou : out std_logic);
end antitokenChannel_reg;

architecture antitokenChannel_reg1 of antitokenChannel_reg is
	signal heldVal : std_logic;
	signal d_in_internal : std_logic;
begin

	-- if we're at the spot matching for $latency, we use the antitoken 
	-- as input signal. Else, we will use the previous reg's output
	d_in_internal <= d_in when isInsertionSpot='0' else antitoken;	
		
	holdValue : process(clk, reset, antitoken, isInsertionSpot, d_in)
	begin
		if(rising_edge(clk))then
			if(wrenable='1') then
				heldVal <= d_in_internal;
			end if;
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



--------------------------------------------------  ATC_shiftRegister
---------------------------------------------------------------------
-- a shift register composed of the register units described below
-- contains 8 registers -> up to a latency 7 antitoken
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

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
	signal d_in_internal : std_logic_vector(6 downto 0);
begin

	--sets the tokenInsertionSpot vector
	insertionSpotVector : process(clk, reset, tokenLatency)
	begin
		tokenInsertionSpot <= (others => '0');
		tokenInsertionSpot(conv_integer(tokenLatency)) <= '1';
	end process;

	-- 8 registers instanciation
	
	lastReg : entity work.antitokenChannel_reg port map(clk, reset, antiToken, enableShift, tokenInsertionSpot(0), d_in_internal(0), timeout);
	genShiftRegister : for i in 1 to 6 generate
		internalReg : entity work.antitokenChannel_reg port map(clk, reset, antiToken, enableShift, tokenInsertionSpot(i), d_in_internal(i), d_in_internal(i-1));
	end generate genShiftRegister;
	firstReg : entity work.antitokenChannel_reg port map(clk, reset, antiToken, enableShift, tokenInsertionSpot(7), '0', d_in_internal(6));
	
	-- async reset done by port mapping the reset signal
	
end antitokenChannel_shiftRegister1;
