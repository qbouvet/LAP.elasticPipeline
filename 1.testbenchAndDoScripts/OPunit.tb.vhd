library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.customTypes.all;

entity TB_OPunit is 
end TB_OPunit;


------------------------------------------------------------------------
-- tests the OPunit itself
------------------------------------------------------------------------
architecture OPunit of TB_OPunit is

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
		procedure resetSim is
		begin
			print("reset");
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
			print("reset done");
		end procedure;			
		--waiting procedures
		procedure waitPeriod(constant i : in real) is
		begin	wait for i * CLK_PERIOD;
		end procedure;		
		procedure waitPeriod(constant i : in integer) is
		begin	wait for i * CLK_PERIOD;
		end procedure;	
		-- finished procedures
	begin
		resetSim;
		if(not finished)then
		
			newline;print("simulation started");
			newline;print("basic tests");
			-- addi test
			oc <= X"00000" & "000000100000"; -- op0-addi		
			argA <= X"00000001";
			argI <= X"00000002";
			nReady <= '1';
			pValidArray <= (others => '1');
			waitPeriod(1);
			assert res=X"00000003" report "addi fails" severity error;
			
			waitPeriod(0.5);
			--insert here
			
		end if;		
		
		newline;print("simluation finished");
		finished <= true;
	end process sim;

	-- DUT instance
	opu : entity work.OPunit(debug3)
		port map(	clk, reset, 
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
    
end OPunit;
	
	
	
	
	
	
	
	




------------------------------------------------------------------------
-- tests the selector block from the OPunit
------------------------------------------------------------------------
architecture selectorBlock of TB_OPunit is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;	
	
	signal res1, res0, oc, res : std_logic_vector(31 downto 0);
	signal pValidArray,readyArray : bitArray_t(2 downto 0);
	signal nReady, valid : std_logic;
	
begin
	
	-- run simulation
	sim : process
		-- reset procedure
		procedure resetSim is
			begin
				reset <= '1';
				pValidArray <= (others => '0');
				nReady <= '0';
				res1 <= (others => '0');
				res0 <= (others => '0');
				oc <= (others => '0');
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
		
		print("quick test for the data part");
		res0 <= X"00000001";
		res1 <= X"00000002";
		waitPeriod(1);
		oc <= "00000000000000000000000000100000";
		waitPeriod(1);
		assert res=res0;
		oc <= "00000000000000000000000001000000";
		waitPeriod(1);
		assert res=res1;
		
		resetSim;
		res0 <= X"00000001";
		res1 <= X"00000002";
		oc <= "00000000000000000000000000100000";
		
		print("control signals tests");
		-- NB 'valid0 depends only on wether the previous data is valid
		-- 'ready(x)' depends on wether nReady='1' but also on wether all other previous data are valid
		-- nReady = '0'
		pValidArray <= "001";
		waitPeriod(1);
		assert valid = '0';
		assert readyArray = "110";
		pValidArray <= "010";	
		waitPeriod(1);	
		assert valid = '0';
		assert readyArray = "101";
		pValidArray <= "100";
		waitPeriod(1);
		assert valid = '0';
		assert readyArray = "011";
		pValidArray <= "110";
		waitPeriod(1);
		assert valid = '0';
		assert readyArray = "001";
		pValidArray <= "111";
		waitPeriod(1);		
		assert valid = '1';
		-- nReady = '1'
		nReady <= '1';
		pValidArray <= "001";
		waitPeriod(1);
		assert valid = '0';
		pValidArray <= "010";	
		waitPeriod(1);	
		assert valid = '0';
		pValidArray <= "100";
		waitPeriod(1);
		assert valid = '0';
		pValidArray <= "110";
		waitPeriod(1);
		assert valid = '0';
		pValidArray <= "111";
		waitPeriod(1);
		assert valid = '1';
		assert readyArray = "111";
		
		newline;print("simulation finished");
		
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.selectorBlock 
			port map(	res1, res0, oc,
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
      
end selectorBlock;
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	


------------------------------------------------------------------------
-- tests op1 (addi)
------------------------------------------------------------------------
architecture op1 of TB_OPunit is
	
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
			port map( 	a, b, 
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







------------------------------------------------------------------------
-- tests op0 (addi)
------------------------------------------------------------------------
architecture addi of TB_OPunit is
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
	DUT : entity work.op0
			port map( 	a, b, 
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
	
	
	
