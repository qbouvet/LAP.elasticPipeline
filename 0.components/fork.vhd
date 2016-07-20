---------------------------------------------------------------  fork
---------------------------------------------------------------------
-- forks signals from one register controller to two other register
-- controllers
-- contains both implementations from "Cortadella elastic systems", 
-- paper 2, p3
library ieee;
use ieee.std_logic_1164.all;

entity fork is
port(	p_valid,
		n_ready0, n_ready1 : in std_logic;
		ready, valid0, valid1 : out std_logic);
end fork;



architecture lazy of fork is
begin

	valid0 <= p_valid and n_ready0 and n_ready1;
	valid1 <= p_valid and n_ready0 and n_ready1;
	
	ready <= n_ready0 and n_ready1;
	
end lazy;



architecture eager of fork is
begin
	--todo
end lazy;
