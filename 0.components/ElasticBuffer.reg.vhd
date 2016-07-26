-----------------------------------------------------  elasticBuffer
---------------------------------------------------------------------
-- the "2register-1multiplexer" implementation from cortadella's 
-- papers
---------------------------------------------------------------------




------------------------------------------------------------------------
-- controller for the elastic buffer
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EB_controller is
port(
	reset : in std_logic;
	clk : in std_logic;

	n_ready : in std_logic;
	p_valid : in std_logic;
	ready : out std_logic;
	valid : out std_logic;
	
	aux_wren : out std_logic;
	main_wren : out std_logic;
	mux_sel : out std_logic	);
end EB_controller;


architecture EB_controller1 of EB_controller is

	type state_t is (EMPTY, HALF, FULL);
	signal currentState, nextState : state_t;
	
begin
	
	-- rotate states
	process(clk, reset)
	begin
	if(reset='1')then
		currentState <= EMPTY;
	else
		if(rising_edge(clk)) then
			currentState <= nextState;
		end if;
	end if;
	end process;
	
	-- states transitions
	process(currentState, n_ready, p_valid)
	begin
		if(currentState=EMPTY) then
			valid <= '0';
			ready <= '1';
			
			-- main_wren <= p_valid;
			main_wren <= '1';
			aux_wren <= '0';
			mux_sel <= '0';
			
			if(p_valid='1') then
				nextState <= HALF;
			else
				nextState <= EMPTY;
			end if;
			
		elsif (currentState=HALF) then
			valid <= '1';
			ready <= '1';
			
			main_wren <= p_valid and n_ready;
			aux_wren <= not n_ready;
			mux_sel <= '0';
			
			if((p_valid xor n_ready)='0') then
				nextState <= HALF;
			elsif(p_valid='1') then -- not n_ready -> on stocke
				nextState <= FULL;
			else -- not p_valid and next_ready -> on vide
				nextState <= EMPTY;
			end if;
			
		else -- FULL
			valid <= '1';
			ready <= n_ready; -- if next buffer wil accept a value, we can "shift ours" and accept a new one
			
			main_wren <= p_valid and n_ready;
			aux_wren <= p_valid and n_ready;
			mux_sel <= p_valid and n_ready;
				
			if(n_ready='0' or p_valid ='1') then
				nextState <= FULL; -- either we stall, or we shift
			else -- n_ready and not p_valid : main -> output, aux -> main
				nextState <= HALF;
			end if;
		
		end if;
	end process;
end EB_controller1;





------------------------------------------------------------------------ 
-- elastic buffer itself
------------------------------------------------------------------------ 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity elasticBuffer_reg is
GENERIC(
	VECT_SIZE : integer);
port(
	clk, reset : in std_logic;
	
	d_in : in std_logic_vector(VECT_SIZE-1 downto 0);
	d_out : out std_logic_vector(VECT_SIZE-1 downto 0);
	
	p_valid, n_ready : in std_logic;
	ready, valid : out std_logic);
end elasticBuffer_reg;

architecture elasticBuffer_reg1 of elasticBuffer_reg is
	
	signal aux_wren : std_logic;
	signal main_wren : std_logic;
	signal mux_sel : std_logic; --selects the auxiliary register at '1', the data input at '0'	
	signal mainRegData : std_logic_vector(VECT_SIZE-1 downto 0);
	signal auxRegData : std_logic_vector(VECT_SIZE-1 downto 0);
	
begin

	controller : entity work.EB_controller(EB_controller1) port map (
		reset, clk, n_ready, p_valid, ready, valid, aux_wren, main_wren, mux_sel
	);
	
	-- auxiliairy register
	process(aux_wren, clk, d_in, main_wren)
	begin
		if(reset='1')then
			auxRegData <= (others => '0');
		else 
			if(rising_edge(clk)) then
				if(aux_wren='1') then
					auxRegData <= d_in;
				end if;
			end if;
		end if;
	end process;
	
	-- main register + multiplexer
	process(main_wren, clk, d_in)
	begin
		if(reset='1')then
			mainRegData <= (others => '0');
		else 
			if(rising_edge(clk)) then
				if(main_wren='1') then
					if(mux_sel = '1') then
						mainRegData <= auxRegData;
					else 
						mainRegData <= d_in;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	d_out <= mainRegData;
	
end elasticBuffer_reg1;
