library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity xor_unit is
    Port (
        in      : in  STD_LOGIC_VECTOR(7 downto 0);  -- 8-bit input
        xor_val : in  STD_LOGIC_VECTOR(3 downto 0);  -- 4-bit XOR value (0 to 15)
        out     : out STD_LOGIC_VECTOR(7 downto 0)   -- 8-bit output after XOR
    );
end xor_unit;

architecture Behavioral of xor_unit is
begin
    -- XOR the input with the XOR value extended to 8 bits
    out <= in xor ("0000" & xor_val);
end Behavioral;

entity xor_parallel is
    Port (
        in      : in  STD_LOGIC_VECTOR(7 downto 0);  
        out0    : out STD_LOGIC_VECTOR(7 downto 0);  
        out1    : out STD_LOGIC_VECTOR(7 downto 0);  
        out2    : out STD_LOGIC_VECTOR(7 downto 0);  
        out3    : out STD_LOGIC_VECTOR(7 downto 0);  
        out4    : out STD_LOGIC_VECTOR(7 downto 0);  
        out5    : out STD_LOGIC_VECTOR(7 downto 0);  
        out6    : out STD_LOGIC_VECTOR(7 downto 0);  
        out7    : out STD_LOGIC_VECTOR(7 downto 0);  
        out8    : out STD_LOGIC_VECTOR(7 downto 0);  
        out9    : out STD_LOGIC_VECTOR(7 downto 0);  
        out10   : out STD_LOGIC_VECTOR(7 downto 0);  
        out11   : out STD_LOGIC_VECTOR(7 downto 0);  
        out12   : out STD_LOGIC_VECTOR(7 downto 0);  
        out13   : out STD_LOGIC_VECTOR(7 downto 0);  
        out14   : out STD_LOGIC_VECTOR(7 downto 0);  
        out15   : out STD_LOGIC_VECTOR(7 downto 0)   
    );
end xor_parallel;

architecture Behavioral of xor_parallel is

    -- Instantiate the 16 XOR units
    component xor_unit
        Port (
            in      : in  STD_LOGIC_VECTOR(7 downto 0);
            xor_val : in  STD_LOGIC_VECTOR(3 downto 0);
            out     : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

begin
    -- Instantiate each XOR unit with a specific XOR value
    u0  : xor_unit port map (in => in, xor_val => "0000", out => out0);
    u1  : xor_unit port map (in => in, xor_val => "0001", out => out1);
    u2  : xor_unit port map (in => in, xor_val => "0010", out => out2);
    u3  : xor_unit port map (in => in, xor_val => "0011", out => out3);
    u4  : xor_unit port map (in => in, xor_val => "0100", out => out4);
    u5  : xor_unit port map (in => in, xor_val => "0101", out => out5);
    u6  : xor_unit port map (in => in, xor_val => "0110", out => out6);
    u7  : xor_unit port map (in => in, xor_val => "0111", out => out7);
    u8  : xor_unit port map (in => in, xor_val => "1000", out => out8);
    u9  : xor_unit port map (in => in, xor_val => "1001", out => out9);
    u10 : xor_unit port map (in => in, xor_val => "1010", out => out10);
    u11 : xor_unit port map (in => in, xor_val => "1011", out => out11);
    u12 : xor_unit port map (in => in, xor_val => "1100", out => out12);
    u13 : xor_unit port map (in => in, xor_val => "1101", out => out13);
    u14 : xor_unit port map (in => in, xor_val => "1110", out => out14);
    u15 : xor_unit port map (in => in, xor_val => "1111", out => out15);

end Behavioral;