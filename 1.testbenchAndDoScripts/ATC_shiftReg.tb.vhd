-- NB for next time :
-- "wait until currenttime=230 ns;wait until rising_edge(clk);" 
-- fucks everything up when used several consecutive times
-- use "wait for CLK_PERIOD" or "wait until rising_edge(clk) 
-- after the first call to above expression

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_atc_shiftReg is 
end tb_atc_shiftReg;


-- the weird signals assignment here are done to avoid sequential assignments 
-- that do not work well with setting signals at clock edge
architecture testbench of tb_atc_shiftReg is
	
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic;
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 10 ns;
	
	signal enableShift, antitoken, timeout : std_logic;	
	signal tokenLatency : std_logic_vector(2 downto 0);
	
begin

	--assign signals
	setSignals : process
		procedure resetSim is
		begin -- no longer used
			reset <= '1';
			enableShift <= '0';
			antitoken <= '0';
			tokenLatency <= "000";
			wait until rising_edge(clk);
			wait for(3 * CLK_PERIOD / 4);
			reset<='0';
		end procedure resetSim;
		--text processing
		variable console_out : line;
		procedure newline is
		begin
			console_out := new string'("");
			writeline(output, console_out);
		end procedure newline;
		procedure print(msg : in string) is
		begin
			console_out := new string'(msg);
			writeline(output, console_out);
		end procedure print;
	begin
		--resetSim; --no longer used
		wait until rising_edge(clk);
		if(not finished)then
						
			--set the inputs for the whole simulation
			reset <= '1', '0' after 7.5 ns, '1' after 60 ns, '0' after 67.5 ns, '1' after 140 ns, '0' after 147.5 ns, '1' after 210 ns, '0' after 217.5 ns;
			tokenLatency <= "010", "100" after 210 ns;
			antitoken <= '0', '1' after 20 ns, '0' after 30 ns, '1' after 70 ns, '0' after 110 ns, '1' after 150 ns, '0' after 160 ns, '1' after 220 ns, '0' after 240 ns, '1' after 260 ns, '0' after 280 ns;
			
			enableShift <= '1'; --changes here happen right after the clock edge, this signal will be set using the usual syntax through the sim
			--enableShift <= '1', '1' after 150 ns, '0' after 160 ns, '1' after 170 ns, '0' after 271 ns, '1' after 290 ns ;
			
			-- single token
			newline;print("latency of 2 *clock+enable* cycles");
			newline;Print("antitoken 1 at 20 ns, single antitoken should timeout at 40ns");
			wait until currenttime = 40 ns; wait until rising_edge(clk);							-- need to wait until _after_ the rising edge
			assert timeout='1' report "antitoken 1 didn't timeout" severity error;
			wait for CLK_PERIOD;
			assert timeout='0' report "timeout didn't return to 0" severity error;
			
			--forget to reset simulation here, nevermind
			
			-- continuous arrival of 4 antitokens
			newline;print("four antitokens following each other starting at 60 ns - numbered 2 to 5 - should timeout between 90 and 130 ns");
			wait until currenttime = 90 ns; wait until rising_edge(clk);
			assert timeout='1' report "antitoken 2 didn't timeout" severity error;
			--wait until currenttime = 100 ns; wait until rising_edge(clk);				-- prevent next asserts from happeneing ? restriction in the number of asserts ?
			wait for CLK_PERIOD;
			assert timeout='1' report "antitoken 3 didn't timeout" severity error;
			--wait until currenttime = 110 ns; wait until rising_edge(clk);
			wait for CLK_PERIOD;
			assert timeout='1' report "antitoken 4 didn't timeout" severity error;
			--wait until currenttime = 120 ns; wait until rising_edge(clk);
			wait for CLK_PERIOD;
			assert timeout='1' report "antitoken 5 didn't timeout" severity error;
			wait for CLK_PERIOD;
			assert timeout='0' report "timeout didn't return to 0" severity error;
			
			-- check behaviour of enable signal
			wait until currenttime = 140 ns;
			newline;print("enable signal correctly stops the antitoken countdown");
			print("antitoken 6 - inserted at 150 ns - should timeout at 180 ns - register not enabled during one cycle");
			wait until currenttime=150 ns; wait until rising_edge(clk);
			enableShift <= '0';
			--wait until currenttime=160 ns; wait until rising_edge(clk);
			--wait for CLK_PERIOD;
			wait until rising_edge(clk);
			enableShift <= '1';
			--wait until currenttime=180 ns; wait until rising_edge(clk);
			wait until rising_edge(clk);
			wait until rising_edge(clk); --180 ns
			assert timeout='1' report "antitoken 6 didn't timeout" severity error;
			wait until rising_edge(clk);
			assert timeout='0' report "timeout didn't return to 0" severity error;
			
			--check behaviour of timeout signal (2) with increased latency and several consecutive antitokens
			--wait until currenttime=220 ns;
			newline;print("several consecutive antitokens + enable signal test (with latency 4)");
			print("insert 4 from 220 ns to 260 ns with not enabledShift during 2 cycles - expected timeout from 280 to 320");
			wait until currenttime=225 ns;wait until rising_edge(clk);	-- 230 ns
			enableShift <= '0';
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			enableShift <= '1';
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			wait until rising_edge(clk);
			assert timeout = '1' report "antitokens didn't timeout" severity error;
			wait for CLK_PERIOD * 4;
			assert timeout = '0' report "timeout didn't return to 0" severity error;
			
			newline;newline;
			assert false report "simulation finished" severity note;
			wait until finished=true;
		end if;
	end process;
		
	
	--run and stop simulation
	sim : process
	begin
		wait until reset='0';
		wait until rising_edge(clk);
		wait for CLK_PERIOD * 33;
		finished <= true;
	end process;
	
	--instantiate design under test
	--DUT : entity work.antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiToken, tokenLatency, timeout);			--debug
	DUT : entity work.antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiToken, tokenLatency, open,  timeout);
	
	-- ticks the clock
	clock : process
    begin
        if (finished) then
            wait;
        else
            clk <= not clk;
            wait for CLK_PERIOD / 2;
            currenttime <= currenttime + CLK_PERIOD / 2;
        end if;
    end process clock;
    
    
end testbench;














-- simplified version avoiding the "x <= a, b after [time]" assignments
-- for debugging
architecture simplified of tb_atc_shiftReg is

	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic;
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 10 ns;
	
	signal enableShift, antitoken, timeout : std_logic;	
	signal tokenLatency : std_logic_vector(2 downto 0);
	signal vect : std_logic_vector(7 downto 0);
	
begin

	sim : process 
	
		procedure reset_sim is
		begin
			reset <= '1';
			enableShift <= '0';
			antitoken <= '0';
			tokenLatency <= "000";
			wait until rising_edge(clk);
			wait for(3 * CLK_PERIOD / 4);
			reset<='0';
		end procedure reset_sim;
		
	begin
		
		reset_sim;
		wait for CLK_PERIOD;
		antitoken <= '1';
		enableShift <= '1';
		tokenLatency <= "011";
		
		wait for CLK_PERIOD * 10;
		
		finished <= true;		
		
	end process sim;

	--instantiate design under test
	--DUT : entity work.antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiToken, tokenLatency, timeout);				--debug
	DUT : entity work.antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiToken, tokenLatency, vect, timeout);
	
	-- ticks the clock
	clock : process
    begin
        if (finished) then
            wait;
        else
            clk <= not clk;
            wait for CLK_PERIOD / 2;
            currenttime <= currenttime + CLK_PERIOD / 2;
        end if;
    end process clock;
    
end simplified;



