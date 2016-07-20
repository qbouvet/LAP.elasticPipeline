-- A testbench for the antitokenChannel
--
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity tb_antitokenChannel is 
end tb_antitokenChannel;

architecture testbench of tb_antitokenChannel is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;	
	
	signal latency : std_logic_vector(2 downto 0) := "011"; --in
	signal antitoken, p_valid, n_ready : std_logic := '0'; --in
	signal ready, valid : std_logic; --out
	
begin
	
	-- run simulation
	sim : process
		procedure resetSim is
		begin
			reset <= '1';
			wait until rising_edge(clk);
			wait for(3 * CLK_PERIOD / 4);
			reset<='0';
		end procedure resetSim;
			--waiting procedures
		procedure waitPeriod(constant i : in integer) is
		begin
			for n in 1 to i loop
				wait for CLK_PERIOD;
			end loop;
		end procedure;		
		procedure waitForRising(signal sig : in std_logic; constant i : in integer) is
		begin
			for n in 1 to i loop
				wait until rising_edge(sig);
			end loop;
		end procedure;
			-- text output procedures
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
		
		-- init simulation
		resetSim ; --ends at 3/4 of a period
		
		if(finished=false)then
			
			--simple token with constant enable
			newline;print("simple 1-antitoken test with constant p_valid/n_ready - latency = 3 cycles");
			antitoken <= '1';
			p_valid <= '1';
			n_ready <= '1';
			waitPeriod(1); -- only one antitoken in the buffer
			antitoken <= '0';
			waitPeriod(2);	--at this point, we discard data
			assert valid = '0' report "'valid' signal should be low" severity error;
			waitPeriod(1);
			wait for CLK_PERIOD;
			assert valid = '1' report "'valid' signal should be back up" severity error;
			
			--several tokens with interrupted p_valid/n_read signals
			newline;print("several tokens with interrupted p_valid/n_read signals - latency = 5 cycles");
			resetSim;
			latency <= "101";
			antitoken <= '1';
			p_valid <= '1';
			n_ready <= '1'; 
			waitPeriod(3); --let's load 3 consecutive tokens, then test if the cycle count stops correctly accroding to p_valid and n_ready
			antitoken <= '0';
			n_ready <= '0';
			waitPeriod(5); -- should be stopped
			assert ready = '0' report "the channel should wait on the next buffer's ready signal" severity error;
			assert valid = '1' report "p_valid is still high, so valid must be too" severity error;
			p_valid <= '0';
			n_ready <= '1';
			waitPeriod(5); -- should still be stopped
			assert ready = '1' report "the buffer following the channel is ready, channel should report ready" severity error;
			assert valid = '0' report "no valid data incomming, shoud be not ready" severity error;
			p_valid <= '1';
			waitPeriod(2); -- now should have completed shifting, the first antitoken should have reached the last buffer
			assert ready='1' report "timeout reached, channel should accept any data to discard it asap" severity error;
			assert valid='0' report "timeout reached, until enough data discarded, channel should not send valid data" severity error;
			waitPeriod(2); -- discard data 2 times and let 3 out of 3 antitokens out
			p_valid <= '0';
			waitPeriod(2); -- stopping incomming valid data should stop the shifting
			assert ready='1' report "still in timeout, channel should accept any data to discard it asap" severity error;
			assert valid='0' report "still in timeout, until enough data discarded, channel should not send valid data" severity error;
			p_valid <= '1';
			waitPeriod(1); --let the last antiToken out
			assert ready=n_ready report "should be back to normal" severity error;
			assert valid=p_valid report "should be back to normal" severity error;
			n_ready <='0';
			p_valid <= '0';
			waitPeriod(1); --let's quickly test ready/valid signals for correct behaviour without antitokens
			assert ready=n_ready report "should be back to normal (2)" severity error;
			assert valid=p_valid report "should be back to normal (2)" severity error;
			waitPeriod(3);
			
			--continuous flow of antitokens block the channel
			newline;print("continuous flow of antitokens blocks the channel's valid='0' and ready='1' - latency 3");
			resetSim;
			latency <= "011";
			antitoken <= '1'; 
			p_valid <= '1';
			n_ready <= '1';
			-- should wait before asserting signals assigned just before
			--assert ready = '1' report "not blocked yet, n_ready should pass through" severity error;
			--assert valid = '1' report "not blocked yet, n_ready should pass through" severity error;
			waitPeriod(1);
			assert ready = '1' report "not blocked yet, n_ready should pass through" severity error;
			assert valid = '1' report "not blocked yet, n_ready should pass through" severity error;
			waitPeriod(1);
			assert ready = '1' report "not blocked yet, n_ready should pass through" severity error;
			assert valid = '1' report "not blocked yet, n_ready should pass through" severity error;
			waitPeriod(1); --AT shifted to last register
			assert ready ='1' report "should block" severity error;
			assert valid='0' report "should block" severity error;
			n_ready<='0';
			p_valid<= '1';
			assert ready ='1' report "should block" severity error;
			assert valid='0' report "should block" severity error;
			waitPeriod(1); --AT shifted to last register
			assert ready ='1' report "should block" severity error;
			assert valid='0' report "should block" severity error;
			
			
			waitPeriod(3);		
			newline; newline;
			assert false report "finished simulation" severity note;
			
		end if;
		finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.antitokenChannel 
		port map( clk, reset, antitoken, p_valid, n_ready, latency, valid, ready);
			--port( clk, reset,
			--		antiT,
			--		p_valid, n_ready : in std_logic;
			--		wantedLatency : in std_logic_vector(2 downto 0);
			--		valid, ready : out std_logic);
	
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
