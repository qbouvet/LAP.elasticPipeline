---------------------------------------------------  Program Counter
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity PC is
port(
	reset : in std_logic;
	clk : in std_logic;
	enable : in std_logic;
	count : out std_logic_vector(31 downto 0)
);
end PC;

architecture PC1 of PC is
	signal counter : std_logic_vector (31 downto 0);
begin
	count <= counter;
	process(reset, clk)
	begin
	if(reset='1')then
		counter <= (others => '0');
	else
		if(rising_edge(clk))then 
			if(enable='1')then
				counter <= std_logic_vector(unsigned(counter) + 4);
			end if;
		end if;
	end if;
	end process;
end PC1;




---------------------------------------------------  Instruction Register
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity IR is
port(
	reset : in std_logic;
	clk : in std_logic;
	enable : in std_logic;
	d_in : in std_logic_vector(31 downto 0);
	d_out : out std_logic_vector(31 downto 0)
);
end IR;

architecture IR1 of IR is
begin
	process(clk)
	begin
	if(reset='1')then 
		d_out <= (others => '0');
	else 
		if(rising_edge(clk)) then
			if(enable='1') then
				d_out <= d_in;
			end if;
		end if;
	end if;
	end process;
end IR1;




------------------------------------------------------------------------  Controller
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity controller is
port(
	reset, clk : in std_logic;
	
	instr : in std_logic_vector(31 downto 0);
	oc : out std_logic_vector(31 downto 0); --for future extension
	
	readNextInstruction, rf_wren, pc_en, ir_wren : out std_logic
);
end controller;
architecture controller1 of controller is
	type state_t is (BREAK, FETCH, DECODE, OP);
	signal currentState, nextState : state_t;
begin

	-- standard functions processes

	process(clk, reset, instr, currentState)
	begin
		nextState <= currentState;
		readNextInstruction <= '0';
		rf_wren <= '0';
		pc_en <= '0';
		ir_wren <= '0';
		oc <= (others => '0');
		if(reset = '0') then 
			case currentState is 
				when FETCH =>
					readNextInstruction <= '1';
					ir_wren <= '1';
					nextState <= DECODE;
				when DECODE => 
					if(instr(5 downto 0)="111111")then
						nextState <= BREAK;
					else
						pc_en <= '1';
						nextState <= OP;
					end if;
				when OP => 
					rf_wren <= '1';
					nextState <= FETCH;
				when BREAK =>
					nextState <= BREAK;
			end case;
		end if;
	end process;
	
	process(clk)
	begin 
		if(reset='1')then	
			currentState <= FETCH;
		else
			if(rising_edge(clk))then
				currentState <= nextState;
			end if;
		end if;
	end process;
end controller1;




------------------------------------------------------------------------   IFD
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity IFD is
port(
	reset, clk : in std_logic;
	
	rddata : in std_logic_vector(31 downto 0);
	rd_addr : out std_logic_vector(31 downto 0);
	
	readNextInstr : out std_logic;
	instr_delayed : out vectorArray_t(3 downto 0)(31 downto 0);
	instr_valid : out bitArray_t(3 downto 0);
	
	rf_wren : out std_logic;
	adrA, adrB, wr_adr : out std_logic_vector(31 downto 0);
	
	oc_delayed : out vectorArray_t(3 downto 0)(31 downto 0);
	oc_valid : out bitArray_t(3 downto 0);
	
	-- elastic control signals necessary for the delayChannel
	n_ready : in std_logic;
	valid : out std_logic);
	
end IFD;

architecture IFD1 of IFD is
	
	signal pc_en, ir_wren : std_logic;
	signal instr_in : std_logic_vector(31 downto 0);
	signal instrRegister_out : std_logic_vector(31 downto 0);
	signal oc : std_logic_vector(31 downto 0);
	
begin	
	oc <= "00000000000000000000" & instr_in(16 downto 11) & instr_in(5 downto 0);
	wr_adr <= "000000000000000000000000000" & instr_in(31 downto 27);
	adrA <= "000000000000000000000000000" & instr_in(26 downto 22);
	adrB <= "000000000000000000000000000" & instr_in(21 downto 17);	
	
	ctrlr1 : entity work.controller 
			port map(reset, clk, instr_in, open, readNextInstr, rf_wren, pc_en, ir_wren);
	PC1 : entity work.PC 
			port map (reset, clk, pc_en, rd_addr);
	IR1 : entity work.IR 
			port map (reset, clk, ir_wren, rddata, instrRegister_out);
		
		
	-- delay channel for instructions
	instrDelayChannel : entity work.delayChannel(generique) generic map(32, 3)
			port map(clk, reset, instrRegister_out, instr_delayed, instr_valid, "1", "1", open); -- we fetch new instructions at each cycle ?
			
	-- delay channel for OPcode
	ocDelayChannel : entity work.delayChannel(generique) generic map(32, 3)
			port map(clk, reset, oc, oc_delayed, oc_valid, "1", "1". open); -- idem
	
	-- control signals processes
	readNextInstruction <= n_ready;
	valid <= n_ready;			-- in our simulation, the instruction reads are instanteneous. We may need to change that at some point
	
end IFD1;


