----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.08.2024 19:03:09
-- Design Name: 
-- Module Name: vga_driver_test_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_driver_test_top is
    Port ( CLK_I : in  STD_LOGIC;
    VGA_HS_O : out  STD_LOGIC;
    VGA_VS_O : out  STD_LOGIC;
    VGA_R : out  STD_LOGIC_VECTOR (3 downto 0);
    VGA_B : out  STD_LOGIC_VECTOR (3 downto 0);
    VGA_G : out  STD_LOGIC_VECTOR (3 downto 0);
    led : out  STD_LOGIC_VECTOR (1 downto 0)
    );
end vga_driver_test_top;

architecture Behavioral of vga_driver_test_top is
    component clk_wiz_0
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic
 );
end component;
component vga_driver
    port
    (
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
        VGA_G : out  STD_LOGIC_VECTOR (1 downto 0)
        
        ); -- Todo: change to 1 downto 0
    end component;
    
    component wishbone_receiver
        Port ( 
        -- wishbone bus
        CLK_I   : in  std_logic;
        RST_I   : in  std_logic;
        DAT_I   : in  std_logic_vector(7 downto 0);
        STB_I   : in  std_logic;
        ACK_O   : out std_logic;

        -- output to physical VGA driver
        vga_green: out STD_LOGIC_VECTOR(1 downto 0);
        vga_red: out STD_LOGIC_VECTOR (1 downto 0);
        vga_blue: out STD_LOGIC_VECTOR (1 downto 0);
        vga_sync: out std_logic);
    end component;
    
    

    signal pxl_clk : std_logic;
    signal pxl_counter : STD_LOGIC_VECTOR(63 downto 0);
    
        -- Signals from VGA module
    signal vga_red : std_logic_vector(1 downto 0);
    signal vga_green : std_logic_vector(1 downto 0);
    signal vga_blue : std_logic_vector(1 downto 0);
    signal vga_sync:std_logic;
    
    signal wish_bone_data_i : std_logic_vector(7 downto 0);
    signal VGA_HS_O_s: std_logic;
    signal VGA_VS_O_s : std_logic;
begin
    wishbone_receiver_inst : wishbone_receiver
    port map
    (
        CLK_I => pxl_clk, 
        RST_I => '0',
        DAT_I => wish_bone_data_i,
        STB_I => '1',
        ACK_O => open,
        
        vga_green => vga_green,
        vga_red => vga_red,
        vga_blue => vga_blue,
        vga_sync => vga_sync
        
    );
    
    
    clk_div_inst : clk_wiz_0
    port map
    (-- Clock in ports
    CLK_IN1 => CLK_I,
    -- Clock out ports
    CLK_OUT1 => pxl_clk);

    vga_driver_inst : vga_driver
    port map
    (   
--        WB_CLK_I => '1',
--        WB_RST_I => '1',
--        WB_DAT_I => pxl_counter(31 downto 0),
--        WB_DAT_O => open,
        vga_green => vga_green,
        vga_red => vga_red,
        vga_blue => vga_blue,
        vga_sync => vga_sync,

        VGA_CLK_I => pxl_clk,

        VGA_HS_O => VGA_HS_O,
        VGA_VS_O => VGA_VS_O,
        VGA_R => VGA_R(1 downto 0),
        VGA_B => VGA_B(1 downto 0),
        VGA_G => VGA_G(1 downto 0));
        
    VGA_R(3 downto 2) <="00";
    VGA_G(3 downto 2) <="00";
    VGA_B(3 downto 2) <="00";
    
    
    cnt_process : process (pxl_clk)
        variable var_pxl_counter:integer range 0 to 307200;
    begin
        if rising_edge(pxl_clk) then
            var_pxl_counter := var_pxl_counter+1;
            
            if var_pxl_counter>307200 and var_pxl_counter<307202  then
                var_pxl_counter := 0;
                wish_bone_data_i(1 downto 0) <= "11";
            else
                wish_bone_data_i(1 downto 0) <= "00";
            end if;
            
            wish_bone_data_i(7 downto 2) <= std_logic_vector(to_unsigned(var_pxl_counter,32)(5 downto 0));
            
        end if;
    end process cnt_process;
    
    led(0) <= VGA_HS_O_s; 
    led(1) <= VGA_VS_O_s;
    
    VGA_HS_O <= VGA_HS_O_s;
    VGA_VS_O <= VGA_VS_O_s;

end Behavioral;
