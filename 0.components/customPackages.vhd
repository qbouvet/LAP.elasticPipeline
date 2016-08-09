---------------------------------------------------------------------
-- customPackages.vhd
--
-- COMPILE WITH VHDL 2008.
-- contains :	- custom types
--				- code shared/used by most testbenchs
--				- simple gates shared/used in several components (andN, orN)
--
--
---------------------------------------------------------------------



-------------------------------------------------------  customTypes
---------------------------------------------------------------------
-- custom types are declared here 
library ieee;
use ieee.std_logic_1164.all;
package customTypes is

	-- array of vectors used especially with delay channels
	type vectorArray_t is array (integer range <>) of std_logic_vector; -- (data size, latency) must be specified when used

	-- array of bits useed mostly for grouping elastic control signals. 
	-- An alias to std_logic_vector, used for clarity purpose. Probably could "search/replace" those if need be
	type bitArray_t is array (integer range <>) of std_logic;

	-- the address array used as input to the dependancy detection unit
	type ADDR_ARRAY is array(integer range <>) of std_logic_vector(4 downto 0);
	
	-- data type used in the register file
	type register_t is array(63 downto 0) of std_logic_vector(31 downto 0);
	
	
	
end package;



---------------------------------------------------  testbenchCommons
---------------------------------------------------------------------
-- contains code used in most testbenches :
--		- signals declarations (clk, reset, finished...)
--		- procedures (waiting, text output)
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.customTypes.all;

package testbenchCommons is
	-- usual testbench signals
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;		
	
	-- useful for reasons
	signal zero : std_logic_vector(31 downto 0) := (others => '0');
	
	--wait procedures prototypes
	procedure waitPeriod;
	procedure waitPeriod(constant i : in real);
	procedure waitPeriod(constant i : in integer);
	
	-- text output procedures variables declarations and prototypes	
	procedure newline;
	procedure print(msg : in string);
end testbenchCommons;

package body testbenchCommons is

	--waiting procedures		
	procedure waitPeriod is
	begin	wait for CLK_PERIOD;
	end procedure;		
	procedure waitPeriod(constant i : in real) is
	begin	wait for i * CLK_PERIOD;
	end procedure;		
	procedure waitPeriod(constant i : in integer) is
	begin 	wait for i * CLK_PERIOD;
	end procedure;	
	
	--text output procedures
	procedure newline is
		variable console_out : line;
	begin	console_out := new string'("");
			writeline(output, console_out);
	end procedure newline;
	procedure print(msg : in string) is
		variable console_out : line;
	begin	console_out := new string'(msg);
			writeline(output, console_out);
	end procedure print;
	
	--old/deprecated waiting procedure - for backup only, don't use
	procedure waitForRising(signal sig : in std_logic; constant i : in integer) is
	begin
		for n in 1 to i loop
			wait until rising_edge(sig);
		end loop;
	end procedure;
	
end testbenchCommons;




-----------------------------------------------------------------  andN
------------------------------------------------------------------------
-- size-generic AND gate used in the size-generic lazy fork and join
------------------------------------------------------------------------
LIBRARY IEEE;
USE ieee.std_logic_1164.all;
use work.customTypes.all;

ENTITY andN IS
GENERIC (n : INTEGER := 4);
PORT (	x : IN bitArray_t(N-1 downto 0);
		res : OUT STD_LOGIC);
END andN;

ARCHITECTURE vanilla OF andn IS
	SIGNAL dummy : bitArray_t(n-1 downto 0);
BEGIN
	dummy <= (OTHERS => '1');
	res <= '1' WHEN x = dummy ELSE '0';
END vanilla;




-----------------------------------------------------------------  orN
------------------------------------------------------------------------
-- size-generic OR gate used in the size-generic eager fork and join
------------------------------------------------------------------------
LIBRARY IEEE;
USE ieee.std_logic_1164.all;
use work.customTypes.all;

ENTITY orN IS
GENERIC (n : INTEGER := 4);
PORT (	x : IN bitArray_t(N-1 downto 0);
		res : OUT STD_LOGIC);
END orN;

ARCHITECTURE vanilla OF orN IS
	SIGNAL dummy : bitArray_t(n-1 downto 0);
BEGIN
	dummy <= (OTHERS => '0');
	res <= '0' WHEN x = dummy ELSE '1';
END vanilla;
