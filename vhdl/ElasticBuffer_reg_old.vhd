library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ElasticBuffer_reg is
port(
	clk : in std_logic;
	reset : in std_logic;
	
	d_in : in std_logic_vector(31 downto 0);
	d_out : out std_logic_vector(31 downto 0);
	
	p_valid, n_ready : in std_logic;
	ready, valid : out std_logic);
end ElasticBuffer_reg;

-- implementation (b) (2 flip flop connected sequentially with a multiplexer in between)
architecture EB_seq_reg of ElasticBuffer_reg is
	
	component EB_controller
		port (
				reset,clk : in std_logic;
				n_ready, p_valid : in std_logic;
				ready, valid: out std_logic;
				aux_wren, main_wren, mux_sel : out std_logic);
	end component;
	signal aux_wren : std_logic;
	signal main_wren : std_logic;
	signal mux_sel : std_logic; --selects the auxiliary register at '1', the data input at '0'	
	signal mainRegData : std_logic_vector(31 downto 0);
	signal auxRegData : std_logic_vector(31 downto 0);
	
begin

	controller : EB_controller port map (
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
	
end;



--------------------------------------------------------------------------
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


architecture sync of EB_controller is

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

			if(p_valid='1') then
				nextState <= HALF;
				aux_wren <= '0';
				main_wren <= '1';
				mux_sel <= '0';
			else
				nextState <= EMPTY;
				aux_wren <= '0';
				main_wren <= '0';
				mux_sel <= '0';
			end if;
			
		elsif (currentState=HALF) then
			valid <= '1';
			ready <= '1';
			if((p_valid='1' and n_ready ='1') or (p_valid='0' and n_ready='0')) then
				nextState <= HALF;
				aux_wren <= '0';
				main_wren <= '1';
				mux_sel <= '0';
			elsif(p_valid='1') then --n_ready = false
				nextState <= FULL;
				aux_wren <= '1';
				main_wren <= '0';
				mux_sel <= '0';
			else --p_valid = '0' - on écrit rien à la prochaine edge
				nextState <= EMPTY;
				aux_wren <= '0';
				main_wren <= '0';
				mux_sel <= '0';
			end if;
			
		else --currentState = FULL
			valid <= '1';
			ready <= n_ready; --we can accept a new value only if the next buffer will clear one of ours
			if(n_ready='0') then
				nextState <= FULL;
				aux_wren <= '0';
				main_wren <= '0';
				mux_sel <= '0';
			elsif(p_valid='1') then --(n_ready='1') 
				nextState <= FULL;	
				aux_wren <= '1';		-- we shift the 3 values
				main_wren <= '1';
				mux_sel <= '1'; 		-- shift
			elsif(p_valid='0') then --(n_ready='1')
				nextState <= HALF;
				aux_wren <= '0';
				main_wren <= '1';
				mux_sel <= '1';
			end if;
		
		end if;
	end process;
end sync;