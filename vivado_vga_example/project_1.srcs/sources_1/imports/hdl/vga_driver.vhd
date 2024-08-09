library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity vga_driver is
    Port ( 
        -- wishbone bus
        vga_green: in STD_LOGIC_VECTOR(1 downto 0);
        vga_red: in STD_LOGIC_VECTOR (1 downto 0);
        vga_blue: in STD_LOGIC_VECTOR (1 downto 0);
        vga_sync: in std_logic;
        
        VGA_CLK_I : in  STD_LOGIC;   --25Mhz
        
        -- output to physical VGA connector
        VGA_HS_O : out  STD_LOGIC;
        VGA_VS_O : out  STD_LOGIC;
        VGA_R : out  STD_LOGIC_VECTOR (1 downto 0); -- Todo: change to 1 downto 0
        VGA_B : out  STD_LOGIC_VECTOR (1 downto 0); -- Todo: change to 1 downto 0
        VGA_G : out  STD_LOGIC_VECTOR (1 downto 0)); -- Todo: change to 1 downto 0
end vga_driver;


architecture Behavioral of vga_driver is


    
    --Sync Generation constants
    
    --***640x480@60Hz***--  Requires 25 MHz clock
    constant FRAME_WIDTH : natural := 640;
    constant FRAME_HEIGHT : natural := 480;
    
    constant H_FP : natural := 16; --H front porch width (pixels)
    constant H_PW : natural := 96; --H sync pulse width (pixels)
    constant H_MAX : natural := 800; --H total period (pixels)
    
    constant V_FP : natural := 10; --V front porch width (lines)
    constant V_PW : natural := 2; --V sync pulse width (lines)
    constant V_MAX : natural := 525; --V total period (lines)
    
    constant H_POL : std_logic := '0';
    constant V_POL : std_logic := '0';
    
    signal pxl_clk : std_logic;
    signal active : std_logic;
    
    signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
    signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
    
    signal h_sync_reg : std_logic := not(H_POL);
    signal v_sync_reg : std_logic := not(V_POL);
    
    signal h_sync_dly_reg : std_logic := not(H_POL);
    signal v_sync_dly_reg : std_logic :=  not(V_POL);
    
    signal vga_red_reg : std_logic_vector(1 downto 0) := (others =>'0');
    signal vga_green_reg : std_logic_vector(1 downto 0) := (others =>'0');
    signal vga_blue_reg : std_logic_vector(1 downto 0) := (others =>'0');
    
    begin
      
       
    pxl_clk <= VGA_CLK_I;
      

--    vga_red <= WB_DAT_I(3 downto 0);
--    vga_green <= WB_DAT_I(7 downto 4);
--    vga_blue <= WB_DAT_I(7 downto 4);--std_logic_vector(unsigned((v_cntr_reg(6 downto 3) + box_x_reg(6 downto 3)) xor h_cntr_reg(6 downto 3)));
    

     ------------------------------------------------------
     -------         SYNC GENERATION                 ------
     ------------------------------------------------------
     
      process (pxl_clk)
      begin
        if (rising_edge(pxl_clk)) then
--          if ((h_cntr_reg = (H_MAX - 1))) then 
          if ((h_cntr_reg = (H_MAX - 1)) or vga_sync='1') then
            h_cntr_reg <= (others =>'0');
          else
            h_cntr_reg <= h_cntr_reg + 1;
          end if;
        end if;
      end process;
      
      process (pxl_clk)
      begin
        if (rising_edge(pxl_clk)) then
--          if (((h_cntr_reg = (H_MAX - 1)) and (v_cntr_reg = (V_MAX - 1))) or vga_sync='1') then
          if (((h_cntr_reg = (H_MAX - 1)) and (v_cntr_reg = (V_MAX - 1))) or vga_sync='1') then
            v_cntr_reg <= (others =>'0');
          elsif (h_cntr_reg = (H_MAX - 1)) then
            v_cntr_reg <= v_cntr_reg + 1;
          end if;
        end if;
      end process;
      
      process (pxl_clk)
      begin
        if (rising_edge(pxl_clk)) then
          if (h_cntr_reg >= (H_FP + FRAME_WIDTH - 1)) and (h_cntr_reg < (H_FP + FRAME_WIDTH + H_PW - 1)) then
            h_sync_reg <= H_POL;
          else
            h_sync_reg <= not(H_POL);
          end if;
        end if;
      end process;
      
      
      process (pxl_clk)
      begin
        if (rising_edge(pxl_clk)) then
          if (v_cntr_reg >= (V_FP + FRAME_HEIGHT - 1)) and (v_cntr_reg < (V_FP + FRAME_HEIGHT + V_PW - 1)) then
            v_sync_reg <= V_POL;
          else
            v_sync_reg <= not(V_POL);
          end if;
        end if;
      end process;
    
      process (pxl_clk)
      begin
        if (rising_edge(pxl_clk)) then
          v_sync_dly_reg <= v_sync_reg;
          h_sync_dly_reg <= h_sync_reg;
          vga_red_reg <= vga_red;
          vga_green_reg <= vga_green;
          vga_blue_reg <= vga_blue;
        end if;
      end process;
    
      VGA_HS_O <= h_sync_dly_reg;
      VGA_VS_O <= v_sync_dly_reg;
      VGA_R <= vga_red_reg;
      VGA_G <= vga_green_reg;
      VGA_B <= vga_blue_reg;
    
    end Behavioral;
    