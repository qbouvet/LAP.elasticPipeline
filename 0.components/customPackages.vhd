-------------------------------------------------------  customTypes
---------------------------------------------------------------------
-- customTypes are declared here (can't use array types directly in
-- entities' port
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
package customTypes is

	-- array of vectors used especially with delay channels
	type vectorArray_t is array (integer range <>) of std_logic_vector; -- data size and latency must be specified when used

	-- array of bits useed mostly for grouping elastic control signals. used in many components. Almost an alias for std_logic_vector
	type bitArray_t is array (integer range <>) of std_logic;

	-- the address array used as input to the dependancy detection unit
	type ADDR_ARRAY is array(integer range <>) of std_logic_vector(4 downto 0);
	
	-- data type used in the register file
	type register_t is array(63 downto 0) of std_logic_vector(31 downto 0);
	
	
	
end package;



---------------------------------------------------  testbenchCommons
---------------------------------------------------------------------
-- This package contains common code to most testbenches, such as 
-- signal declarations for clk, reset ... ; waiting and test output 
-- procedures ; 
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.customTypes.all;

package testbenchCommons is
	--signals
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;	
	
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
	
end testbenchCommons;
