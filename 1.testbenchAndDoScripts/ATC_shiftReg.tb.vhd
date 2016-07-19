library ieee;
use ieee.std_logic_1164.all;

entity tb_atc_shiftReg is 
end tb_atc_shiftReg;


-- the weird signals assignment here are done to avoid sequential assignments 
-- that do not work well with setting signals at clock edge
architecture testbench of tb_atc_shiftReg is
	
	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic;
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 10 ns;
	
	signal enableShift, antitoken, timeout : std_logic;	
	signal tokenLatency : std_logic_vector(2 downto 0);
	
begin

	--assign signals
	setSignals : process
		procedure resetSim is
		begin
			reset <= '1';
			enableShift <= '0';
			antitoken <= '0';
			tokenLatency <= "000";
			wait until rising_edge(clk);
			wait for(3 * CLK_PERIOD / 4);
			reset<='0';
		end procedure resetSim;
	begin
		resetSim;
		if(not finished)then
			tokenLatency <= "010";
			enableShift <= '1';
			antitoken <= '0', '1' after 20 ns, '0' after 30 ns; 
			wait for CLK_PERIOD * 10;
		end if;
	end process;
	
	checkValues : process
	begin
		
	
	--run and stop simulation
	sim : process
	begin
		wait until reset='0';
		wait until rising_edge(clk);
		wait for CLK_PERIOD * 10;
		finished <= true;
	end process;
	
	--instantiate design under test
	--DUT : entity work.antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiToken, tokenLatency, timeout);			--debug
	DUT : entity work.antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiToken, tokenLatency, open,  timeout);
	
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






-- simplified version avoiding the "x <= a, b after [time]" assignments
-- for debugging
architecture simplified of tb_atc_shiftReg is

	signal finished    : boolean := false;
    signal currenttime : time    := 0 ns;	
	signal reset : std_logic;
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 10 ns;
	
	signal enableShift, antitoken, timeout : std_logic;	
	signal tokenLatency : std_logic_vector(2 downto 0);
	signal vect : std_logic_vector(7 downto 0);
	
begin

	sim : process 
	
		procedure reset_sim is
		begin
			reset <= '1';
			enableShift <= '0';
			antitoken <= '0';
			tokenLatency <= "000";
			wait until rising_edge(clk);
			wait for(3 * CLK_PERIOD / 4);
			reset<='0';
		end procedure reset_sim;
		
	begin
		
		reset_sim;
		wait for CLK_PERIOD;
		antitoken <= '1';
		enableShift <= '1';
		tokenLatency <= "011";
		
		wait for CLK_PERIOD * 10;
		
		finished <= true;		
		
	end process sim;

	--instantiate design under test
	--DUT : entity work.antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiToken, tokenLatency, timeout);				--debug
	DUT : entity work.antitokenChannel_shiftRegister port map(clk, reset, enableShift, antiToken, tokenLatency, vect, timeout);
	
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
    
end simple;



