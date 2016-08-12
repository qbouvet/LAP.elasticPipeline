library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use work.testbenchCommons.all; 	-- contains clock/reset, procedures, ect...

entity tb_FwdPathResolutionUnit is 
end tb_FwdPathResolutionUnit;

architecture testbench of tb_FwdPathResolutionUnit is
	constant INPUT_NB : integer := 4;	
	constant DATASIZE : INTEGER := 32;
	
	signal readAdr 				: std_logic_vector(4 downto 0);
	signal wAdrArray 			: ADDR_ARRAY(INPUT_NB-1 downto 1);						-- (memory bypass, newest -> oldest write addresses)
	signal adrValidArray		: bitArray_t(INPUT_NB-1 downto 0);						-- (memory bypass, newest -> oldest write addresses, readAdr)
	
	signal inputArray 			: vectorArray_t(INPUT_NB-1 DOWNTO 0)(DATASIZE-1 downto 0);-- (memory bypass, forwarding paths in "newest instructions leftmost" order, RF output)
	signal output 				: std_logic_vector(DATASIZE-1 downto 0);		
	signal inputValidArray 		: bitArray_t(INPUT_NB-1 downto 0);						-- (memory bypass, newwest->oldest instruction result, registerFile)
	signal nReady, valid, ready	: std_logic; 
begin
	
	-- run simulation
	sim : process
				--simulation reset
		procedure resetSim is
		begin
				reset <= '1';
				readAdr <= (others => '0');
				wAdrArray <= (others => (others => '0'));
				adrValidArray <= (others => '0');
				inputArray <= (others => (others => '0'));
				inputValidArray <=(others => '0');
				nReady <= '0';
				
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
	begin
	resetSim;
	if(not finished)then 
		
			
		newline;print("simulation started - 4 inputs");
		
		
		wAdrArray <= ("00001","00010","00011"); --(1->mem bypass, 2->fwd0, 3->fwd1)
		inputArray <= (X"00000001",X"00000002",X"00000003",X"0000000A"); --(mem bypass=1, fwd0=2, fwd1=3, RF=10)
		adrValidArray <= "1111";
		inputValidArray <= "1111";
		nReady <= '1';
		waitPeriod;
		
		
		newline;print("testing data output");
		
		
		assert output = X"0000000A" report "(1)";	-- no matching adress -> get from RF
		readAdr <= "00001";
		waitPeriod;
												-- reading from different inputs
		assert output = X"00000001" report "(2)";
		readAdr <= "00010";
		waitPeriod;
		
		assert output = X"00000002" report "(3)";
		readAdr <= "00011";
		waitPeriod;
		
		assert output = X"00000003" report "(4)";
		waitPeriod;
		
		
		newline;print("testing control signals (quick)");
		

		adrValidArray <= "0000";
		inputValidArray <= "0000";
		nReady <= '0';
		waitPeriod;
		
		assert valid = '0' report "(1)";	-- no valid incomming data
		assert ready = '0' report "(2)";	-- next not ready
		nReady <= '1';
		waitPeriod;
		
		assert ready = '1' report "(3)";	-- ready is forwarded
		nReady <= '0';
		readAdr <= "00010";			-- 2 -> fwd0
		inputValidArray <= "1011";	-- (membypass, fwd0, fdw1, rf)
		adrValidArray <= "1111";	-- (membypass, fwd0, fdw1, rf)
		waitPeriod;
		
		assert valid='0' report "(4)";		-- data is not valid on the selected fwd path
		inputValidArray <= "1011";	-- (membypass, fwd0, fdw1, rf)
		adrValidArray <= "1111";	-- (membypass, fwd0, fdw1, rf)
		waitPeriod;
		
		assert valid='0' report "(5)";		-- data is valid, but address is not 
		readAdr <= "00011";			-- 3->fwd1
		inputValidArray <= "0010";
		adrValidArray <= "0010";
		waitPeriod;
		
		assert valid='1' report "(6)";		-- adr and data are valid 
		
		
		
		newline;print("simulation completed");
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.FwdPathResolutionUnit(vanilla) generic map(DATASIZE, INPUT_NB) 
			port map( 	readAdr, wAdrArray, adrValidArray,
						inputArray, output, 
						inputValidArray, nReady,
						valid, ready);
	
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
