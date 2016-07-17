library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg is 
port(
	clk : in std_logic;	
	reset : in std_logic;
	d_in : in std_logic_vector (31 downto 0);
	enable : in std_logic;
	d_out : out std_logic_vector(31 downto 0)
);
end reg;

architecture reg1 of reg is 
	signal stored : std_logic_vector(31 downto 0);
begin
	process(clk, enable, d_in)
	begin
	if(reset='1')then
		stored <= (others => '0');
	else
		if(rising_edge(clk)) then
			if(enable='1') then
				stored <= d_in;
			end if;
		end if;
	end if;
	end process;
	d_out <= stored;
end reg1;

architecture actuallyNotBuggy of reg is 
	signal stored : std_logic_vector(31 downto 0);
begin
	process(clk, enable, d_in)
	begin
	if(reset='1')then
		stored <= (others => '0');
	else
			if(enable='1') then
		if(rising_edge(clk)) then
				stored <= d_in;
			end if;
		end if;
	end if;
	end process;
	d_out <= stored;
end actuallyNotBuggy;