library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.customTypes.all;

entity tb_registerFile is
end tb_registerFile;



------------------------------------------------------------------------
-- test the implementation that uses lazy joins and forks
------------------------------------------------------------------------
architecture lazy of tb_registerFile is
	
	signal finished : boolean := false;
	signal currenttime : time := 0 ns;
	signal clk : std_logic := '0';
	signal reset : std_logic;
	constant CLK_PERIOD : time := 10 ns;
	
	signal adrA, adrB, adrW, wrData, a, b : std_logic_vector(31 downto 0);
	signal pValidArray, readyArray : bitArray_t(3 downto 0);
	signal nReadyArray, validArray : bitArray_t(1 downto 0);

begin
	
	sim : process
		--reset procedure 
		procedure resetSim is
		begin
			reset <= '1';
			adrA <= (others => '0');
			adrB <= (others => '0');
			adrW <= (others => '0');
			wrData <= (others => '0');
			pValidArray <= (others => '0');
			nReadyArray <= (others => '0');
			wait until rising_edge(clk);
			wait for CLK_PERIOD / 4;
			reset <= '0';
		end procedure resetSim;
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
	
	-- writes happen correctly <-> control signals for writes are correctly joined
		newline;print("writes happen correctly");
		adrA <= X"00000003";
		adrB <= X"00000003";
		adrW <= X"00000003";
		wrData <= X"00000003";
		pValidArray <= "0000";
		nReadyArray <= "11";
		waitPeriod(1);
		assert a=X"00000000" report "(1)";
		pvalidArray <= "1110";
		waitPeriod(1);
		assert a=X"00000000" report "(2)";
		pvalidArray <= "1101";
		waitPeriod(1);
		assert a=X"00000000" report "(3)";
		pvalidArray <= "0111";
		waitPeriod(1);
		assert a=X"00000003" report "(4)";
		assert b=X"00000003" report "(5)";
		waitPeriod(1);
		resetSim;		
				
	-- control signals for reads are forwarded and data is read correctly
		newline;print("read control signals are forwarded correctly");
		adrA <= X"00000001";
		adrB <= X"00000002";
		nReadyArray <= "00";		-- no read input is valid/ready
		pValidArray <= "0000";		-- wrData and adrW control signals' are always ready
		waitPeriod(1);
		assert validArray = "00" report "(1)";
		assert readyArray = "0011" report "(2)";
		assert a=X"00000000"report "(3)";
		assert b=X"00000000"report "(4)";
		nReadyArray <= "11";		-- both next are ready, but no valid data
		waitPeriod(1);		
		assert validArray = "00"report "(5)";
		assert readyArray = "1111"report "(6)";
		assert a=X"00000000"report "(7)";
		assert b=X"00000000"report "(8)";
		pValidArray <= "1000";		-- one read data is ready/valid, the other is not
		nReadyArray <= "01";
		waitPeriod(1);		
		assert validArray = "10"report "(9)";
		assert readyArray = "0111"report "(10)";
		waitPeriod(1);
		
		resetSim;
		
	-- fills the register file so that we have stuff to read from it
		wrData <= X"00000001";
		adrW <= X"00000001";
		waitPeriod(1);
		wrData <= X"00000002";
		adrW <= X"00000002";
		waitPeriod(1);
		wrData <= X"00000003";
		adrW <= X"00000003";
		waitPeriod(1);
		wrData <= X"00000000";
		adrW <= X"00000000";
		waitPeriod(1);
		
	-- test the data reads
		-- TODO - not so important 
		
		newline;print("simulation finished");
		
		finished <= true;
	end process sim;
	
	-- design under test
	DUT : entity work.registerFile(elastic) port map (
		clk, reset, 
		adrA, adrB, adrW, wrData,
		pValidArray,
		nReadyArray,
		a, b,
		readyArray,
		validArray);
		
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
	
end lazy;
