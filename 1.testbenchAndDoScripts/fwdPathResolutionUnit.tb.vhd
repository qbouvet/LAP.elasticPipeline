library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use work.testbenchCommons.all; 	-- contains clock/reset, procedures, ect...

entity tb_forwardingUnit is 
end tb_forwardingUnit;






------------------------------------------------------------------------
-- Tests a forwarding unit of size 5 (3 fwd paths)
------------------------------------------------------------------------
architecture testbench5 of tb_forwardingUnit is
	constant INPUT_NB : integer := 5;	
	constant DATASIZE : INTEGER := 32;
	
	signal readAdrB, readAdrA	: std_logic_vector(31 downto 0);
	signal wAdrArray 			: vectorArray_t(INPUT_NB-1 downto 2)(31 downto 0);			-- (oldest(mem bypass) -> newest write addresses)
	signal adrValidArray		: bitArray_t(INPUT_NB-1 downto 0);							-- (oldest(mem bypass) -> newest write addresses, readAdrB, readAdrA)
	
	signal inputArray 			: vectorArray_t(INPUT_NB-1 DOWNTO 0)(DATASIZE-1 downto 0);	-- (oldest(mem bypass) -> newest instruction's results, B_RF, A_RF)
	signal inputValidArray 		: bitArray_t(INPUT_NB-1 downto 0);							-- (oldest(mem bypass) -> newest instruction's results, B_RF, A_RF)
	signal outputArray			: vectorArray_t(1 downto 0)(DATASIZE-1 downto 0);	
		
	signal nReadyArray, validArray, 
			readyArray			: bitArray_t(1 downto 0);
begin
	
	-- run simulation
	sim : process
				--simulation reset
		procedure resetSim is
		begin
				reset <= '1';
				readAdrA <= (others => '0');
				readAdrB <= (others => '0');
				wAdrArray <= (others => (others => '0'));
				adrValidArray <= (others => '0');
				inputArray <= (others => (others => '0'));
				inputValidArray <=(others => '0');
				nReadyArray <= (others => '0');
				
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
	begin
	resetSim;
	if(not finished)then 
		
			
		newline;print("simulation started - 5 inputs");
		
		
		wAdrArray <= (X"00000003", X"00000002", X"00000001"); 							-- addresse : ([oldest]membypass<-3, fw1<-2, fw0<-1[newest])
		inputArray <= (X"00000003",X"00000002",X"00000001",X"00000014",X"0000000A"); 	-- values contained : ([oldest]membypass=3, fw1=2, fw0=1[newest] B_RF=20, A_RF=10)
		adrValidArray <= "11111";
		inputValidArray <= "11111";
		nReadyArray <= "11";
		waitPeriod;
		
		
		newline;print("testing data output");
		
		
		assert outputArray = (X"00000014",X"0000000A")  report "(1)";		-- no matching adress -> get from RF
		readAdrA <= X"00000001";
		readAdrB <= X"00000002";
		waitPeriod;
		
		assert outputArray = (X"00000002",X"00000001")  report "(2)";		-- reading from different inputs
		readAdrA <= X"00000002";
		readAdrB <= X"00000003";
		waitPeriod;
		
		assert outputArray = (X"00000003", X"00000002") report "(3)";
		readAdrA <= X"00000003";
		readAdrB <= X"00000003";
		waitPeriod;
		
		assert outputArray = (X"00000003", X"00000003") report "(4)";
		waitPeriod;
		
		
		newline;print("testing control signals");
		

		adrValidArray <= "00000";			-- no valid address
		inputValidArray <= "00000";			-- no valid incomming data
		nReadyArray <= "00";				-- next not ready
		waitPeriod;
		
		assert validArray = "00" report "(1)";
		assert readyArray = "00" report "(2)";
		nReadyArray <= "11";					-- check ready signals are forwarded
		waitPeriod;
		
		assert readyArray = "11" report "(3)";	
		nReadyArray <= "10";
		waitPeriod;
		
		assert readyArray = "10" report "(4)";
		nreadyArray <= "01";
		waitPeriod;
		
		assert readyArray = "01" report "(5)";
		nReadyArray <= "00";
		readAdrA <= X"00000002";				-- fwd path 1
		readAdrB <= X"00000000";				-- operandB will be read from RF
		adrValidArray <= "11111";				-- adress is valid, data is not for A
		inputValidArray <= "10111";				
		waitPeriod;
		
		assert validArray = "10" report "(6)";
		assert outputArray(1) = X"00000014" report "(7)";
		readAdrA <= X"00000003";				-- mem bypass
		waitPeriod;								-- this time, operandA is read from mem bypass, which has valid input + valid address
		
		assert validArray = "11" report "(8)";
		adrValidArray <= "10000";				-- valid address, but no valid data at mem bypass
		inputValidArray <= "00000";
		readAdrA <= X"00000003";				--asking at membypass
		readAdrB <= X"00000003";
		waitPeriod;
		
		assert validArray <= "00" report "(9)";
		adrValidArray <= "01000";				-- valid adress/data at fw1, valid data only at membypass
		inputValidArray <= "11000";				
		readAdrA <= X"00000001";				-- asking at fw1
		readAdrB <= X"00000002";				-- asking at fw1
		waitPeriod;
		
		assert validArray = "10" report "(10)";		
		wAdrArray <= (X"00000001", X"00000001", X"00000001"); 	-- addresse : (membypass<-1, fw1<-1, fw0 <-1)
		readAdrA <= X"00000001";
		readAdrB <= X"00000001";
		inputValidArray <= "11111";
		adrValidArray <= "11011";								-- if the most recent bypass doesn't have valid address -> can't have valid data
		waitPeriod;
				
		assert validArray = "00" report "(11)";
		inputValidArray <= "11011";								-- if the most recent bypass doesn't have valid data -> can't have valid data
		adrValidArray <= "11111";
		waitPeriod;
		
		assert validArray = "00" report "(12)";
		inputArray <= (X"0000000F",X"0000000A",X"00000005",X"00000014",X"0000000A"); 	-- values contained : ([oldest]membypass=15, fw1=10, fw0=5[newest] B_RF=20, A_RF=10)
		inputValidArray <= "01100";								-- can fetch valid data from the most recent bypass
		adrValidArray <= "01100";								-- + fetches the correct data
		waitPeriod;
		
		assert validArray = "11" report "(13)";
		assert outputArray = (X"00000005",X"00000005") report "(14)";
		inputValidArray <= "01000";								-- newest data is not valid
		adrValidArray <= "01100";								-- -> newest data is selected, but invalid
		waitPeriod;
		
		assert validArray = "00" report "(15)";
		assert outputArray = (X"00000005",X"00000005") report "(16)";
		inputValidArray <= "00011";								-- fetches data in register if no address matched
		adrValidArray <= "00011";
		readAdrA <= X"10000000";
		readAdrB <= X"10010010";
		waitPeriod;
		
		assert validArray = "11" report "(17)";
		assert outputArray = (X"00000014",X"0000000A") report "(18)";
		waitPeriod;
		
		
		newline;print("simulation completed");
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.forwardingUnit(vanilla) generic map(DATASIZE, INPUT_NB) 
			port map( 	readAdrB, readAdrA,
						wAdrArray, 
						adrValidArray,
						inputArray, inputValidArray, 
						outputArray, 
						nReadyArray,
						validArray, readyArray);
	
	-- ticks the clock
	clock : process
    begin
		if (finished) then	wait;
        else	clk <= not clk;
				wait for CLK_PERIOD / 2;
				currenttime <= currenttime + CLK_PERIOD / 2;
        end if;
    end process clock ;
      
end testbench5;








------------------------------------------------------------------------
-- Tests a forwarding unit of size 3 (1 fwd paths)
------------------------------------------------------------------------
architecture testbench3 of tb_forwardingUnit is
	constant INPUT_NB : integer := 3;	
	constant DATASIZE : INTEGER := 32;
	
	signal readAdrB, readAdrA	: std_logic_vector(31 downto 0);
	signal wAdrArray 			: vectorArray_t(INPUT_NB-1 downto 2)(31 downto 0);			-- (oldest(mem bypass) -> newest write addresses)
	signal adrValidArray		: bitArray_t(INPUT_NB-1 downto 0);							-- (oldest(mem bypass) -> newest write addresses, readAdrB, readAdrA)
	
	signal inputArray 			: vectorArray_t(INPUT_NB-1 DOWNTO 0)(DATASIZE-1 downto 0);	-- (oldest(mem bypass) -> newest instruction's results, B_RF, A_RF)
	signal inputValidArray 		: bitArray_t(INPUT_NB-1 downto 0);							-- (oldest(mem bypass) -> newest instruction's results, B_RF, A_RF)
	signal outputArray			: vectorArray_t(1 downto 0)(DATASIZE-1 downto 0);	
		
	signal nReadyArray, validArray, 
			readyArray			: bitArray_t(1 downto 0);
			
	-- ugly stuff to typecast a single element to an array of size 1
begin
	
	-- run simulation
	sim : process
				--simulation reset
		procedure resetSim is
		begin
				reset <= '1';
				readAdrA <= (others => '0');
				readAdrB <= (others => '0');
				wAdrArray <= (others => (others => '0'));
				adrValidArray <= (others => '0');
				inputArray <= (others => (others => '0'));
				inputValidArray <=(others => '0');
				nReadyArray <= (others => '0');
				
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
	begin
	resetSim;
	if(not finished)then 
		
			
		newline;print("simulation started - 3 inputs -> single fwd path");
		
		
		
		wAdrArray <= (0 => X"00000001"); 							-- addresse : 			membypass<-1
		inputArray <= (X"00000001",X"00000014",X"0000000A"); 	-- values contained : 	membypass=1, B_RF=20, A_RF=10)
		adrValidArray <= "111";
		inputValidArray <= "111";
		nReadyArray <= "11";
		waitPeriod;
		
		
		newline;print("testing data output");
		
		
		assert outputArray = (X"00000014",X"0000000A")  report "(1)";		-- no matching adress -> get from RF
		readAdrA <= X"00000001";
		readAdrB <= X"00000002";
		waitPeriod;
		
		assert outputArray = (X"00000014",X"00000001")  report "(2)";		-- reading from different inputs
		readAdrA <= X"00000002";
		readAdrB <= X"00000003";
		waitPeriod;
		
		
		newline;print("testing control signals");
		

		adrValidArray <= "000";			-- no valid address
		inputValidArray <= "000";		-- no valid incomming data
		nReadyArray <= "00";			-- next not ready
		waitPeriod;
		
		assert validArray = "00" report "(1)";
		assert readyArray = "00" report "(2)";
		nReadyArray <= "11";					-- check ready signals are forwarded
		waitPeriod;
		
		assert readyArray = "11" report "(3)";	
		nReadyArray <= "10";
		waitPeriod;
		
		assert readyArray = "10" report "(4)";
		nreadyArray <= "01";
		waitPeriod;
		
		assert readyArray = "01" report "(5)";
		nReadyArray <= "00";
		readAdrA <= X"00000001";			-- fwd path
		readAdrB <= X"00000000";			-- operandB will be read from RF
		adrValidArray <= "111";				-- adress is valid, data is not for A
		inputValidArray <= "011";				
		waitPeriod;
		
		assert validArray = "10" report "(6)";
		assert outputArray(1) = X"00000014" report "(7)";
		adrValidArray <= "011";				-- this time, data valid but adress is not
		inputValidArray <= "111";
		waitPeriod;								
		
		assert validArray = "10" report "(8)";
		adrValidArray <= "111";				-- this time we can use the fwd path
		inputValidArray <= "111";
		readAdrA <= X"00000001";			--asking at membypass
		readAdrB <= X"00000003";
		waitPeriod;
		
		assert validArray <= "11" report "(9)";
		adrValidArray <= "100";					-- valid adress/data at fw1, valid data only at membypass -> check we can fetch from fwd path alone
		inputValidArray <= "100";					
		readAdrA <= X"00000001";				-- asking at fwd path
		readAdrB <= X"00000002";				-- asking at rf
		waitPeriod;
		
		assert validArray = "01" report "(10)";		
		assert outputArray(0) = X"00000001" report "(11)";
		adrValidArray <= "111";					-- try to replicate the "resolving when should not" issue we have in the circuit
		inputValidArray <= "111";					
		readAdrA <= X"00000001";				
		readAdrB <= X"00000000";				
		wAdrArray <= (0 => X"00000005"); 
		waitPeriod;
		
		assert outputArray = (X"00000014",X"0000000A");
		waitPeriod;
		
		
		newline;print("simulation completed");
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.forwardingUnit(vanilla) generic map(DATASIZE, INPUT_NB) 
			port map( 	readAdrB, readAdrA,
						wAdrArray, 
						adrValidArray,
						inputArray, inputValidArray, 
						outputArray, 
						nReadyArray,
						validArray, readyArray);
	
	-- ticks the clock
	clock : process
    begin
		if (finished) then	wait;
        else	clk <= not clk;
				wait for CLK_PERIOD / 2;
				currenttime <= currenttime + CLK_PERIOD / 2;
        end if;
    end process clock ;
      
end testbench3;
