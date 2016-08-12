library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use work.testbenchCommons.all; 	-- contains clock/reset, procedures, ect...

entity test is 
end test;

architecture testbench of test is
	signal testsignal : vectorArray_t(3 downto 0)(31 downto 0);
begin
	
	-- run simulation
	sim : process
				--simulation reset
		procedure resetSim is
		begin
				reset <= '1';
				testsignal <= (others => (others => '0'));
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
	begin
	resetSim;
	if(not finished)then 
			
		newline;print("simulation started");
		
		
		
		
		newline;print("simulation completed");
	end if;
	finished <= true;
	end process;
	
	
	-- ticks the clock
	clock : process
    begin
		if (finished) then	wait;
        else	clk <= not clk;
				wait for CLK_PERIOD / 2;
				currenttime <= currenttime + CLK_PERIOD / 2;
        end if;
    end process clock ;
      
end testbench;
