--------------------------------------------------  OP unit's operations
------------------------------------------------------------------------
-- regroups all operations used in the OP unit, as well as 
-- simpler blocks used in said operations


-----------------------------------------------------------   Multiplier 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplier is 
	port(
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		res : out std_logic_vector(31 downto 0);
		overflow : out std_logic);
end multiplier;

architecture multiplier1 of multiplier is	
	signal res_temp : std_logic_vector (63 downto 0);
begin
	res_temp <= std_logic_vector(unsigned(a) * unsigned(b));
	res <= res_temp(31 downto 0);
	overflow <= '0' when res_temp(63 downto 32) = X"00000000" else '1';	
end multiplier1;

----------------------------------------------------------------   Adder
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
		carry : out std_logic);
end adder;

architecture adder1 of adder is
	signal temp_res : std_logic_vector(32 downto 0);
begin
	
	temp_res <= ('0' & a) + ('0' & b);
	
	res <= temp_res(31 downto 0);
	carry <= temp_res(32);
	
end adder1;




------------------------------------------------------------------------
-- an "operation" block with elastic control signals
-- integrates the "join" block for its arguments, but no buffer (yet)
-- this one will be the "immediate addition" operation - takes 1 cycle
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity op0 is 
port(
	a, b : in std_logic_vector(31 downto 0);
	res : out std_logic_vector(31 downto 0);
	pValidArray : in bitArray_t(1 downto 0);
	nReady : in std_logic;
	readyArray : out bitArray_t(1 downto 0);
	valid : out std_logic;
	);
end op0;

architecture s1 of sample_op_0 is
begin

	joinArgs : entity work.join 
			port map(pValidArray(0), pValidArray(1), nReady, valid, readyArray(0), readyArray(1));

	addArgs : entity work.adder 
			port map (a, b, res, open); --leave the carry open

end s1;


------------------------------------------------------------------------
-- another "operation" block with elastic control signals
-- integrates the "join" block for its arguments
-- this a   (a,b) -> a*(a+b)
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity op1 is 
port(
	a, b : in std_logic_vector(31 downto 0);
	res : out std_logic_vector(31 downto 0);
	pValidArray : in bitArray_t(1 downto 0);
	nReady : in std_logic;
	readyArray : out bitArray_t(1 downto 0);
	valid : out std_logic;
	);
end op1;

architecture vanilla of op1 is
begin
	joinArgs : entity work.join3
			port map(pValidArray(0), pValidArray(1), nReady, valid, readyArray(0), readyArray(1));
			
	
end vanilla;
