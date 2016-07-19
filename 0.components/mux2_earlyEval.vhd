---------------------------------------------------------------  TODO
---------------------------------------------------------------------
-- add the latency parameter through the multiplexer interface _ 
-- adapt the 'join' to have only one antitoken channel







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
