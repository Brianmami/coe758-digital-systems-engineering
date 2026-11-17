--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:15:56 10/19/2025
-- Design Name:   
-- Module Name:   /home/student2/dnserran/COE758/Project1/CacheSystem_TB.vhd
-- Project Name:  Project1
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: CacheController
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

entity CacheSystem_TB is
	Port (
		clk : in STD_LOGIC;
		rst : in STD_LOGIC
	);
end CacheSystem_TB;

architecture Behavioral of CacheSystem_TB is
	Component CPU_gen is
		Port ( 
			clk 		: in  STD_LOGIC;
			rst 		: in  STD_LOGIC;
			trig 		: in  STD_LOGIC;
			
			-- Interface to the Cache Controller.
			Address 	: out  STD_LOGIC_VECTOR (15 downto 0);
			wr_rd 	: out  STD_LOGIC;
			cs 		: out  STD_LOGIC;
			DOut 		: out  STD_LOGIC_VECTOR (7 downto 0)
		);
	end component;

	component CacheController is
		Port (
			clk		   : in  STD_LOGIC;
			rst			: in  STD_LOGIC;
			Add_in      : in  STD_LOGIC_VECTOR (15 downto 0);
			Wr_in	      : in  STD_LOGIC;
			CS          : in  STD_LOGIC;
			Add_out     : out STD_LOGIC_VECTOR (15 downto 0);
			Wr_out      : out STD_LOGIC;
			MSTRB       : out STD_LOGIC;
			Din_s       : out STD_LOGIC;
			Dout_s      : out STD_LOGIC;
			Wen         : out STD_LOGIC;
			Add_Cache   : out STD_LOGIC_VECTOR (7 downto 0);
			Next_state  : out STD_LOGIC_VECTOR (2 downto 0);
			RDY 			: out STD_LOGIC;
			dBit			: out STD_LOGIC
		);
	end component;

	component SRAM is
		Port ( clk : in  STD_LOGIC;
			wen : in  STD_LOGIC;
			AddrIn : in  STD_LOGIC_VECTOR (7 downto 0);
			CPU_Din : in  STD_LOGIC_VECTOR (7 downto 0);
			SDRAM_Din : in  STD_LOGIC_VECTOR (7 downto 0);
			CPU_Dout : out  STD_LOGIC_VECTOR (7 downto 0);
			SDRAM_Dout : out  STD_LOGIC_VECTOR (7 downto 0);
			DinControl : in  STD_LOGIC;
			DoutControl : in  STD_LOGIC
		);
	end component;

	Component SDRAMController is
		Port ( clk   : in  STD_LOGIC;
			Add  : in  STD_LOGIC_VECTOR (15 downto 0);
			Wr  : in  STD_LOGIC; 
			MSTRB : in  STD_LOGIC;  -- Strobe signal for memory access
			Din   : in  STD_LOGIC_VECTOR (7 downto 0);
			Dout  : out  STD_LOGIC_VECTOR (7 downto 0)
		);
	end component;
	
	-- ChipScope
	component icon
		Port (
			control0: inout STD_LOGIC_VECTOR(35 downto 0)
		);
	end component;
	
	component ila
		Port (
			CONTROL : inout STD_LOGIC_VECTOR(35 downto 0);
			CLK : in STD_LOGIC;
			DATA : in STD_LOGIC_VECTOR(57 downto 0);
			TRIG0 : in STD_LOGIC_VECTOR(7 downto 0)
		);
	end component;
	
	-- CPU to Cache Controller Interface
	signal cpu_address : STD_LOGIC_VECTOR (15 downto 0);
	signal cpu_wr_rd	 : STD_LOGIC;
	signal cpu_cs	    : STD_LOGIC;
	signal cpu_dout	 : STD_LOGIC_VECTOR (7 downto 0);
	signal cpu_din		 : STD_LOGIC_VECTOR (7 downto 0);
	signal cache_rdy	 : STD_LOGIC := '0';
	
	-- Cache Controller to SDRAM Controller Interface
	signal cache_to_sdram_add   : STD_LOGIC_VECTOR (15 downto 0);
	signal cache_to_sdram_wr    : STD_LOGIC;
	signal cache_to_sdram_mstrb : STD_LOGIC;
	
	-- Cache Controller to local SRAM selector signals
	signal cache_din_s  : STD_LOGIC;
	signal cache_dout_s : STD_LOGIC;
	signal cache_wen	  : STD_LOGIC;
	signal cache_add	  : STD_LOGIC_VECTOR(7 downto 0);
	
	-- Data Path Signals 
	signal sdram_to_cache : STD_LOGIC_VECTOR (7 downto 0);
	signal cache_to_sdram : STD_LOGIC_VECTOR (7 downto 0);
	
	--Signal that gives visibility to the state of the cache controller
	signal state_out : STD_LOGIC_VECTOR (2 downto 0);
	
	signal control0 : STD_LOGIC_VECTOR (35 downto 0);
	signal ila_data : STD_LOGIC_VECTOR (57 downto 0);
	signal trig0 : STD_LOGIC_VECTOR (7 downto 0);
	
	signal clk_counter : STD_LOGIC := '0';  -- ADD THIS LINE HERE
	
	-- Clock period definition (100 MHz clock frequency)
	constant clk_period : time := 10 ns;
	
	-- Simulation flag to stop the clock when simulation is complete
	signal sim_done : boolean := false;
	signal dirtyBit : STD_LOGIC;
	
begin
	process(clk)
	begin
		if rising_edge(clk) then
			clk_counter <= not clk_counter;
		end if;
	end process;
	
	--ChipScope instances
	icon_inst : icon
	port map(
		CONTROL0 => control0
	);
	
	ila_inst : ila
	port map (
		CONTROL => control0,
		CLK => clk,
		DATA => ila_data,
		TRIG0 => trig0
	);
	ila_data(57 downto 42) <= cache_to_sdram_add;
	ila_data(41) <= dirtyBit;
	ila_data(40) <= clk_counter;
	ila_data(39 downto 32) <= cpu_dout;
	ila_data(31 downto 16) <= cpu_address;
	ila_data(15 downto 13) <= state_out;
	ila_data(12) <= cpu_cs;
	ila_data(11) <= cpu_wr_rd;
	ila_data(10) <= cache_rdy;
	ila_data(9) <= cache_to_sdram_mstrb;
	ila_data(8) <= cache_wen;
	ila_data(7) <= cache_dout_s;
	ila_data(6) <= cache_din_s;
	ila_data(5 downto 0) <= cache_add(5 downto 0);

	
	trig0(0) <= cpu_cs;
	trig0(1) <= cpu_wr_rd;
	trig0(2) <= cache_rdy;
	trig0(3) <= cache_to_sdram_mstrb;
	trig0(6 downto 4) <= state_out;
	trig0(7) <= '0';
	
	
	-- CPU generator instantiation
	-- Simulates cpu by generating pre-defined test patterns
	cpu_generator : CPU_gen
	port map (
		-- Clock and control signals
		clk  => clk,
		rst  => rst,
		trig => cache_rdy,
		
		-- Outputs to the cache controller
		Address => cpu_address,
		wr_rd   => cpu_wr_rd,
		cs	 	  => cpu_cs,
		DOut	  => cpu_dout
	);
	
	--Cache controller instantiation
	cache_ctrl : CacheController
	port map (
		clk => clk,
		rst => rst,
		
		-- CPU interface (inputs from CPU_gen)
		Add_in => cpu_address,
		Wr_in  => cpu_wr_rd,
		CS	    => cpu_cs,
		
		-- SDRAM interface (outputs to SDRAM controller)
		Add_out => cache_to_sdram_add,
		Wr_out  => cache_to_sdram_wr,
		MSTRB	  => cache_to_sdram_mstrb,
		
		-- SRAM control (outputs to cache memory)
		Din_s     => cache_din_s,
		Dout_s    => cache_dout_s,
		Wen	    => cache_wen,
		Add_cache => cache_add,
		
		-- Status outputs
		Next_state => state_out, -- Shows what state we are in
		RDY 	     => cache_rdy,  -- Ready signal to CPU
		dBit 		  => dirtyBit
	);
	
	-- SRAM instance
	cache_sram : SRAM
	port map (
		clk => clk,
		
		-- Control inputs from cache controller
		wen 	 => cache_wen,
		AddrIn => cache_add,
		
		-- Data inputs
		CPU_Din	 => cpu_dout, -- Data to CPU (cache read)
		SDRAM_Din => sdram_to_cache, -- Data to SDRAM (block writeback)
		
		-- Data outputs 
		CPU_Dout   => cpu_din,
		SDRAM_Dout => cache_to_sdram,
		
		-- Selectors from cache controller
		DinControl  => cache_din_s,
		DoutControl => cache_dout_s
	);
	
	-- SDRAM Controller instance (main mem)
	sdram_ctrl : SDRAMController
	port map (
		clk => clk,
		
		-- Control and address inputs from cache controller
		Add   => cache_to_sdram_add,
		Wr    => cache_to_sdram_wr,
		MSTRB => cache_to_sdram_mstrb,
		
		-- Data ports
		Din  => cache_to_sdram,
		Dout => sdram_to_cache
	);
end Behavioral;