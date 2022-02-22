library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity democore is
   generic (
      CLK_KHZ   : integer := 27000;     -- 25.00 MHz
      PIX_SIZE  : integer := 11;
      H_PIXELS  : integer :=  720;      -- horizontal display width in pixels
      V_PIXELS  : integer :=  576;      -- vertical display width in rows
      H_FP      : integer :=   17;      -- horizontal front porch width in pixels
      H_PULSE   : integer :=   64;      -- horizontal sync pulse width in pixels
      H_BP      : integer :=   63;      -- horizontal back porch width in pixels
      V_FP      : integer :=    5;      -- vertical front porch width in rows
      V_PULSE   : integer :=    5;      -- vertical sync pulse width in rows
      V_BP      : integer :=   39;      -- vertical back porch width in rows
      H_MAX     : integer :=  864;
      V_MAX     : integer :=  625;
      H_POL     : std_logic := '1';       -- horizontal sync pulse polarity (1 = positive, 0 = negative)
      V_POL     : std_logic := '1'        -- vertical sync pulse polarity (1 = positive, 0 = negative)
   );
   port (
      sys_clk_i  : in  std_logic;
      sys_rstn_i : in  std_logic;
      vga_clk_o  : out std_logic;
      vga_r_o    : out std_logic_vector(7 downto 0);
      vga_g_o    : out std_logic_vector(7 downto 0);
      vga_b_o    : out std_logic_vector(7 downto 0);
      vga_hs_o   : out std_logic;
      vga_vs_o   : out std_logic;
      vga_de_o   : out std_logic
   );
end democore;

architecture synthesis of democore is

   signal clkfb         : std_logic;
   signal clkfb_mmcm    : std_logic;
   signal vga_clk_mmcm  : std_logic;

   signal vga_clk : std_logic;

   signal pixel_x : std_logic_vector(PIX_SIZE-1 downto 0) := (others => '0');
   signal pixel_y : std_logic_vector(PIX_SIZE-1 downto 0) := (others => '0');

   constant C_HS_START : integer := H_PIXELS + H_FP;
   constant C_VS_START : integer := V_PIXELS + V_FP;

   constant C_BORDER  : integer := 4;  -- Number of pixels
   constant C_SQ_SIZE : integer := 50; -- Number of pixels

   signal pos_x : integer range 0 to H_PIXELS-1 := H_PIXELS/2;
   signal pos_y : integer range 0 to V_PIXELS-1 := V_PIXELS/2;
   signal vel_x : integer range -7 to 7         := 1;
   signal vel_y : integer range -7 to 7         := 1;

begin

   vga_clk_o <= vga_clk;

   -- VCO frequency range for Artix 7 speed grade -1 : 600 MHz - 1200 MHz
   -- f_VCO = f_CLKIN * CLKFBOUT_MULT_F / DIVCLK_DIVIDE   
   i_clk_vga : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 1,
         CLKFBOUT_MULT_F      => 10.125,    -- f_VCO = (100 MHz / 1) x 10.125 = 1012.5 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 37.500,     -- i_clk @ 27.00 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => clkfb_mmcm,
         CLKOUT0             => vga_clk_mmcm,
         -- Input clock control
         CLKFBIN             => clkfb,
         CLKIN1              => sys_clk_i,
         CLKIN2              => '0',
         -- Tied to always select the primary input clock
         CLKINSEL            => '1',
         -- Ports for dynamic reconfiguration
         DADDR               => (others => '0'),
         DCLK                => '0',
         DEN                 => '0',
         DI                  => (others => '0'),
         DO                  => open,
         DRDY                => open,
         DWE                 => '0',
         -- Ports for dynamic phase shift
         PSCLK               => '0',
         PSEN                => '0',
         PSINCDEC            => '0',
         PSDONE              => open,
         -- Other control and status signals
         LOCKED              => open,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => not sys_rstn_i
      ); -- i_clk_vga


   -------------------------------------
   -- Output buffering
   -------------------------------------

   i_bufg_clkfb : BUFG
      port map (
         I => clkfb_mmcm,
         O => clkfb
      ); -- i_bufg_clkfb

   i_bufg_vga_clk : BUFG
      port map (
         I => vga_clk_mmcm,
         O => vga_clk
      ); -- i_bufg_vga_clk


   -------------------------------------
   -- Generate horizontal pixel counter
   -------------------------------------

   p_pixel_x : process (vga_clk)
   begin
      if rising_edge(vga_clk) then
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

   p_pixel_y : process (vga_clk)
   begin
      if rising_edge(vga_clk) then
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

   p_sync : process (vga_clk)
   begin
      if rising_edge(vga_clk) then
         -- Generate horizontal sync signal
         if unsigned(pixel_x) >= C_HS_START and
            unsigned(pixel_x) < C_HS_START+H_PULSE then

            vga_hs_o <= H_POL;
         else
            vga_hs_o <= not H_POL;
         end if;

         -- Generate vertical sync signal
         if unsigned(pixel_y) >= C_VS_START and
            unsigned(pixel_y) < C_VS_START+V_PULSE then

            vga_vs_o <= V_POL;
         else
            vga_vs_o <= not V_POL;
         end if;

         -- Default is black
         vga_de_o <= '0';

         -- Only show color when inside visible screen area
         if unsigned(pixel_x) < H_PIXELS and
            unsigned(pixel_y) < V_PIXELS then

            vga_de_o <= '1';
         end if;
      end if;
   end process p_sync;


   p_rgb : process (vga_clk)
   begin
      if rising_edge(vga_clk) then
         -- Render background
         vga_r_o <= X"88";
         vga_g_o <= X"CC";
         vga_b_o <= X"AA";

         -- Render white border
         if unsigned(pixel_x) < C_BORDER or unsigned(pixel_x) + C_BORDER >= H_PIXELS or
            unsigned(pixel_y) < C_BORDER or unsigned(pixel_y) + C_BORDER >= V_PIXELS then
            vga_r_o <= X"FF";
            vga_g_o <= X"FF";
            vga_b_o <= X"FF";
         end if;

         -- Render red-ish square
         if unsigned(pixel_x) >= pos_x and unsigned(pixel_x) < pos_x + C_SQ_SIZE and
            unsigned(pixel_y) >= pos_y and unsigned(pixel_y) < pos_y + C_SQ_SIZE then
            vga_r_o <= X"EE";
            vga_g_o <= X"20";
            vga_b_o <= X"40";
         end if;
      end if;
   end process p_rgb;


   -- Move the square
   p_move : process (vga_clk)
   begin
      if rising_edge(vga_clk) then
         -- Update once each frame
         if unsigned(pixel_x) = 0 and unsigned(pixel_y) = 0 then
            pos_x <= pos_x + vel_x;
            pos_y <= pos_y + vel_y;

            if pos_x >= H_PIXELS - C_SQ_SIZE - C_BORDER and vel_x > 0 then
               vel_x <= -vel_x;
            end if;

            if pos_x < C_BORDER and vel_x < 0 then
               vel_x <= -vel_x;
            end if;

            if pos_y >= V_PIXELS - C_SQ_SIZE - C_BORDER and vel_y > 0 then
               vel_y <= -vel_y;
            end if;

            if pos_y < C_BORDER and vel_y < 0 then
               vel_y <= -vel_y;
            end if;
         end if;
      end if;
   end process p_move;

end architecture synthesis;

