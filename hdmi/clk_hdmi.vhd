library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity clk_hdmi is
   port (
      sys_clk_i  : in  std_logic;   -- expects 100 MHz
      sys_rstn_i : in  std_logic;   -- Asynchronous, asserted low
      i_clk_o    : out std_logic;   -- 25.17 MHz
      o_clk_o    : out std_logic;   -- 74.25 MHz pixelclock for 720p @ 60 Hz
      hdmi_clk_o : out std_logic;   -- pixelclock (74.25 MHz x 5 = 371.25 MHz) for HDMI
      locked_o   : out std_logic
   );
end entity clk_hdmi;

architecture synthesis of clk_hdmi is

   signal clkfb         : std_logic;
   signal clkfb_mmcm    : std_logic;
   signal i_clk_mmcm    : std_logic;
   signal o_clk_mmcm    : std_logic;
   signal hdmi_clk_mmcm : std_logic;

begin

   -- VCO frequency range for Artix 7 speed grade -1 : 600 MHz - 1200 MHz
   -- f_VCO = f_CLKIN * CLKFBOUT_MULT_F / DIVCLK_DIVIDE   
   i_clk_hdmi : MMCME2_ADV
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
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKOUT1_DIVIDE       => 10,         -- o_clk @ 74.25 MHz
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE,
         CLKOUT2_DIVIDE       => 2,          -- hdmi_clk @ 371.25 MHz
         CLKOUT2_PHASE        => 0.000,
         CLKOUT2_DUTY_CYCLE   => 0.500,
         CLKOUT2_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => clkfb_mmcm,
         CLKOUT0             => i_clk_mmcm,
         CLKOUT1             => o_clk_mmcm,
         CLKOUT2             => hdmi_clk_mmcm,
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
         LOCKED              => locked_o,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => not sys_rstn_i
      ); -- i_clk_hdmi


   -------------------------------------
   -- Output buffering
   -------------------------------------

   i_bufg_clkfb : BUFG
      port map (
         I => clkfb_mmcm,
         O => clkfb
      ); -- i_bufg_clkfb

   i_bufg_i_clk : BUFG
      port map (
         I => i_clk_mmcm,
         O => i_clk_o
      ); -- i_bufg_i_clk

   i_bufg_o_clk : BUFG
      port map (
         I => o_clk_mmcm,
         O => o_clk_o
      ); -- i_bufg_o_clk

   i_bufg_hdmi_clk : BUFG
      port map (
         I => hdmi_clk_mmcm,
         O => hdmi_clk_o
      ); -- i_bufg_hdmi_clk

end architecture synthesis;

