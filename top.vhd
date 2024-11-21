----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/21/2024 09:32:50 PM
-- Design Name: 
-- Module Name: top - Behavioral
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

entity top is
    Port ( CLK_I : in  STD_LOGIC;
    VGA_HS_O : out  STD_LOGIC;
    VGA_VS_O : out  STD_LOGIC;
    VGA_R : out  STD_LOGIC_VECTOR (3 downto 0);
    VGA_B : out  STD_LOGIC_VECTOR (3 downto 0);
    VGA_G : out  STD_LOGIC_VECTOR (3 downto 0);
    led : out  STD_LOGIC_VECTOR (1 downto 0)
    );
end top;

architecture Behavioral of top is

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
        clk_pix : in std_logic;
        rst_pix : in std_logic;
        wb_data : in std_logic_vector(7 downto 0);
        vga_r : out std_logic_vector(1 downto 0);
        vga_g : out std_logic_vector(1 downto 0);
        vga_b : out std_logic_vector(1 downto 0);

        sx : out std_logic_vector(9 downto 0); -- keep open
        sy : out std_logic_vector(9 downto 0); -- keep open

        hsync : out std_logic;
        vsync : out std_logic;

        de : out std_logic -- keep open
        
        ); 
    end component;

    component ppu
    port
    (
        clk : in std_logic;
        rst : in std_logic;

        sync : in std_logic;

        mode : in std_logic_vector(2 downto 0);
        
        data_i : in std_logic_vector(7 downto 0);
        stb_i : in std_logic;
        ack_i : out std_logic;

        data_o : out std_logic_vector(7 downto 0);
        stb_o : out std_logic;
        ack_o : in std_logic
    );
    end component;

    signal clk_pix, sys_rst, ppu_sync, ppu_stb_i, ppu_ack_i, ppu_stb_o, ppu_ack_o : std_logic;
    signal wb_data, ppu_data_i, ppu_data_o : std_logic_vector(7 downto 0);
    signal ppu_mode : std_logic_vector(2 downto 0);
    signal vgr_gen_r, vga_gen_g, vga_gen_b : std_logic_vector(1 downto 0);
    signal ppu_counter : unsigned(3 downto 0) := (others => '0');
    type test_data_t is array(0 to 9) of std_logic_vector(7 downto 0);
    signal test_data : test_data_t := ("00101010", "01111011", "01010111", "11111111", "00000000", "11000110", "01001100", "00100010", "11010010", "10110110");

    type state_t is (IDLE, SEND_DATA, RUN);
    signal state : state_t;
    
begin

    -- reset the system when the clock is not stable
    proceed_reset : process(CLK_I)
    variable clk_count : integer := 0;
    begin
        if rising_edge(CLK_I) then
            if clk_count < 100 then
                sys_rst <= '0';
                clk_count := clk_count + 1;
            else
                sys_rst <= '1';
            end if;
        end if;
    end process;

    clk_div_inst : clk_wiz_0
    port map
    (
        -- Clock in ports
        CLK_IN1 => CLK_I,
        -- Clock out ports
        CLK_OUT1 => clk_pix
    );

    vga_driver_inst : vga_driver
    port map
    (
        clk_pix => clk_pix,
        rst_pix => sys_rst,
        wb_data => wb_data,
        vga_r => vgr_gen_r,
        vga_g => vga_gen_g,
        vga_b => vga_gen_b,
        sx => open,
        sy => open,
        hsync => VGA_HS_O,
        vsync => VGA_VS_O,
        de => open
    );

    -- the dev board has 4 pins but we will only use 2 pins on the chip
    -- so we duplicate the color values
    VGA_R(3 downto 0) <= vgr_gen_r & vgr_gen_r;
    VGA_G(3 downto 0) <= vga_gen_g & vga_gen_g;
    VGA_B(3 downto 0) <= vga_gen_b & vga_gen_b;

    ppu_inst : ppu
    port map
    (
        clk => clk_pix,
        rst => sys_rst,
        sync => ppu_sync,
        mode => ppu_mode,
        data_i => ppu_data_i,
        stb_i => ppu_stb_i,
        ack_i => ppu_ack_i,
        data_o => ppu_data_o,
        stb_o => ppu_stb_o,
        ack_o => ppu_ack_o
    );

    process_fsm : process( clk_pix, sys_rst )
    begin
        if (sys_rst = '0') then
            state <= IDLE;
            ppu_counter <= (others => '0');
            ppu_mode <= "100"; --4 is the mode has interesting pattern
        else
            if rising_edge(clk_pix) then
                if state=IDLE then
                    ppu_data_i <= (others => '0');
                    ppu_stb_i <= '0';
                    state <= SEND_DATA;
                    ppu_sync <= '1';
                elsif state=SEND_DATA then
                    ppu_data_i <= test_data(to_integer(ppu_counter));
                    ppu_stb_i <= '1';

                    if ppu_ack_i = '1' then
                        if ppu_counter = 9 then
                            ppu_counter <= (others => '0');
                            state <= RUN;
                            ppu_sync <= '0';
                        else
                            ppu_counter <= ppu_counter + 1;
                        end if;
                    end if;
                elsif state=RUN then
                    wb_data(7 downto 2) <= ppu_data_o(7 downto 2);
                    ppu_sync <= '0';
                    ppu_ack_o <= '1';
                    ppu_stb_i <= '0';
                end if;
            end if;
                
        end if;
    end process ; -- process_fsm




end Behavioral;
