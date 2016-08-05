library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.customTypes.all;

entity TB_instructionFetcherDecoder is
end TB_instructionFetcherDecoder;

architecture testbench of TB_instructionFetcherDecoder is

	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic := '1';
	signal clk : std_logic := '0';
	
	constant CLK_PERIOD : time := 10 ns;

	signal instr, adrA, adrB, adrW, argI, oc : std_logic_vector(31 downto 0);
	signal instrValid, ifdReady : std_logic;
	signal nReadyArray, validArray : bitArray_t(4 downto 0);	
	
	signal currentHeldInstruction : std_logic_vector(31 downto 0); 
	
begin

	
-- runs simulation
	sim : process is	
	--reset procedure
		procedure reset_sim is
		begin
			reset <= '1';
			nReadyArray <= "00000";
			wait until rising_edge(clk);
			wait for CLK_PERIOD / 4;
			reset <= '0';
		end procedure reset_sim;
	-- text output procedures
		variable console_out : line;
		procedure newline is
		begin
			console_out := new string'("");
			writeline(output, console_out);
		end procedure newline;
		procedure print(msg : in string) is
		begin
			console_out := new string'(msg);
			writeline(output, console_out);
		end procedure print;
	--waiting procedures
		procedure waitPeriod is
		begin	wait for CLK_PERIOD;
		end procedure;	
		procedure waitPeriod(constant i : in real) is
		begin	wait for i * CLK_PERIOD;
		end procedure;		
		procedure waitPeriod(constant n : in integer) is
		begin	wait for n * CLK_PERIOD;
		end procedure;	
	-- end of procedures
	begin
		reset_sim;	
		
		-- instr is always valid, instrValid ='1' always
		
		nReadyArray <= "00000";
		waitPeriod;
		assert validArray="11111" report "(0)";	-- there's valid data for all the output channels
		waitPeriod(2);
		assert ifdReady = '0' report "(1)"; 	-- the ifd's buffer will store the first 2 instructions, then will turn not ready
		assert validArray="11111" report "(2)";	-- there's valid data for all the output channels
		
		nReadyArray <= "01110";
		waitPeriod;
		assert ifdReady = '0' report "(3)"; 	-- still not all the outputs are ready
		assert validArray="10001" report "(4)";	-- some output channels have been served
		
		nReadyArray <= "11111";
		waitPeriod(0.5);
		assert validArray="10001" report "(5)";
		assert ifdReady = '1' report "(6)";		-- the IFD will finish passing the first instruction to all channels by the end of this clock, so it'll be ready for a new instruction
		waitPeriod(0.5);
		assert validArray="11111" report "(7)";
		
		waitPeriod;								-- data flows (all nReady and valid)
		assert ifdReady = '1' report "(8)";
		assert validArray="11111" report "(9)";
		
		waitPeriod;								-- again
		assert ifdReady = '1' report "(10)";
		assert validArray="11111" report "(11)";
		
		print("simulation finished");
		wait;
		
	end process;


	-- design under test
	DUT : entity work.instructionFetcherDecoder 
			port map (	clk, reset,
						instr, 						-- in
						adrB, adrA, adrW, argI, oc,	-- out
						instrValid,					-- in (pValid)
						nReadyArray,				-- in
						ifdReady, 					-- out
						validArray, 				-- out
						currentHeldInstruction);	-- out (for test purpose)


	
	-- reads the next line, verifies it's not a comment, then holds it until the next rising clock where ifdReady='1' 
	data_prvd : process
		file instr_f : text is in "/home/quentin/Desktop/LAP/00.ElasticPipeline/1.testbenchAndDoScripts/instructionFetcherDecoder.instruction.txt";
		variable line_in : line;
		variable WORD : std_logic_vector(31 downto 0);
		variable readInstruction : boolean := false;
	-- text read procedures
		procedure readNextInstruction is
		begin		
			readInstruction := false;
			while not readInstruction loop													-- while we didn't read an actual instruction
				if(endfile(instr_f)) then														-- if end of file
					instrValid <= '0';																-- set the finished and instrValid signals
					wait until validArray="00000"; --on attends de vider le buffer de l'IFD
					finished <= true;				
					wait;
				else																			-- else
					line_in := new string'("");														-- read next line_in	
					readline(instr_f, line_in);														-- if it's not a comment
					if(line_in'length /= 0 and line_in(1) /= '#' and line_in(1) /= '|')then				-- set instruction and readInstruction boolean
						instrValid <= '1';
						read(line_in, WORD);
						instr <= WORD;
						readInstruction := true;
						instrValid <= '1';
					end if;
				end if;
			end loop;
		end procedure readNextInstruction;
	--end procedures
	begin
		if reset = '1' then
			instr <= (others => '0');
			instrValid <= '0';
			wait until reset = '0';
		else		
			readNextInstruction;
			wait until rising_edge(clk) and ifdReady='1';
			wait for CLK_PERIOD / 4; -- don't loop immediately, for clarity on the wave of modelsim
		end if;
	end process data_prvd;
	
	

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
