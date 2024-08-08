library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity wishbone_receiver is
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
end wishbone_receiver;

architecture Behavioral of wishbone_receiver is
    signal received_data : std_logic_vector(7 downto 0) := "00000000";
    signal data_valid : std_logic := '0';
    
begin

    -- decoding wishbone payload
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
--            vga_sync <= '1' when received_data(1 downto 0) = "11" else '0';

            if received_data(1 downto 0) = "11" then
                vga_sync<= '1';
            else
                vga_sync<= '0';
            end if;
            
            if RST_I = '1' then
                ACK_O <= '0';
                received_data <= (others => '0');
                data_valid <= '0';
            else
                if STB_I = '1' then
                    -- Receive data
                    received_data <= DAT_I;
                    data_valid <= '1';
                    ACK_O <= '1';
                else
                    ACK_O <= '0';
                    data_valid <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Process to use the received data
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if data_valid = '1' then
                vga_red <= received_data(7 downto 6);
                vga_green <= received_data(5 downto 4);
                vga_blue <= received_data(3 downto 2);
            end if;
        end if;
    end process;

end Behavioral;