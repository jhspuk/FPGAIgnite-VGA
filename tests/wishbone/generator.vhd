----------------------------------------------------------------------------------
-- Company: ExampleCorp
-- Engineer: Your Name
-- 
-- Create Date:    08/08/2024 
-- Project Name:   SimpleVGA
-- Target Devices: Artix-7
-- Tool versions:  Vivado 2023.1
-- Description:    Simple VGA Pattern Generator
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SimpleVGA is
    Port ( 
           CLK_I     : in  STD_LOGIC;
           VGA_HS_O  : out  STD_LOGIC;
           VGA_VS_O  : out  STD_LOGIC;
           VGA_R     : out  STD_LOGIC_VECTOR (3 downto 0);
           VGA_B     : out  STD_LOGIC_VECTOR (3 downto 0);
           VGA_G     : out  STD_LOGIC_VECTOR (3 downto 0)
           );
end SimpleVGA;

architecture Behavioral of SimpleVGA is

-- VGA Sync Generation constants for 640x480 @ 60Hz
constant FRAME_WIDTH  : natural := 640;
constant FRAME_HEIGHT : natural := 480;

constant H_FP  : natural := 16;  -- H front porch width (pixels)
constant H_PW  : natural := 96;  -- H sync pulse width (pixels)
constant H_MAX : natural := 800; -- H total period (pixels)

constant V_FP  : natural := 10;  -- V front porch width (lines)
constant V_PW  : natural := 2;   -- V sync pulse width (lines)
constant V_MAX : natural := 525; -- V total period (lines)

constant H_POL : std_logic := '0';
constant V_POL : std_logic := '0';

signal pxl_clk : std_logic;
signal active  : std_logic;

signal h_cntr_reg : std_logic_vector(9 downto 0) := (others =>'0');
signal v_cntr_reg : std_logic_vector(9 downto 0) := (others =>'0');

signal h_sync_reg : std_logic := not(H_POL);
signal v_sync_reg : std_logic := not(V_POL);

signal h_sync_dly_reg : std_logic := not(H_POL);
signal v_sync_dly_reg : std_logic := not(V_POL);

signal vga_red_reg   : std_logic_vector(3 downto 0) := (others =>'0');
signal vga_green_reg : std_logic_vector(3 downto 0) := (others =>'0');
signal vga_blue_reg  : std_logic_vector(3 downto 0) := (others =>'0');

begin

-- Assume an external 25 MHz clock for 640x480 @ 60Hz
pxl_clk <= CLK_I;

------------------------------------------------------
-- Simple Pattern Generation Logic
------------------------------------------------------
process (pxl_clk)
begin
    if (rising_edge(pxl_clk)) then
        if active = '1' then
            if h_cntr_reg < FRAME_WIDTH/2 then
                if v_cntr_reg < FRAME_HEIGHT/2 then
                    -- Top-left quadrant: Red
                    vga_red_reg <= "1111";
                    vga_green_reg <= "0000";
                    vga_blue_reg <= "0000";
                else
                    -- Bottom-left quadrant: Green
                    vga_red_reg <= "0000";
                    vga_green_reg <= "1111";
                    vga_blue_reg <= "0000";
                end if;
            else
                if v_cntr_reg < FRAME_HEIGHT/2 then
                    -- Top-right quadrant: Blue
                    vga_red_reg <= "0000";
                    vga_green_reg <= "0000";
                    vga_blue_reg <= "1111";
                else
                    -- Bottom-right quadrant: Black
                    vga_red_reg <= "0000";
                    vga_green_reg <= "0000";
                    vga_blue_reg <= "0000";
                end if;
            end if;
        else
            vga_red_reg <= "0000";
            vga_green_reg <= "0000";
            vga_blue_reg <= "0000";
        end if;
    end if;
end process;

------------------------------------------------------
-- VGA Sync Generation Logic
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
    if rising_edge(pxl_clk) then
        v_sync_dly_reg <= v_sync_reg;
        h_sync_dly_reg <= h_sync_reg;
    end if;
end process;

VGA_HS_O <= h_sync_dly_reg;
VGA_VS_O <= v_sync_dly_reg;
VGA_R    <= vga_red_reg;
VGA_G    <= vga_green_reg;
VGA_B    <= vga_blue_reg;

end Behavioral;

