library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regFile is
port(
	clk, reset : in std_logic;
	adr_a, adr_b : in std_logic_vector(31 downto 0);
	aa, ab : out std_logic_vector(31 downto 0);
	wr_enable : in std_logic;
	wr_adr, wr_data : in std_logic_vector(31 downto 0));
end regFile;

architecture regFile1 of regFile is
	
	type register_t is array(63 downto 0) of std_logic_vector(31 downto 0);
	-- array initialized to '0' vectors
	signal reg : register_t := (others => (others => '0'));
	
begin

	-- write
	process(clk, adr_a, adr_b, wr_enable, wr_adr, wr_data)
	begin
		if(reset = '1')then
			reg <= (others => (others => '0'));
		else
			if(rising_edge(clk)) then
				if(wr_enable='1') then
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
	