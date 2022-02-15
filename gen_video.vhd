library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gen_video is
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

architecture structural of gen_video is

   -- Define constants used for 640x480 @ 60 Hz.
   -- Requires a clock of 25.175 MHz.
   -- See page 17 in "VESA MONITOR TIMING STANDARD"
   -- http://caxapa.ru/thumbs/361638/DMTv1r11.pdf
   constant H_PIXELS : integer := 640;
   constant V_PIXELS : integer := 480;

   constant H_TOTAL  : integer := 800;
   constant HS_START : integer := 656;
   constant HS_TIME  : integer := 96;

   constant V_TOTAL  : integer := 525;
   constant VS_START : integer := 490;
   constant VS_TIME  : integer := 2;

   -- Pixel counters
   signal pix_x : integer range 0 to H_TOTAL;
   signal pix_y : integer range 0 to V_TOTAL;

begin

   --------------------------------------------------
   -- Generate horizontal and vertical pixel counters
   --------------------------------------------------

   p_pix_x : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if pix_x = H_TOTAL-1 then
            pix_x <= 0;
         else
            pix_x <= pix_x + 1;
         end if;
      end if;
   end process p_pix_x;

   p_pix_y : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if pix_x = H_TOTAL-1  then
            if pix_y = V_TOTAL-1 then
               pix_y <= 0;
            else
               pix_y <= pix_y + 1;
            end if;
         end if;
      end if;
   end process p_pix_y;


   --------------------------------------------------
   -- Generate horizontal sync signal
   --------------------------------------------------

   p_hs : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if pix_x >= HS_START and pix_x < HS_START+HS_TIME then
            hs_o <= '0';
         else
            hs_o <= '1';
         end if;
      end if;
   end process p_hs;


   --------------------------------------------------
   -- Generate vertical sync signal
   --------------------------------------------------

   p_vs : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if pix_y >= VS_START and pix_y < VS_START+VS_TIME then
            vs_o <= '0';
         else
            vs_o <= '1';
         end if;
      end if;
   end process p_vs;


   --------------------------------------------------
   -- Generate pixel colour
   --------------------------------------------------

   p_rgb : process (clk_i)
   begin
      if rising_edge(clk_i) then

         -- Generate checker board pattern
         if ((pix_x + pix_y) mod 7) = 1 then
            r_o <= X"FF";
            g_o <= X"FF";
            b_o <= X"FF";
         else
            r_o <= X"00";
            g_o <= X"00";
            b_o <= X"00";
         end if;

         -- Make sure colour is black outside the visible area.
         if pix_x >= H_PIXELS or pix_y >= V_PIXELS then
            r_o <= X"00";
            g_o <= X"00";
            b_o <= X"00";
            de_o <= '0';
         else
            de_o <= '1';
         end if;
      end if;
   end process p_rgb;

end architecture structural;

