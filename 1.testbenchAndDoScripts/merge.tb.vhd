library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.customTypes.all;

entity tb_merge is 
end tb_merge;

architecture testbench of tb_merge is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;	
	
	signal data0, data1, dataOut : std_logic_vector(31 downto 0);
	signal pValidArray, readyArray : bitArray_t(1 downto 0);
	signal nReady, valid : std_logic;
	
begin
	
	-- run simulation
	sim : process
		--simulation reset
		procedure resetSim is
		begin
				reset <= '1';
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
		--waiting procedures		
		procedure waitPeriod is
		begin	wait for CLK_PERIOD;
		end procedure;		
		procedure waitPeriod(constant i : in real) is
		begin	wait for i * CLK_PERIOD;
		end procedure;		
		procedure waitPeriod(constant i : in integer) is
		begin 	wait for i * CLK_PERIOD;
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
																		-- todo
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.merge 
			port map( 	data0, data1, dataOut,
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
