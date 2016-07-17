library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity TB_EB is
end TB_EB;

architecture testbench of TB_EB is

	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;
	
	constant CLK_PERIOD : time := 10 ns;

	component elasticBuffer is
	port(
		clk, reset : in std_logic;
		
		d_in : in std_logic_vector(31 downto 0);
		d_out : out std_logic_vector(31 downto 0);
		
		p_valid, n_ready : in std_logic;
		ready, valid : out std_logic);
	end component;
	
    signal reset : std_logic := '1';
	signal clk : std_logic := '0';
	signal p_valid, n_ready : std_logic := '0';
	signal d_in : std_logic_vector(31 downto 0) := (others => '0');
	
	signal ready, valid : std_logic;
	signal d_out : std_logic_vector(31 downto 0);
	
begin

	simulation : process	
		procedure reset_sim is 
		begin
			wait until rising_edge(clk);
			reset <= '1';
			d_in <= (others => '0');
			p_valid <= '0';
			n_ready <= '0';
			wait for CLK_PERIOD / 4;
			reset <= '0';
		end procedure reset_sim;
	-- text output procedures
		variable console_out : line;
		procedure newline is
		begin
			console_out := new string'("");
			writeline(output, console_out);
		end procedure newline;
		procedure print(msg : in string) is
		begin
			console_out := new string'(msg);
			writeline(output, console_out);
		end procedure print;
	begin if(not finished) then
		reset_sim;
		
	-- functions when p_valid changes mid clock
		--one in, one out, one in
		newline; print("one in, one out, one in");		
		wait until falling_edge(clk);
		wait for CLK_PERIOD / 4;
		p_valid <= '1';
		d_in <= X"00000001";
		wait for CLK_PERIOD; --one in
		assert d_out = X"00000001" report "incorrect output (1)" severity error;		
		p_valid <= '0';
		n_ready <= '1';
		wait for CLK_PERIOD; -- one out
		p_valid <= '1';
		n_ready <= '0';
		d_in <= X"00000002";
		wait for CLK_PERIOD;
		assert d_out = X"00000002" report "incorrect output (2)" severity error;		
		reset_sim;		
		
		
		--3 sequentially
		newline; print("3 sequentially");
		wait until falling_edge(clk); 
		wait for CLK_PERIOD / 4;
		p_valid <= '1';
		d_in <= X"00000005";
		wait for CLK_PERIOD; -- one in
		d_in <= X"00000006";
		wait for CLK_PERIOD; -- two in 
		assert d_out = X"00000005" report "incorrect output (1)" severity error;
		n_ready <= '1';
		d_in <= X"00000007";
		wait for CLK_PERIOD;
		p_valid <= '0';
		assert d_out = X"00000006" report "incorrect output (2)" severity error;
		wait for CLK_PERIOD;
		assert d_out = X"00000007" report "incorrect output (3)" severity error;
		reset_sim;
		
		
	-- when p_valid changed at rising edge
		newline; print("one in");
		wait until rising_edge(clk);
		p_valid <= '1';
		d_in <= X"00000001";
		wait for CLK_PERIOD;
		assert d_out=X"00000001" report "wrong output (1)" severity error;
		
		
		
		finished <= true;	
		newline; print("done");
	end if;
	end process simulation;

	--instanciating design under test
	DUT : elasticBuffer port map(
		clk, reset, d_in, d_out, 
		p_valid, n_ready, ready, valid
		);
	
	clock : process
    begin
        if (finished) then
            wait;
        else
            clk <= not clk;
            wait for CLK_PERIOD / 2;
            currenttime <= currenttime + CLK_PERIOD / 2;
        end if;
    end process clock;
	
end testbench;