library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regFile is
port(
	clk, reset : in std_logic;
	adr_a, adr_b : in std_logic_vector(31 downto 0);
	aa, ab : out std_logic_vector(31 downto 0);
	adr_validWr : in std_logic; -- replaces wr_enable : we now write whenever there's valid data incomming
	wr_adr, wr_data : in std_logic_vector(31 downto 0);
		
	adr_validA, n_readyA, adr_validB, n_readyB : in std_logic;
	readyA, validA, readyB, validB, readyWr : out std_logic
);
end regFile;

architecture regFile1 of regFile is
	
	type register_t is array(63 downto 0) of std_logic_vector(31 downto 0);
	-- array initialized to '0' vectors
	signal reg : register_t := (others => (others => '0'));
	
begin

	--control signals stuff
	validA <= adr_validA; --reads are asynchronous
	validB <= adr_validB;
	readyA <= '1'; -- can ready anytime (at least once per clock)
	readyB <= '1';
	readyWr <= adr_validWr; -- can write to registers once per clock	

	-- write
	process(clk, adr_a, adr_b, adr_validWr, wr_adr, wr_data)
	begin
		if(reset = '1')then
			reg <= (others => (others => '0'));
		else
			if(rising_edge(clk)) then
				if(adr_validWr='1') then
					reg(to_integer(unsigned(wr_adr))) <= wr_data;
				end if;
			end if;
		end if;
		reg(0) <= (others => '0');
	end process;

	--reads 
	aa <= reg(to_integer(unsigned(adr_a)));
	ab <= reg(to_integer(unsigned(adr_b)));

end regFile1;
	
