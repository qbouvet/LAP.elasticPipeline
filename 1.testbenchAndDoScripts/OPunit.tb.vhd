library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.customTypes.all;

entity TB_OPunit is 
end TB_OPunit;

architecture testbench of TB_OPunit is

	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic;
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 10 ns;

	--data
	signal argA, argB, argI, oc, res : std_logic_vector(31 downto 0);
	--control signals
	signal pValidArray, readyArray : bitArray_t(3 downto 0);
	signal valid, nReady : std_logic;	
	
begin
	
	sim : process
		procedure resetSim is
		begin
			reset <= '1';
			oc <= (others => '0');
			argI <= (others => '0');
			argA <= (others => '0');
			argB <= (others => '0');
			pValidArray <= (others => '0');
			nReady <= '0';
			wait until rising_edge(CLK);
			wait for CLK_PERIOD / 4;
			reset <= '0';
		end procedure;			
		--waiting procedures
		procedure waitPeriod(constant i : in real) is
		begin	wait for i * CLK_PERIOD;
		end procedure;		
		procedure waitPeriod(constant i : in integer) is
		begin	wait for i * CLK_PERIOD;
		end procedure;	
		--text output procedures
		variable console_out : line;
		procedure newline is
		begin	console_out := new string'("");
				writeline(output, console_out);
		end procedure newline;
		procedure print(msg : in string) is
		begin	console_out := new string'(msg);
				writeline(output, console_out);
		end procedure print;
		-- finished procedures
	begin
	
		resetSim;
		if(not finished)then
		
			newline;print("simulation started");
			newline;print(" basic tests");
			-- addi test
			oc <= X"00000" & "000000100000"; -- op0-addi		
			argA <= X"00000001";
			argI <= X"00000002";
			nReady <= '1';
			pValidArray <= (others => '1');
			waitPeriod(1);
			assert res=X"00000003" report "addi fails" severity error;
			
			waitPeriod(0.5);
			resetSim;
			
			--op1 test
			oc <= X"00000" & "000001000000"; -- op1
			argB <= X"00000001";
			argA <= X"00000002";
			nReady <= '1';
			pValidArray <= (others => '1');
			waitPeriod(1);
			assert res=X"00000006" report "op1 fails" severity error;
						
			waitPeriod(0.5);
			resetSim;
			
			newLine; print("control signals tests");
			oc <= X"00000" & "000000100000"; -- op0-addi		
			argA <= X"00000001";
			argI <= X"00000002";
			nReady <= '1';
			pValidArray <= "1110";
			waitPeriod(1);
			assert valid='0' report "must stay invalid until all data is available" severity error;
			assert readyArray="0001" report "ready signals array must switch to 0 on ready buffers when not all data is available, so that they keep the informations" severity error;
			pValidArray <= "1101";
			waitPeriod(1);
			assert valid='0' report "must stay invalid until all data is available (2)" severity error;
			assert readyArray="0010" report "ready signals array must switch to 0 on ready buffers when not all data is available, so that they keep the informations (2)" severity error;
			pValidArray <= "1011";
			waitPeriod(1);
			assert valid='0' report "must stay invalid until all data is available (3)" severity error;
			assert readyArray="0100" report "ready signals array must switch to 0 on ready buffers when not all data is available, so that they keep the informations (3)" severity error;
			pValidArray <= "0111";
			waitPeriod(1);
			assert valid='0' report "must stay invalid until all data is available (4)" severity error;
			assert readyArray="1000" report "ready signals array must switch to 0 on ready buffers when not all data is available, so that they keep the informations (4)" severity error;
			pValidArray <= "0000";
			waitPeriod(1);
			assert valid='0' report "must stay invalid until all data is available (5)" severity error;
			assert readyArray="1111" report "ready signals array must switch to 0 on ready buffers when not all data is available, so that they keep the informations (5)" severity error;
			pValidArray <= "1111";			
			nReady <= '0';
			waitPeriod(1);
			assert valid='0' report "must stay invalid until all data is available (6)" severity error;
			assert readyArray="0000" report "ready signals array must switch to 0 when the next component isn't ready" severity error;
			nReady <= '1';
			waitPeriod(0.5);
			assert valid = '1' report "should be valid now" severity error;
			assert readyArray = "1111" report "should accept data now" severity error;
			wait until rising_edge(CLK);
			pValidArray <= "0000";
			waitPeriod(0.25);
			assert valid='0' report "no more data, can't be valid" severity error;
			assert readyArray = "1111" report "next component still ready, no data incommind, should be ready" severity error;
			
			
			waitPeriod(1);
			newline;print("simluation finished");
			finished <= true;
		end if;		
		
	end process sim;

	-- DUT instance
	opu : entity work.OPunit port map(	clk, reset, 
										argB, argA, argI, oc, 
										res, 
										pValidArray,
										nReady,
										valid, 
										readyArray);
	
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
	
	
	
	
	
	
	
	
	
	
	
	
	
	
