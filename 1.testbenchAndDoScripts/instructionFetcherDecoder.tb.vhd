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

	-- design under test


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
	
	-- reads the next line, verifies it's not a comment, then holds it until the next rising clock where ifdReady='1' 
	data_prvd : process
		file instr_f : text is in "/home/quentin/Desktop/LAP/00.ElasticPipeline/1.testbenchAndDoScripts/instructionFetcherDecoder.instruction.txt";
		variable line_in : line;
		variable WORD : std_logic_vector(31 downto 0);
		variable readInstruction : boolean := false;
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
	-- text read procedures
		procedure readNextInstruction is
		begin		
			readInstruction := false;
			while not readInstruction loop													-- while we didn't read an actual instruction
				if(endfile(instr_f)) then														-- if end of file
					instrValid <= '0';																-- set the finished and instrValid signals
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
		end if;
end process data_prvd;
	
-- run simulation
	sim : process is	
		procedure reset_sim is
		begin
			reset <= '1';
			wait until rising_edge(clk);
			wait for 3 * CLK_PERIOD / 4;
			reset <= '0';
		end procedure reset_sim;
	--waiting procedures
		procedure waitPeriod is
		begin	wait for CLK_PERIOD;
		end procedure;	
	begin
		reset_sim;
		
		ifdReady <= '0';
		waitPeriod;
		
		waitPeriod;
		
		ifdReady <= '1';
		waitPeriod;
		waitPeriod;
		
		wait;
		
	end process;
end testbench;
