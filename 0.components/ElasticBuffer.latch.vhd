library ieee;
use ieee.std_logic_1164.all;


entity ElasticBuffer_latch is
	port(	d_in : out std_logic_vector(31 downto 0);
			d_out : out std_logic_vector(31 downto 0);
			p_valid, n_ready : in std_logic;
			ready, valid : out std_logic);
end ElasticBuffer_latch;

architecture EBL1 of ElasticBuffer_latch is


begin

	--todo

end EBL1;
