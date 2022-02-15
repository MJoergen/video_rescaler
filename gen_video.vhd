library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gen_video is
   generic (
      CLK_KHZ   : integer := 74250;     -- 74.25 MHz
      PIX_SIZE  : integer := 11;
      H_PIXELS  : integer := 1280;      -- horizontal display width in pixels
      V_PIXELS  : integer :=  720;      -- vertical display width in rows
      H_FP      : integer :=  110;      -- horizontal front porch width in pixels
      H_PULSE   : integer :=   40;      -- horizontal sync pulse width in pixels
      H_BP      : integer :=  220;      -- horizontal back porch width in pixels
      V_FP      : integer :=    5;      -- vertical front porch width in rows
      V_PULSE   : integer :=    5;      -- vertical sync pulse width in rows
      V_BP      : integer :=   20;      -- vertical back porch width in rows
      H_MAX     : integer := 1650;
      V_MAX     : integer := 750;
      H_POL     : std_logic := '1';       -- horizontal sync pulse polarity (1 = positive, 0 = negative)
      V_POL     : std_logic := '1'        -- vertical sync pulse polarity (1 = positive, 0 = negative)
   );
   port (
      clk_i : in  std_logic;
      r_o   : out unsigned(7 downto 0);
      g_o   : out unsigned(7 downto 0);
      b_o   : out unsigned(7 downto 0);
      hs_o  : out std_logic;
      vs_o  : out std_logic;
      de_o  : out std_logic
   );
end gen_video;

architecture synthesis of gen_video is

   signal pixel_x : std_logic_vector(PIX_SIZE-1 downto 0) := (others => '0');
   signal pixel_y : std_logic_vector(PIX_SIZE-1 downto 0) := (others => '0');

   constant C_HS_START : integer := H_PIXELS + H_FP;
   constant C_VS_START : integer := V_PIXELS + V_FP;

begin

   -------------------------------------
   -- Generate horizontal pixel counter
   -------------------------------------

   p_pixel_x : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if unsigned(pixel_x) = H_MAX-1 then
            pixel_x <= (others => '0');
         else
            pixel_x <= std_logic_vector(unsigned(pixel_x) + 1);
         end if;
      end if;
   end process p_pixel_x;


   -----------------------------------
   -- Generate vertical pixel counter
   -----------------------------------

   p_pixel_y : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if unsigned(pixel_x) = H_MAX-1 then
            if unsigned(pixel_y) = V_MAX-1 then
               pixel_y <= (others => '0');
            else
               pixel_y <= std_logic_vector(unsigned(pixel_y) + 1);
            end if;
         end if;
      end if;
   end process p_pixel_y;


   -----------------------------------
   -- Generate sync pulses
   -----------------------------------

   p_sync : process (clk_i)
   begin
      if rising_edge(clk_i) then
         -- Generate horizontal sync signal
         if unsigned(pixel_x) >= C_HS_START and
            unsigned(pixel_x) < C_HS_START+H_PULSE then

            hs_o <= H_POL;
         else
            hs_o <= not H_POL;
         end if;

         -- Generate vertical sync signal
         if unsigned(pixel_y) >= C_VS_START and
            unsigned(pixel_y) < C_VS_START+V_PULSE then

            vs_o <= V_POL;
         else
            vs_o <= not V_POL;
         end if;

         -- Default is black
         de_o <= '0';

         -- Only show color when inside visible screen area
         if unsigned(pixel_x) < H_PIXELS and
            unsigned(pixel_y) < V_PIXELS then

            de_o <= '1';
         end if;
      end if;
   end process p_sync;

   p_rgb : process (clk_i)
   begin
      if rising_edge(clk_i) then
         r_o <= to_unsigned(to_integer(unsigned(pixel_x)) mod 256, 8);
         g_o <= to_unsigned(to_integer(unsigned(pixel_y)) mod 256, 8);
         b_o <= to_unsigned(to_integer(unsigned(pixel_x)) + to_integer(unsigned(pixel_y)) mod 256, 8);
      end if;
   end process p_rgb;

end architecture synthesis;

