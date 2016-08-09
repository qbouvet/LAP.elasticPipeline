------------------------------------------------------------------------
------------------------------------------------------------------------
-- contains tests for the OP unit operations
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.customTypes.all;

entity TB_OPunit_operations is 
end TB_OPunit_operations;


------------------------------------------------------------------------
-- tests addi
------------------------------------------------------------------------
architecture addi of TB_OPunit_operations is
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;	
	
	signal a, b, res : std_logic_vector(31 downto 0);
	signal pValidArray, readyArray : bitArray_t(1 downto 0);
	signal nReady, valid : std_logic;
begin
	
	-- run simulation
	sim : process
		-- reset procedure
		procedure resetSim is
			begin
				reset <= '1';
				a <= (others => '0');
				b <= (others => '0');
				pValidArray  <= (others => '0');
				nReady <= '0';
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
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
	if(not finished)then 
		
		a <= X"00000001";
		b <= X"00000001";	
		
		pValidArray <= "00";
		waitPeriod(1);
		assert readyArray="11";
		pValidArray <= "01";
		waitPeriod(1);
		assert readyArray="10";
		pValidArray <= "10";
		waitPeriod(1);
		assert readyArray="01";
		pValidArray <= "11";
		waitPeriod(1);
		assert readyArray="00";
		
		nReady <= '1';
		pValidArray <= "00";
		waitPeriod(1);
		assert readyArray="11";
		pValidArray <= "01";
		waitPeriod(1);
		assert readyArray="10";
		pValidArray <= "10";
		waitPeriod(1);
		assert readyArray="01";
		pValidArray <= "11";
		waitPeriod(1);
		assert readyArray="11";
		
		a <= X"00000002";
		b <= X"00000001";
		waitPeriod(1);
		a <= X"00000002";
		b <= X"00000003";
		waitPeriod(1);
			
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.op0(forwarding)
			port map( 	clk, reset,
						a, b, 
						res, 
						pValidArray,
						nReady,
						readyArray,
						valid);
	
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
      
end addi;
	
	
	

	


------------------------------------------------------------------------
-- tests op1 
------------------------------------------------------------------------
architecture op1 of TB_OPunit_operations is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;	
	
	signal a, b, res : std_logic_vector(31 downto 0);
	signal pValidArray, readyArray : bitArray_t(1 downto 0);
	signal nReady, valid : std_logic;
	
begin
	
	-- run simulation
	sim : process
		-- reset procedure
		procedure resetSim is
			begin
				reset <= '1';
				a <= (others => '0');
				b <= (others => '0');
				pValidArray  <= (others => '0');
				nReady <= '0';
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
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
	if(not finished)then 
		
		a <= X"00000001";
		b <= X"00000001";	
		
		pValidArray <= "00";
		waitPeriod(1);
		assert readyArray="11";
		pValidArray <= "01";
		waitPeriod(1);
		assert readyArray="10";
		pValidArray <= "10";
		waitPeriod(1);
		assert readyArray="01";
		pValidArray <= "11";
		waitPeriod(1);
		assert readyArray="00";
		
		nReady <= '1';
		pValidArray <= "00";
		waitPeriod(1);
		assert readyArray="11";
		pValidArray <= "01";
		waitPeriod(1);
		assert readyArray="10";
		pValidArray <= "10";
		waitPeriod(1);
		assert readyArray="01";
		pValidArray <= "11";
		waitPeriod(1);
		assert readyArray="11";
		
		a <= X"00000002";
		b <= X"00000001";
		waitPeriod(1);
		a <= X"00000002";
		b <= X"00000003";
		waitPeriod(1);
		
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.op1
			port map( 	clk, reset,
						a, b, 
						res, 
						pValidArray,
						nReady,
						readyArray,
						valid);
	
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
      
end op1;






