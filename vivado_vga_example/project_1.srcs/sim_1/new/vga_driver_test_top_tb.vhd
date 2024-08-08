library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

library xil_defaultlib;
use xil_defaultlib.all;

-----------------------------------------------------------

entity vga_driver_test_top_tb is
port(
    clk : out std_logic
    );
end entity;

-----------------------------------------------------------
architecture rtl of vga_driver_test_top_tb is
    constant C_CLK_PERIOD : time := 10 ns;      
    signal clock : std_logic := '0';
    signal reset : std_logic := '0';

    signal r,g,b : std_logic_vector(3 downto 0);
    signal vga_hs, vga_vs:std_logic;
    
begin
    -----------------------------------------------------------
    -- Clocks and Reset
    -----------------------------------------------------------
    CLK_GEN : process
    begin
        clock <= '1';
        wait for C_CLK_PERIOD/2;
        clock <= '0';
        wait for C_CLK_PERIOD/2;
    end process CLK_GEN;

    RESET_GEN : process
    begin
        reset <= '1',
                 '0' after 20.0*C_CLK_PERIOD;
    wait;
    end process RESET_GEN;

    clk <= clock;

    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------
    test_main : process
    begin
       
        wait;
    end process ; -- test_main

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    uut: entity xil_defaultlib.vga_driver_test_top(Behavioral)
    -- Testbench UUT generics
    port map (
        CLK_I =>clock,
        VGA_HS_O => vga_hs,
        VGA_VS_O => vga_vs,
        VGA_R => r,
        VGA_G => g,
        VGA_B => b
        
    );

end architecture;