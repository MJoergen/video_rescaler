library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
   port (
      clk          : in    std_logic;                  -- 100 MHz clock
      reset_n      : in    std_logic;                  -- CPU reset button (active low)

      -- HyperRAM device interface
      hr_resetn    : out   std_logic;
      hr_csn       : out   std_logic;
      hr_ck        : out   std_logic;
      hr_rwds      : inout std_logic;
      hr_dq        : inout std_logic_vector(7 downto 0);

      -- MEGA65 keyboard
      kb_io0       : out   std_logic;
      kb_io1       : out   std_logic;
      kb_io2       : in    std_logic;

      -- VGA output
      vga_red      : out   std_logic_vector(7 downto 0);
      vga_green    : out   std_logic_vector(7 downto 0);
      vga_blue     : out   std_logic_vector(7 downto 0);
      vga_hs       : out   std_logic;
      vga_vs       : out   std_logic;
      vdac_clk     : out   std_logic;
      vdac_sync_n  : out   std_logic := '0';
      vdac_blank_n : out   std_logic;

      -- Audio output
      pwm_l        : out   std_logic;
      pwm_r        : out   std_logic;

      -- MEGA65 Digital Video (HDMI)
      hdmi_data_p  : out   std_logic_vector(2 downto 0);
      hdmi_data_n  : out   std_logic_vector(2 downto 0);
      hdmi_clk_p   : out   std_logic;
      hdmi_clk_n   : out   std_logic
   );
end entity top;

architecture synthesis of top is

   signal audio_clk   : std_logic;
   signal audio_rst   : std_logic;
   signal audio_left  : std_logic_vector(15 downto 0);
   signal audio_right : std_logic_vector(15 downto 0);

begin

   --------------------------------------------------------
   -- Instantiate Core
   --------------------------------------------------------

   i_democore : entity work.democore
      port map (
         sys_clk_i     => clk,       -- 100 MHz clock
         sys_rstn_i    => reset_n,   -- CPU reset button (active low)
         vga_clk_o     => vdac_clk,
         vga_r_o       => vga_red,
         vga_g_o       => vga_green,
         vga_b_o       => vga_blue,
         vga_hs_o      => vga_hs,
         vga_vs_o      => vga_vs,
         vga_de_o      => vdac_blank_n,
         audio_clk_o   => audio_clk,
         audio_rst_o   => audio_rst,
         audio_left_o  => audio_left,
         audio_right_o => audio_right
      ); -- i_democore


   --------------------------------------------------------
   -- Instantiate MEGA65 framework
   --------------------------------------------------------

   i_framework : entity work.framework
      port map (
         vga_clk_i     => vdac_clk,
         vga_r_i       => vga_red,
         vga_g_i       => vga_green,
         vga_b_i       => vga_blue,
         vga_hs_i      => vga_hs,
         vga_vs_i      => vga_vs,
         vga_de_i      => vdac_blank_n,
         audio_clk_i   => audio_clk,
         audio_rst_i   => audio_rst,
         audio_left_i  => audio_left,
         audio_right_i => audio_right,
         pwm_l         => pwm_l,
         pwm_r         => pwm_r,
         clk           => clk,
         reset_n       => reset_n,
         hr_resetn     => hr_resetn,
         hr_csn        => hr_csn,
         hr_ck         => hr_ck,
         hr_rwds       => hr_rwds,
         hr_dq         => hr_dq,
         kb_io0        => kb_io0,
         kb_io1        => kb_io1,
         kb_io2        => kb_io2,
         hdmi_data_p   => hdmi_data_p,
         hdmi_data_n   => hdmi_data_n,
         hdmi_clk_p    => hdmi_clk_p,
         hdmi_clk_n    => hdmi_clk_n
      ); -- i_framework

end architecture synthesis;

