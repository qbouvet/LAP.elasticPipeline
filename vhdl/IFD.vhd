----------------------------------------------------   IFD
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IFD is
port(
	reset, clk : in std_logic;
	
	rddata : in std_logic_vector(31 downto 0);
	rd_addr : out std_logic_vector(31 downto 0);
	
	read_instr : out std_logic;
	instr : out std_logic_vector(31 downto 0);
	
	rf_wren : out std_logic;
	adrA, adrB, wr_adr : out std_logic_vector(31 downto 0);
	
	op,opx : out std_logic_vector(5 downto 0); --may be replaced by oc
	oc : out std_logic_vector(31 downto 0)); --for extension
end IFD;

architecture IFD1 of IFD is
	signal pc_en, ir_wren : std_logic;
	signal instr_in : std_logic_vector(31 downto 0);
	
	component controller is port(
		reset, clk : in std_logic;		
		instr : in std_logic_vector(31 downto 0);
		oc : out std_logic_vector(31 downto 0); --for future extension
		rd_instr, rf_wren, pc_en, ir_wren : out std_logic
	);
	end component;
	component PC is port(
		reset,clk,enable : in std_logic;
		count : out std_logic_vector(31 downto 0));
	end component;	
	component IR is port(
		reset : in std_logic;
		clk : in std_logic;
		enable : in std_logic;
		d_in : in std_logic_vector(31 downto 0);
		d_out : out std_logic_vector(31 downto 0)
	);
	end component;
begin	
	instr <= instr_in;
	op <= instr_in(5 downto 0);
	opx <= instr_in(16 downto 11);
	wr_adr <= "000000000000000000000000000" & instr_in(31 downto 27);
	adrA <= "000000000000000000000000000" & instr_in(26 downto 22);
	adrB <= "000000000000000000000000000" & instr_in(21 downto 17);	
	
	ctrlr1 : controller port map(
		reset, clk, instr_in, oc, read_instr, rf_wren, pc_en, ir_wren);
	PC1 : PC port map (
		reset, clk, pc_en, rd_addr);
	IR1 : IR port map (
		reset, clk, ir_wren, rddata, instr_in);
end IFD1;




--------------------------------------------------  Controller
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
port(
	reset, clk : in std_logic;
	
	instr : in std_logic_vector(31 downto 0);
	oc : out std_logic_vector(31 downto 0); --for future extension
	
	rd_instr, rf_wren, pc_en, ir_wren : out std_logic);
end controller;
architecture controller1 of controller is
	type state_t is (BREAK, FETCH, DECODE, OP);
	signal currentState, nextState : state_t;
begin

	process(clk, reset, instr, currentState)
	begin
		nextState <= currentState;
		rd_instr <= '0';
		rf_wren <= '0';
		pc_en <= '0';
		ir_wren <= '0';
		oc <= (others => '0');
		if(reset = '0') then 
			case currentState is 
				when FETCH =>
					rd_instr <= '1';
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

---------------------------------------------------  Program Counter
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

