library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity clk is
   port (
      sys_clk_i    : in  std_logic;   -- expects 100 MHz
      sys_rstn_i   : in  std_logic;   -- Asynchronous, asserted low
      o_clk_o      : out std_logic;   -- 74.25 MHz pixelclock for 720p @ 60 Hz
      hdmi_clk_o   : out std_logic;   -- pixelclock (74.25 MHz x 5 = 371.25 MHz) for HDMI
      clk_x1_o     : out std_logic;   -- 100 MHz
      clk_x2_o     : out std_logic;   -- 200 MHz
      clk_x2_del_o : out std_logic;   -- 200 MHz
      kbd_clk_o    : out std_logic;   -- 40 MHz
      locked_o     : out std_logic
   );
end entity clk;

architecture synthesis of clk is

   constant C_HYPERRAM_PHASE : real := 162.000;

   signal hdmi_clkfb      : std_logic;
   signal hdmi_clkfb_mmcm : std_logic;
   signal o_clk_mmcm      : std_logic;
   signal hdmi_clk_mmcm   : std_logic;

   signal hr_clkfb        : std_logic;
   signal hr_clkfb_mmcm   : std_logic;
   signal kbd_clk_mmcm    : std_logic;
   signal clk_x1_mmcm     : std_logic;
   signal clk_x2_mmcm     : std_logic;
   signal clk_x2_del_mmcm : std_logic;

   signal hdmi_locked     : std_logic;
   signal hr_locked       : std_logic;

begin

   locked_o <= hdmi_locked and hr_locked;


   --------------------------------------------------------
   -- Generate HDMI clock
   --------------------------------------------------------
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
         CLKFBOUT            => hdmi_clkfb_mmcm,
         CLKOUT1             => o_clk_mmcm,
         CLKOUT2             => hdmi_clk_mmcm,
         CLKFBIN             => hdmi_clkfb,
         CLKIN1              => sys_clk_i,
         CLKIN2              => '0',
         CLKINSEL            => '1',
         DADDR               => (others => '0'),
         DCLK                => '0',
         DEN                 => '0',
         DI                  => (others => '0'),
         DO                  => open,
         DRDY                => open,
         DWE                 => '0',
         PSCLK               => '0',
         PSEN                => '0',
         PSINCDEC            => '0',
         PSDONE              => open,
         LOCKED              => hdmi_locked,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => not sys_rstn_i
      ); -- i_clk_hdmi


   --------------------------------------------------------
   -- generate HyperRAM and keyboard clock.
   --------------------------------------------------------

   i_clk_hyperram : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 1,
         CLKFBOUT_MULT_F      => 10.000,
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 25.000,     -- 40 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE,
         CLKOUT1_DIVIDE       => 5,          -- 200 MHz
         CLKOUT1_PHASE        => 0.000,
         CLKOUT1_DUTY_CYCLE   => 0.500,
         CLKOUT1_USE_FINE_PS  => FALSE,
         CLKOUT2_DIVIDE       => 5,          -- 200 MHz
         CLKOUT2_PHASE        => C_HYPERRAM_PHASE,
         CLKOUT2_DUTY_CYCLE   => 0.500,
         CLKOUT2_USE_FINE_PS  => FALSE,
         CLKOUT3_DIVIDE       => 10,         -- 100 MHz
         CLKOUT3_PHASE        => 0.000,
         CLKOUT3_DUTY_CYCLE   => 0.500,
         CLKOUT3_USE_FINE_PS  => FALSE
      )
      port map (
         CLKFBOUT            => hr_clkfb_mmcm,
         CLKOUT0             => kbd_clk_mmcm,
         CLKOUT1             => clk_x2_mmcm,
         CLKOUT2             => clk_x2_del_mmcm,
         CLKOUT3             => clk_x1_mmcm,
         CLKFBIN             => hr_clkfb,
         CLKIN1              => sys_clk_i,
         CLKIN2              => '0',
         CLKINSEL            => '1',
         DADDR               => (others => '0'),
         DCLK                => '0',
         DEN                 => '0',
         DI                  => (others => '0'),
         DO                  => open,
         DRDY                => open,
         DWE                 => '0',
         PSCLK               => '0',
         PSEN                => '0',
         PSINCDEC            => '0',
         PSDONE              => open,
         LOCKED              => hr_locked,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => not sys_rstn_i
      ); -- i_clk_hyperram

   -------------------------------------
   -- Output buffering
   -------------------------------------

   i_bufg_hdmi_clkfb : BUFG
      port map (
         I => hdmi_clkfb_mmcm,
         O => hdmi_clkfb
      ); -- i_bufg_hdmi_clkfb

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

   i_bufg_hr_clkfb : BUFG
      port map (
         I => hr_clkfb_mmcm,
         O => hr_clkfb
      ); -- i_bufg_hr_clkfb

   i_bufg_kbd_clk : BUFG
      port map (
         I => kbd_clk_mmcm,
         O => kbd_clk_o
      ); -- i_bufg_kbd_clk

   i_bufg_clk_x1 : BUFG
      port map (
         I => clk_x1_mmcm,
         O => clk_x1_o
      ); -- i_bufg_clk_x1

   i_bufg_clk_x2 : BUFG
      port map (
         I => clk_x2_mmcm,
         O => clk_x2_o
      ); -- i_bufg_clk_x2

   i_bufg_clk_x2_del : BUFG
      port map (
         I => clk_x2_del_mmcm,
         O => clk_x2_del_o
      ); -- i_bufg_clk_x2_del
end architecture synthesis;

