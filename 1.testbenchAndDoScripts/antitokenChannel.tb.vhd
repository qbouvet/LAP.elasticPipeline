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
			newline;print("simple 1-antitoken test with constant enable")
			wait for CLK_PERIOD;
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
			
			
			assert false report "finished simulation" severity note;
			
		end if;
		waitPeriod(10);
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
