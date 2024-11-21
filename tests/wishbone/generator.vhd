library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top_level is
    Port ( 
           CLK_I     : in  STD_LOGIC;
           VGA_HS_O  : out  STD_LOGIC;
           VGA_VS_O  : out  STD_LOGIC;
           VGA_R     : out  STD_LOGIC_VECTOR (3 downto 0);
           VGA_B     : out  STD_LOGIC_VECTOR (3 downto 0);
           VGA_G     : out  STD_LOGIC_VECTOR (3 downto 0)
           );
end top_level;

architecture Behavioral of top_level is

component vga_controller
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

-- Clock signal for Wishbone
signal WB_CLK : std_logic;
-- Reset signal for Wishbone
signal WB_RST : std_logic := '0';

-- Wishbone signals
signal WB_ADR  : std_logic_vector(31 downto 0) := (others => '0');
signal WB_DAT_I: std_logic_vector(31 downto 0) := (others => '0');
signal WB_DAT_O: std_logic_vector(31 downto 0);
signal WB_WE   : std_logic := '0';
signal WB_STB  : std_logic := '0';
signal WB_CYC  : std_logic := '0';
signal WB_ACK  : std_logic;

-- Test pattern signals
signal pattern_state : integer range 0 to 3 := 0;
signal pattern_count : integer range 0 to 255 := 0;

begin

-- Instance of the VGA controller
vga_inst : vga_controller
    port map (
           CLK_I     => CLK_I,
           VGA_HS_O  => VGA_HS_O,
           VGA_VS_O  => VGA_VS_O,
           VGA_R     => VGA_R,
           VGA_B     => VGA_B,
           VGA_G     => VGA_G,
           WB_CLK_I  => WB_CLK,
           WB_RST_I  => WB_RST,
           WB_ADR_I  => WB_ADR,
           WB_DAT_I  => WB_DAT_I,
           WB_DAT_O  => WB_DAT_O,
           WB_WE_I   => WB_WE,
           WB_STB_I  => WB_STB,
           WB_CYC_I  => WB_CYC,
           WB_ACK_O  => WB_ACK
    );

-- Clock process for Wishbone clock
WB_CLK_GEN : process
begin
    WB_CLK <= '0';
    wait for 10 ns;
    WB_CLK <= '1';
    wait for 10 ns;
end process;

-- Test pattern generator
test_pattern : process(WB_CLK)
begin
    if rising_edge(WB_CLK) then
        if pattern_count = 255 then
            pattern_count <= 0;
            pattern_state <= (pattern_state + 1) mod 4;
        else
            pattern_count <= pattern_count + 1;
        end if;

        -- Generate Wishbone transactions to write color values
        WB_CYC <= '1';
        WB_STB <= '1';
        WB_WE <= '1';

        case pattern_state is
            when 0 =>  -- Red
                WB_ADR <= x"00000000";
                WB_DAT_I <= x"0000000F";  -- Max value for 4-bit color
            when 1 =>  -- Green
                WB_ADR <= x"00000001";
                WB_DAT_I <= x"0000000F";
            when 2 =>  -- Blue
                WB_ADR <= x"00000002";
                WB_DAT_I <= x"0000000F";
            when others =>  -- Black (or any other color)
                WB_ADR <= x"00000000";
                WB_DAT_I <= x"00000000";
        end case;

        if WB_ACK = '1' then
            WB_CYC <= '0';
            WB_STB <= '0';
            WB_WE <= '0';
        end if;
    end if;
end process;

end Behavioral;

