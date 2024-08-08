entity  is
    Port ( 
            -- wishbone bus
            WB_CLK_I : in  STD_LOGIC;   --data clock
            WB_RST_I : in  STD_LOGIC;   --reset
            WB_DAT_I : in  STD_LOGIC_VECTOR (31 downto 0); --data
            WB_DAT_O : out  STD_LOGIC_VECTOR (31 downto 0); --data
    
           VGA_CLK_I : in  STD_LOGIC;   --25Mhz

           -- output to physical VGA connector
           VGA_HS_O : out  STD_LOGIC;
           VGA_VS_O : out  STD_LOGIC;
           VGA_R : out  STD_LOGIC_VECTOR (3 downto 0); -- Todo: change to 1 downto 0
           VGA_B : out  STD_LOGIC_VECTOR (3 downto 0); -- Todo: change to 1 downto 0
           VGA_G : out  STD_LOGIC_VECTOR (3 downto 0)); -- Todo: change to 1 downto 0
end top;



architecture Behavioral of top is

begin

-- process
´-- 2bit red, 2bit green, 2bit blue
-- Todo, please convert data from wishbone to RGB

-- orginal vga scan logic

end Behavioral;