------------------------------------------------------------  TB_circuit
------------------------------------------------------------------------
-- a testbench for the circuit implemented.
-- does not implement any assertion or verification of correct behaviour
-- you'll need to check it on modelsim's wave
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity TB_circuit is
end TB_circuit;

architecture elasticBasic of TB_circuit is

	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic := '1';
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 10 ns;
	
	signal data : std_logic_vector(31 downto 0); 	-- set in dataPrvd
	signal dataValid : std_logic;
	
	signal currentInstruction, resOut : std_logic_vector(31 downto 0); 	-- outputs of the circuit (for observation purpose)
	signal IFDready, resValid : std_logic; 
	
	signal ifdEmpty : std_logic; 	--to check when to finish the simulation
	
begin

		 
	-- run simulation
	sim : process
		procedure reset_sim is
		begin
			reset <= '1';
			wait until rising_edge(clk);
			wait for CLK_PERIOD / 4;
			reset <= '0';
		end procedure reset_sim;
		variable console_out : line;
		procedure print(msg : in string) is
		begin	console_out := new string'(msg);
				writeline(output, console_out);
		end procedure print;
		--end of procedures
	begin	
	
		reset_sim;
		wait;
		
	end process;
	

	-- reads the next line, verifies it's not a comment, then holds it until the next rising clock where ifdReady='1' 
	dataPrvd : process
		file instr_f : text is in "/home/quentin/Desktop/LAP/00.ElasticPipeline/1.testbenchAndDoScripts/circuit.tb.instructions.txt";
		variable line_in : line;
		variable WORD : std_logic_vector(31 downto 0);
		variable readActualInstruction : boolean := false;
	-- text read procedures
		procedure readNextInstruction is
		begin		
			readActualInstruction := false;
			while not readActualInstruction loop											-- while we didn't read an actual instruction
				if(endfile(instr_f)) then														-- if end of file
					dataValid <= '0';																-- set the finished and instrValid signals
					wait until ifdEmpty='1'; --on attends de vider le buffer de l'IFD
					finished <= true;				
					wait;
				else																			-- else
					line_in := new string'("");														-- read next line_in	
					readline(instr_f, line_in);														-- if it's not a comment
					if(line_in'length /= 0 and line_in(1) /= '#' and line_in(1) /= '|')then				-- set instruction and readInstruction boolean
						read(line_in, WORD);
						data <= WORD;
						readActualInstruction := true;
						dataValid <= '1';
					end if;
				end if;
			end loop;
		end procedure readNextInstruction;
	--end procedures
	begin
		if reset = '1' then
			data <= (others => '0');
			dataValid <= '0';
			wait until reset = '0';
		else		
			readNextInstruction;
			wait until rising_edge(clk) and ifdReady='1';
		end if;
	end process dataPrvd;
	
	
	--instantiates the DUT		can be : 	elasticBasic, singleFwdPath, fwdPathResolution
	circ : entity work.circuit(elasticBasic_delayedAdrW1) 
			port map(	reset, clk, 
						IFDready,	-- ready
						dataValid,	-- pValid
						data, 
						currentInstruction, resOut, resValid, ifdEmpty);
	
	
	-- ticks the clock
	clock : process
		variable console_out : line;
		procedure print(msg : in string) is
		begin	console_out := new string'(msg);
				writeline(output, console_out);
		end procedure print;
		--end of procedures
    begin
        if (finished) then
            wait;
        else
            clk <= not clk;
            wait for CLK_PERIOD / 2;
            currenttime <= currenttime + CLK_PERIOD / 2;
        end if;
    end process clock;
    
	
end elasticBasic;
	
