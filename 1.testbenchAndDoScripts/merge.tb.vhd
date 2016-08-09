library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use work.testbenchCommons.all; 	-- contains clock/reset, procedures, ect...

entity tb_merge is 
end tb_merge;

architecture testbench of tb_merge is

	signal 	data0, data1, 
			dataOut : std_logic_vector(31 downto 0);
	
	signal 	pValidArray  : bitArray_t(1 downto 0);
	signal 	nReady : std_logic;
	
	signal 	readyArray : bitArray_t(1 downto 0);
	signal 	valid : std_logic;
	
begin
	
	-- run simulation
	sim : process
				--simulation reset
		procedure resetSim is
		begin
				reset <= '1';
				data0 <= zero;
				data1 <= zero(31 downto 1) & '1';
				pValidArray <= (others => '0');
				nReady <= '0';
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
	begin
	resetSim;
	if(not finished)then 
		
		newline;print("simulation begins");
		
		
		newLine;print("checking data selection behaviour");
		
		pValidArray <= "00";	
		waitPeriod;
		-- data doesn't matter in this case, control signals will be 0 anyways
		
		pValidArray <= "01";	-- "normal case"
		waitPeriod;
		assert dataOut = data0 report "(1)";
		
		pValidArray <= "10";	-- "normal case"
		waitPeriod;
		assert dataOut = data1 report "(2)";
		
		pValidArray <= "11";	-- "default" case
		waitPeriod;
		-- as described in the paper, pValidArray(0) controls the multiplexer
		assert dataOut = data0 report "(3)";
		
		
		resetSim;		
		newLine;print("checking control signals behaviour");
		
		
		-- check the nReady control both output ready signals
		assert readyArray = "00" report "(1)";
		nReady <= '1';								
		waitPeriod;
			
		assert readyArray = "11" report "(2)";
		nReady <= '0';			
		waitPeriod;
		assert readyArray = "00" report "(3)";
		
		-- check the valid signal behaviour
		assert valid = '0' report "(4)";
		pValidArray <= "01";
		waitPeriod;
		
		assert valid = '1' report "(5)";
		pValidArray <= "10";
		waitPeriod;				
				
		assert valid = '1' report "(6)";
		pValidArray <= "11";
		waitPeriod;
		
		assert valid = '1' report "(7)";
		waitPeriod;
		
		
		newline;print("simulation completed");
		
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.merge(vanilla) 
			port map( 	data0, data1, dataOut,
						pValidArray, 
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
      
end testbench;
