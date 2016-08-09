-----------------------------------------------------------  tb_joinN
---------------------------------------------------------------------
-- tests the size-generic version of join
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;
use work.testbenchCommons.all; 	-- contains clock/reset, procedures, ect...

entity tb_joinN is 
end tb_joinN;


---------------------------------------------------------------------
-- size = 2
---------------------------------------------------------------------
architecture testbench2 of tb_joinN is
	signal pValidArray : bitArray_t(1 downto 0);
	signal 	nReady,
			valid :  std_logic;
	signal readyArray : bitArray_t(1 downto 0);	
begin
	
	-- run simulation
	sim : process
				--simulation reset
		procedure resetSim is
		begin
				reset <= '1';
				pValidArray <= (others => '0');	
				nReady <= '0';
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
	begin
	resetSim;
	if(not finished)then 
		
		newline;print("simulation started");
		
		newline; print("quickly testing valid output");
		
		
		assert valid='0' report "(1)"; 	--at resetSim
		pValidArray <= "01";
		waitPeriod;
		
		assert valid='0' report "(2)";
		pValidArray<= "10";
		waitPeriod;
		
		assert valid='0' report "(3)";
		pValidArray<= "11";
		waitPeriod;
		
		assert valid ='1' report "(4)";
		waitPeriod;
		
		
		resetSim;
		newline;print("testing readyArray control signals");
		
		
		assert readyArray = "11" report "(1)";
		pValidArray <= "01";
		waitPeriod;
		
		assert readyArray = "10" report "(2)";
		pValidArray<= "10";
		waitPeriod;
		
		assert readyArray = "01" report "(3)";
		pValidArray<= "11";
		waitPeriod;
		
		assert readyArray = "00" report "(4)";	--nReady = 0
		nReady <= '1';
		pValidArray <= "00";
		waitPeriod;
		
		assert readyArray = "11" report "(5)";
		pValidArray <= "01";
		waitPeriod;
		
		assert readyArray = "10" report "(6)";
		pValidArray<= "10";
		waitPeriod;
		
		assert readyArray = "01" report "(7)";
		pValidArray<= "11";
		waitPeriod;
		
		assert readyArray = "11" report "(8)";
		waitPeriod;		
		
		
		newline;print("simulation completed");
		
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.joinN(vanilla) generic map(2)
			port map( 	pValidArray,
						nReady,
						valid,
						readyArray);
	
	-- ticks the clock
	clock : process
    begin
		if (finished) then	wait;
        else	clk <= not clk;
				wait for CLK_PERIOD / 2;
				currenttime <= currenttime + CLK_PERIOD / 2;
        end if;
    end process clock ;
      
end testbench2;
