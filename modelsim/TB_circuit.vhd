library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity TB_circuit is
end TB_circuit;

architecture tb_circ_naive of TB_circuit is

	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic;
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 10 ns;

	component circuit is port(
		reset, clk : in std_logic;
		read_instr : out std_logic;
		rddata : in std_logic_vector(31 downto 0);
		rd_adr, instr_out, result_out : out std_logic_vector (31 downto 0));
	end component;
	
	signal rddata, rd_adr, instr_out, result_out : std_logic_vector(31 downto 0);
	signal read_instr : std_logic; 
	
begin

	--instantiates the DUT
	circ : circuit port map(reset, clk, read_instr, rddata, rd_adr, instr_out, result_out);
	
	--check correctness of the result output
	chek_res : process
	begin
		wait until falling_edge(read_instr);
		wait for CLK_PERIOD * 11 / 10;
	end process;
	
	-- check correctness of the instr output
	check_instr : process 
	begin
		wait until rising_edge(read_instr);
		wait until rising_edge(clk);
		wait for CLK_PERIOD / 10;  ----------------------------------------------------------------  problem here ?
		assert instr_out = rddata report "instr_out and rddata mismatch" severity error;
	end process;

	--provide the data on rising edge of read_instr
	data_prvd : process
		file instr_f : text is in "TB.circ.instructions.txt";
		variable line_in : line;
		variable WORD : std_logic_vector(31 downto 0);
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
	begin
		if(endfile(instr_f)) then	
		wait for 5 * CLK_PERIOD;
			finished <= true;
			wait;
		else				
			line_in := new string'("");
			readline(instr_f, line_in);
			if(line_in'length /= 0 )then
				if(line_in(1) /= '#' and line_in(1) /= '|') then
					wait until rising_edge(read_instr);
					read(line_in, WORD);
					rddata <= WORD;
					wait until read_instr = '0';
				end if;
			end if;
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
	
	-- run simulation
	sim : process is	
		procedure reset_sim is
		begin
			reset <= '1';
			wait until rising_edge(clk);
			wait for 3 * CLK_PERIOD / 4;
			reset <= '0';
		end procedure reset_sim;
	begin
		reset_sim;
		wait;
	end process;
	
end tb_circ_naive;
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	