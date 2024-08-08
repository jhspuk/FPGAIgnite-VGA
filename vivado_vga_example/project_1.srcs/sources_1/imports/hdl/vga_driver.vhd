entity is
    Port ( 
        -- wishbone bus
        CLK_I   : in  std_logic;
        RST_I   : in  std_logic;
        DAT_I   : in  std_logic_vector(7 downto 0);
        STB_I   : in  std_logic;
        ACK_O   : out std_logic;

        VGA_CLK_I : in  STD_LOGIC;   -- 25Mhz

        -- output to physical VGA connector
        VGA_HS_O : out  STD_LOGIC;
        VGA_VS_O : out  STD_LOGIC;
        VGA_R : out  STD_LOGIC_VECTOR (1 downto 0);
        VGA_B : out  STD_LOGIC_VECTOR (1 downto 0);
        VGA_G : out  STD_LOGIC_VECTOR (1 downto 0));
end top;

architecture Behavioral of top is
    signal received_data : std_logic_vector(7 downto 0);
    signal data_valid : std_logic := '0';
    signal vga_sync : std_logic;
begin

    -- decoding wishbone payload
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            vga_sync <= '1' when received_data(1 downto 0) = "11" else '0';
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