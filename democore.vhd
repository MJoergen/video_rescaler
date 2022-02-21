library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity democore is
   generic (
      CLK_KHZ   : integer := 25000;     -- 25.00 MHz
      PIX_SIZE  : integer := 11;
      H_PIXELS  : integer :=  640;      -- horizontal display width in pixels
      V_PIXELS  : integer :=  480;      -- vertical display width in rows
      H_FP      : integer :=   16;      -- horizontal front porch width in pixels
      H_PULSE   : integer :=   96;      -- horizontal sync pulse width in pixels
      H_BP      : integer :=   48;      -- horizontal back porch width in pixels
      V_FP      : integer :=   10;      -- vertical front porch width in rows
      V_PULSE   : integer :=    2;      -- vertical sync pulse width in rows
      V_BP      : integer :=   33;      -- vertical back porch width in rows
      H_MAX     : integer :=  800;
      V_MAX     : integer :=  525;
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
         DIVCLK_DIVIDE        => 5,
         CLKFBOUT_MULT_F      => 37.125,     -- f_VCO = (100 MHz / 5) x 37.125 = 742.5 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 29.500,     -- i_clk @ 25.17 MHz
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
         vga_r_o <= std_logic_vector(to_unsigned(to_integer(unsigned(pixel_x)) mod 256, 8));
         vga_g_o <= std_logic_vector(to_unsigned(to_integer(unsigned(pixel_y)) mod 256, 8));
         vga_b_o <= std_logic_vector(to_unsigned(to_integer(unsigned(pixel_x)) + to_integer(unsigned(pixel_y)) mod 256, 8));
      end if;
   end process p_rgb;

end architecture synthesis;

