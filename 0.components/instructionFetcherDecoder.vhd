-------------------------------------------------------------------  IFD
-- receives the instruction as input, creates all necessary 
-- combinatorial signals from the instruction, and send it to the 
-- circuit.
-- uses elastic control signals.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity instructionFetcherDecoder is
port(
	clk, reset : in std_logic;
	instr_in : in std_logic_vector(31 downto 0);
	
	adrB, adrA, adrW, argI, oc : out std_logic_vector(31 downto 0);
	
	-- elastic control signals
	pValid : in std_logic;
	nReadyArray : in bitArray_t(4 downto 0); -- in order : (4)adrB, adrA, adrW, argI, oc(0)
	ready : out std_logic;
	validArray : out bitArray_t(4 downto 0); -- same order 
	
	currentInstruction : out std_logic_vector -- to allow us to look what's going on inside during tests (cf circuit.vhd)
); end instructionFetcherDecoder;

architecture vanilla of instructionFetcherDecoder is
	signal instr : std_logic_vector(31 downto 0);
	signal forkReady, instrReg_valid : std_logic;
begin

	-- all outputs are combinatorial - this + elastic control signals replace the controller
	oc <= X"00000" & instr_in(16 downto 11) & instr_in(5 downto 0);
	argI <= X"0000" & instr_in(21 downto 6);
	adrW <= X"000000" & "000" & instr_in(31 downto 27);
	adrA <= X"000000" & "000" & instr_in(26 downto 22);
	adrB <= X"000000" & "000" & instr_in(21 downto 17);	
	
	-- an elastic buffer has the role of instruction register (holds the current instruction)
	instructionRegister : entity work.elasticBuffer generic map (32)
			port map(clk, reset, instr_in, instr, pValid, forkReady, ready, instrReg_valid);
	
	-- a fork5 maps the instruction register's control signal to all the data outputs made from the isntruction
	forkToOutputs : entity work.forkN generic map (5)
			port map(clk, reset, instrReg_valid, nReadyArray, validArray, forkReady);
	
	currentInstruction <= instr;
	
end vanilla;

































-- replaced by an elastic buffer
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


-- not used : the instructions are exectued sequentially
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


-- no longer used
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
