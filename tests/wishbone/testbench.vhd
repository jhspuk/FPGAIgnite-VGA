library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tb_top is
end tb_top;

architecture Behavioral of tb_top is

    -- Component Declaration for the Unit Under Test (UUT)
    component top
        Port (
            CLK_I     : in  STD_LOGIC;
            VGA_HS_O  : out  STD_LOGIC;
            VGA_VS_O  : out  STD_LOGIC;
            VGA_R     : out  STD_LOGIC_VECTOR (3 downto 0);
            VGA_B     : out  STD_LOGIC_VECTOR (3 downto 0);
            VGA_G     : out  STD_LOGIC_VECTOR (3 downto 0);
            WB_CLK_I  : in  STD_LOGIC;
            WB_RST_I  : in  STD_LOGIC;
            WB_ADR_I  : in  STD_LOGIC_VECTOR(31 downto 0);
            WB_DAT_I  : in  STD_LOGIC_VECTOR(31 downto 0);
            WB_DAT_O  : out STD_LOGIC_VECTOR(31 downto 0);
            WB_WE_I   : in  STD_LOGIC;
            WB_STB_I  : in  STD_LOGIC;
            WB_CYC_I  : in  STD_LOGIC;
            WB_ACK_O  : out STD_LOGIC
        );
    end component;

    -- Signals for driving the UUT
    signal clk        : std_logic := '0';
    signal wb_clk     : std_logic := '0';
    signal reset      : std_logic := '0';
    signal wb_adr     : std_logic_vector(31 downto 0) := (others => '0');
    signal wb_dat_i   : std_logic_vector(31 downto 0) := (others => '0');
    signal wb_dat_o   : std_logic_vector(31 downto 0);
    signal wb_we      : std_logic := '0';
    signal wb_stb     : std_logic := '0';
    signal wb_cyc     : std_logic := '0';
    signal wb_ack     : std_logic;

    signal vga_hs     : std_logic;
    signal vga_vs     : std_logic;
    signal vga_r      : std_logic_vector(3 downto 0);
    signal vga_g      : std_logic_vector(3 downto 0);
    signal vga_b      : std_logic_vector(3 downto 0);

    -- Clock generation
    constant CLK_PERIOD : time := 20 ns;
    constant WB_CLK_PERIOD : time := 40 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: top
        Port map (
            CLK_I     => clk,
            VGA_HS_O  => vga_hs,
            VGA_VS_O  => vga_vs,
            VGA_R     => vga_r,
            VGA_G     => vga_g,
            VGA_B     => vga_b,
            WB_CLK_I  => wb_clk,
            WB_RST_I  => reset,
            WB_ADR_I  => wb_adr,
            WB_DAT_I  => wb_dat_i,
            WB_DAT_O  => wb_dat_o,
            WB_WE_I   => wb_we,
            WB_STB_I  => wb_stb,
            WB_CYC_I  => wb_cyc,
            WB_ACK_O  => wb_ack
        );

    -- Clock process for the main system clock
    clk_process :process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Clock process for the Wishbone clock
    wb_clk_process :process
    begin
        wb_clk <= '0';
        wait for WB_CLK_PERIOD/2;
        wb_clk <= '1';
        wait for WB_CLK_PERIOD/2;
    end process;

    -- Testbench stimulus process
    stim_proc: process
    begin
        -- Initialize inputs
        reset <= '1';
        wait for 100 ns;
        reset <= '0';

        -- Write Red color to VGA
        wb_adr <= x"00000000"; -- Address for Red
        wb_dat_i <= x"0000000F"; -- Full intensity Red
        wb_we <= '1';
        wb_stb <= '1';
        wb_cyc <= '1';
        wait for WB_CLK_PERIOD;
        wb_stb <= '0';
        wb_cyc <= '0';
        wb_we <= '0';

        wait for 100 ns;

        -- Write Green color to VGA
        wb_adr <= x"00000001"; -- Address for Green
        wb_dat_i <= x"0000000F"; -- Full intensity Green
        wb_we <= '1';
        wb_stb <= '1';
        wb_cyc <= '1';
        wait for WB_CLK_PERIOD;
        wb_stb <= '0';
        wb_cyc <= '0';
        wb_we <= '0';

        wait for 100 ns;

        -- Write Blue color to VGA
        wb_adr <= x"00000002"; -- Address for Blue
        wb_dat_i <= x"0000000F"; -- Full intensity Blue
        wb_we <= '1';
        wb_stb <= '1';
        wb_cyc <= '1';
        wait for WB_CLK_PERIOD;
        wb_stb <= '0';
        wb_cyc <= '0';
        wb_we <= '0';

        -- Run simulation for some time
        wait for 1 us;

        -- Stop the simulation
        wait;
    end process;

end Behavioral;

