----------------------------------------------------------  tb_branch
---------------------------------------------------------------------
-- testbench for the (simple) branch block. Does not function with the 
-- hybrid version (which has been test directly in circuit)

library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use work.testbenchCommons.all; 	-- contains clock/reset, procedures, ect...


entity tb_branch is 
end tb_branch;

architecture testbench of tb_branch is
	
	signal condition, pValid, ready : std_logic;
	signal nReadyArray, validArray : bitArray_t(1 downto 0);
	
begin
	
	-- run simulation
	sim : process
		--simulation reset
		procedure resetSim is
		begin
				reset <= '1';
				condition <= '0';
				pValid <= '0';
				nReadyArray <= (others => '0');
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;	
	begin
	resetSim;
	if(not finished)then 
	
		newline;print("NB : testbench for branch, not branchHybrid");print("simulation starting");
	
		assert validArray = "00" report "(1)";
		assert ready = '0' report "(2)";
		nReadyArray <= "10";					-- NB condition=0
		waitPeriod;
		
		assert validArray = "00" report "(3)";
		assert ready = '0' report "(4)";		-- condition doesn't allow branch 1 to control the ready signal
		nReadyArray <= "01";
		waitPeriod;
		
		assert validArray = "00" report "(5)";
		assert ready = '1' report "(4)";		-- condition allows branch 1 to control the ready signal
		pValid <= '1';
		waitPeriod;
		
		assert validArray = "01" report "(6)";	
		condition <= '1';						-- change condition
		pValid <= '0';							-- reset other signals
		nReadyArray <= "00";
		waitPeriod;
		
		assert validArray = "00" report "(7)";
		assert ready = '0' report "(8)";
		pValid <= '1';
		waitPeriod; 
		
		assert ready = '0' report "(11)";		-- branch1 is not ready
		assert validArray = "10" report "(12)";	-- condition allows annoucing valid data to branch 1
		waitPeriod(0.1);
		nReadyArray <= "11";
		waitPeriod(0.9);
		
		assert ready = '1' report "(13)";		-- now it's ready
		assert validArray = "10" report "(14)";
		waitPeriod;
		
		newline;print("simulation completed");		
		
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.branch 
			port map( 	condition,
						pValid,
						nReadyArray,
						validArray,
						ready);
		
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
