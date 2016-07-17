library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity TB_IFD is
end TB_IFD;

architecture testbench of TB_IFD is

	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic;
	signal clk : std_logic := '0';
	
	constant CLK_PERIOD : time := 10 ns;

	component IFD is port(
		reset, clk : in std_logic;
	
		rddata : in std_logic_vector(31 downto 0);
		rd_addr : out std_logic_vector(31 downto 0);
		
		read_instr : out std_logic;
		instr : out std_logic_vector(31 downto 0);
		
		rf_wren : out std_logic;
		adrA, adrB, wr_adr : out std_logic_vector(31 downto 0);
		
		op,opx : out std_logic_vector(5 downto 0); --may be replaced by oc
		oc : out std_logic_vector(31 downto 0)); --for extension
	end component;
	signal rddata : std_logic_vector(31 downto 0);
	signal rd_addr : std_logic_vector(31 downto 0);
	signal instr : std_logic_vector(31 downto 0);
	signal read_instr : std_logic := '0';
	signal rf_wren : std_logic;
	signal op, opx : std_logic_vector(5 downto 0);
	signal oc, adrA, adrB, wr_adr : std_logic_vector(31 downto 0);
	
begin

	-- design under test
	DUT : IFD port map (
		reset, clk, rddata, rd_addr, read_instr, instr, rf_wren, adrA, adrB, wr_adr, op, opx, oc);

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
	
	--provide the data
	data_prvd : process
		file instr_f : text is in "TB.IFD.instruction.txt";
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
				if(line_in(1) = 'x') then
					finished <= true;
				elsif(line_in(1) /= '#' and line_in(1) /= '|') then
					wait until rising_edge(read_instr);
					read(line_in, WORD);
					rddata <= WORD;
					wait until read_instr = '0';
				end if;
			end if;
		end if;
end process data_prvd;
	
--check instr is correctly outputteds	
	check : process 
	begin
		wait until rising_edge(read_instr);
		wait until rising_edge(clk);
		wait for CLK_PERIOD / 10;  ----------------------------------------------------------------  problem here ?
		assert instr = rddata report "instr and rddata mismatch" severity error;
	end process;
	
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
end testbench;