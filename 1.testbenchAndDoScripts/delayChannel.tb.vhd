library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.customTypes.all;

entity tb_delayChannel is 
end tb_delayChannel;

architecture testbench of tb_delayChannel is
	
	signal clk : std_logic := '0';
	signal reset : std_logic;
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	constant CLK_PERIOD : time := 10 ns;	
	
	signal d_in : std_logic_vector(31 downto 0);
	signal d_out : vectorArray_t(0 to 3)(31 downto 0);
	
	signal p_valid, n_ready,
			ready : std_logic;
	signal valid : bitArray_t(0 to 3);
	
begin
	
	-- run simulation
	sim : process
		--simulation reset
		procedure resetSim is
			begin
				reset <= '1';
				p_valid <= '0';
				n_ready <= '0';
				d_in <= (others => '0');
				wait until rising_edge(clk);
				wait for(CLK_PERIOD / 4);
				reset<='0';
		end procedure resetSim;			
		--waiting procedures
		procedure waitPeriod(constant i : in real) is
		begin
			wait for i * CLK_PERIOD;
		end procedure;		
		procedure waitPeriod(constant i : in integer) is
		begin
			wait for i * CLK_PERIOD;
		end procedure;	
		--text output procedures
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
		-- finished procedures
	begin
	resetSim;
	if(not finished)then 
		p_valid <= '1';
		n_ready <= '1';
		d_in <= X"00000007";
		waitPeriod(1);
		d_in <= X"00000006";
		waitPeriod(1);
		d_in <= X"00000005";
		waitPeriod(1);
		d_in <= X"00000004";
		waitPeriod(1);
		d_in <= X"00000003";
		waitPeriod(1);
		p_valid <= '0';
		waitPeriod(3);
		
	end if;
	finished <= true;
	end process;
	
	-- instantiate design under test
	DUT : entity work.delayChannel(generique) generic map(32, 3)
			port map(clk, reset, d_in, d_out, valid, p_valid, n_ready, ready);
--			port(	clk, reset : in std_logic;
--				data_in : in std_logic_vector(DATA_SIZE-1 downto 0);
				-- all the delayed outputs
--				data_out : out vectorArray_t(0 to DELAY)(DATA_SIZE-1 DOWNTO 0); -- we want data_out(0) to select the signal with 0 delay
				--elastic control signals
--				valid : out bitArray_t(0 to DELAY); -- same as data_out
--				p_valid, n_ready : in std_logic;
--				ready : out std_logic
--			); 	
				
	-- ticks the clock
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
