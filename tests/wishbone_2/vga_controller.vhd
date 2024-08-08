library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

entity vga_controller is
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
end vga_controller;

architecture Behavioral of vga_controller is

-- Sync Generation constants
constant FRAME_WIDTH  : natural := 1920;
constant FRAME_HEIGHT : natural := 1080;

constant H_FP  : natural := 88;  -- H front porch width (pixels)
constant H_PW  : natural := 44;  -- H sync pulse width (pixels)
constant H_MAX : natural := 2200;-- H total period (pixels)

constant V_FP  : natural := 4;   -- V front porch width (lines)
constant V_PW  : natural := 5;   -- V sync pulse width (lines)
constant V_MAX : natural := 1125;-- V total period (lines)

constant H_POL : std_logic := '1';
constant V_POL : std_logic := '1';

signal pxl_clk : std_logic;
signal active  : std_logic;

signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');

signal h_sync_reg : std_logic := not(H_POL);
signal v_sync_reg : std_logic := not(V_POL);

signal h_sync_dly_reg : std_logic := not(H_POL);
signal v_sync_dly_reg : std_logic := not(V_POL);

signal vga_red_reg   : std_logic_vector(3 downto 0) := (others =>'0');
signal vga_green_reg : std_logic_vector(3 downto 0) := (others =>'0');
signal vga_blue_reg  : std_logic_vector(3 downto 0) := (others =>'0');

signal vga_red   : std_logic_vector(3 downto 0);
signal vga_green : std_logic_vector(3 downto 0);
signal vga_blue  : std_logic_vector(3 downto 0);

-- Wishbone signals
signal wb_ack : std_logic := '0';

begin

clk_div_inst : clk_wiz_0
  port map (
    CLK_IN1  => CLK_I,
    CLK_OUT1 => pxl_clk
  );

------------------------------------------------------
-- Wishbone Read/Write Logic
------------------------------------------------------
process (WB_CLK_I)
begin
  if rising_edge(WB_CLK_I) then
    if WB_RST_I = '1' then
      -- reset logic
      wb_ack <= '0';
      vga_red <= (others => '0');
      vga_green <= (others => '0');
      vga_blue <= (others => '0');
    else
      if WB_STB_I = '1' and WB_CYC_I = '1' then
        if WB_WE_I = '1' then  -- Write operation
          case WB_ADR_I(3 downto 0) is
            when "0000" =>
              vga_red <= WB_DAT_I(3 downto 0);
            when "0001" =>
              vga_green <= WB_DAT_I(3 downto 0);
            when "0010" =>
              vga_blue <= WB_DAT_I(3 downto 0);
            when others =>
              null;
          end case;
          wb_ack <= '1';
        else  -- Read operation
          case WB_ADR_I(3 downto 0) is
            when "0000" =>
              WB_DAT_O(3 downto 0) <= vga_red;
            when "0001" =>
              WB_DAT_O(3 downto 0) <= vga_green;
            when "0010" =>
              WB_DAT_O(3 downto 0) <= vga_blue;
            when others =>
              WB_DAT_O <= (others => '0');
          end case;
          wb_ack <= '1';
        end if;
      else
        wb_ack <= '0';
      end if;
    end if;
  end if;
end process;

WB_ACK_O <= wb_ack;

------------------------------------------------------
-- Sync Generation Logic
------------------------------------------------------
process (pxl_clk)
begin
  if rising_edge(pxl_clk) then
    if (h_cntr_reg = (H_MAX - 1)) then
      h_cntr_reg <= (others =>'0');
    else
      h_cntr_reg <= h_cntr_reg + 1;
    end if;
  end if;
end process;

process (pxl_clk)
begin
  if rising_edge(pxl_clk) then
    if ((h_cntr_reg = (H_MAX - 1)) and (v_cntr_reg = (V_MAX - 1))) then
      v_cntr_reg <= (others =>'0');
    elsif (h_cntr_reg = (H_MAX - 1)) then
      v_cntr_reg <= v_cntr_reg + 1;
    end if;
  end if;
end process;

process (pxl_clk)
begin
  if rising_edge(pxl_clk) then
    if (h_cntr_reg >= (H_FP + FRAME_WIDTH - 1)) and (h_cntr_reg < (H_FP + FRAME_WIDTH + H_PW - 1)) then
      h_sync_reg <= H_POL;
    else
      h_sync_reg <= not(H_POL);
    end if;
  end if;
end process;

process (pxl_clk)
begin
  if rising_edge(pxl_clk) then
    if (v_cntr_reg >= (V_FP + FRAME_HEIGHT - 1)) and (v_cntr_reg < (V_FP + FRAME_HEIGHT + V_PW - 1)) then
      v_sync_reg <= V_POL;
    else
      v_sync_reg <= not(V_POL);
    end if;
  end if;
end process;

active <= '1' when ((h_cntr_reg < FRAME_WIDTH) and (v_cntr_reg < FRAME_HEIGHT)) else
          '0';

process (pxl_clk)
begin
  if (rising_edge(pxl_clk)) then
    v_sync_dly_reg <= v_sync_reg;
    h_sync_dly_reg <= h_sync_reg;
    vga_red_reg    <= vga_red;
    vga_green_reg  <= vga_green;
    vga_blue_reg   <= vga_blue;
  end if;
end process;

VGA_HS_O <= h_sync_dly_reg;
VGA_VS_O <= v_sync_dly_reg;
VGA_R    <= vga_red_reg;
VGA_G    <= vga_green_reg;
VGA_B    <= vga_blue_reg;

end Behavioral;

