------------------------------------------------   OP_unit_operations
---------------------------------------------------------------------
-- regroups all operations executed by the OP_unit ins a separate 
-- for easier readability




-----------------------------------------------------------------------------  a*b * 3 + 12 with elastic buffers
library ieee;
use ieee.std_logic_1164.all;

entity sample_op_1 is 
port(
	clk, reset,
	a, b : in std_logic_vector(31 downto 0);
	output : out std_logic_vector(31 downto 0);
	
	--elastic control signals
	p_valid, n_ready : in std_logic;
	ready, valid: out std_logic
);	
end sample_op_1;

architecture pipelined of sample_op_1 is
	signal res : array (1 to 4) of std_logic_vector(31 downto 0);
	signal valid_in : array(1 to 2) of std_logic;
	signal ready_in : array(1 to 2) of std_logic;
	end component;
begin
	m1 : entity work.multiplier
			port map(a, b, res(1), open);
	b2 : entity work.elasticBuffer_reg generic map(32)
			port map(clk, reset, res(1), res(2), p_valid, ready_in(1), ready, , valid_in(1));
	m3 : entity work.multiplier 
			port map(res(2), X"00000003", res(2), open);
	b3 : entity work.elasticBuffer_reg generic map(32)
			port map(clk, reset, res(2), res(3), valid_in(1), ready_in(2), ready_in(1), valid_in(2));
	a5 : entity work.adder
			port map(res(3), X"0000000C", res(4), open);
	b6 : entity work.elasticBuffer_reg generic map(32)
			port map(clk, reset, res(4), output, valid_in(2), n_ready, ready_in(2), valid);
end pipelined;




----------------------------------------------------------------------------- a+b with buffer
library ieee;
use ieee.std_logic_1164.all;

entity adderWithBuffers is
port(	clk, reset,
		a, b : in std_logic_vector(31 downto 0);
		output : out std_logic_vector(31 downto 0);
		carry : out std_logic;
	
		--elastic control signals
		p_valid, n_ready : in std_logic;
		ready, valid: out std_logic
);
end adderWithBuffers;

architecture pipelined of adderWithBuffers is
	addi_res : std_logic_vector(31 downto 0);
	carry_res : std_logic;
	buffer_out : array (2 downto 0) of std_logic_vector(32 downto 0);
	
	--control signals
	buffer_valid, buffer_ready : array(1 dowto 0) of std_logic;
begin	
	
	addi : entity work.adder 
			port map(a, b, addi_res, carry_res);
	resBuffer0 : entity work.elasticBuffer_reg generic map(33)
			port map(clk, reset, carry_res&addi_res, buffer_out(0), p_valid, buffer_ready(0), ready, buffer_valid(0));
	resBuffer1 : entity work.elasticBuffer_reg generic map(33)
			port map(clk, reset, buffer_out(0), buffer_out(1), buffer_valid(0), buffer_ready(1), buffer_ready(0), buffer_valid(1));
	resBuffer2 : entity work.elasticBuffer_reg generic map(33)
			port map(clk, reset, buffer_out(1), buffer_out(2), buffer_valid(1), n_ready, buffer_ready(1), valid);
	
	output <= buffer_out(2)(31 downto 0);
	carry <= buffer_out(2)(32);
end pipelined;




-----------------------------------------------------------------------------   Multiplier
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity multiplier is 
	port(
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		res : out std_logic_vector(31 downto 0);
		overflow : out std_logic
	);
end multiplier;

architecture multiplier1 of multiplier is	
	signal res_temp : std_logic_vector (63 downto 0);
begin
	res_temp <= std_logic_vector(unsigned(a) * unsigned(b));
	res <= res_temp(31 downto 0);
	overflow <= '0' when res_temp(63 downto 32) = X"00000000" else '1';	
end multiplier1;


-----------------------------------------------------------------------------   Adder
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity adder is
	port (
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		res : out std_logic_vector(31 downto 0);
		carry : out std_logic
	);
end adder;

architecture adder1 of adder is

	signal temp_res : std_logic_vector(32 downto 0);

begin
	
	temp_res <= ('0' & a) + ('0' & b);
	
	res <= temp_res(31 downto 0);
	carry <= temp_res(32);
	
end adder1;
