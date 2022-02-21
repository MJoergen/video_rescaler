library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
   port (
      clk         : in    std_logic;                  -- 100 MHz clock
      reset_n     : in    std_logic;                  -- CPU reset button (active low)

      -- HyperRAM device interface
      hr_resetn   : out   std_logic;
      hr_csn      : out   std_logic;
      hr_ck       : out   std_logic;
      hr_rwds     : inout std_logic;
      hr_dq       : inout std_logic_vector(7 downto 0);

      -- MEGA65 keyboard
      kb_io0      : out   std_logic;
      kb_io1      : out   std_logic;
      kb_io2      : in    std_logic;

      -- MEGA65 Digital Video (HDMI)
      hdmi_data_p : out   std_logic_vector(2 downto 0);
      hdmi_data_n : out   std_logic_vector(2 downto 0);
      hdmi_clk_p  : out   std_logic;
      hdmi_clk_n  : out   std_logic
   );
end entity top;

architecture synthesis of top is

   signal vga_clk : std_logic;
   signal vga_r   : std_logic_vector(7 downto 0);
   signal vga_g   : std_logic_vector(7 downto 0);
   signal vga_b   : std_logic_vector(7 downto 0);
   signal vga_hs  : std_logic;
   signal vga_vs  : std_logic;
   signal vga_de  : std_logic;

begin

   --------------------------------------------------------
   -- Instantiate Core
   --------------------------------------------------------

   i_democore : entity work.democore
      port map (
         sys_clk_i  => clk,       -- 100 MHz clock
         sys_rstn_i => reset_n,   -- CPU reset button (active low)
         vga_clk_o  => vga_clk,
         vga_r_o    => vga_r,
         vga_g_o    => vga_g,
         vga_b_o    => vga_b,
         vga_hs_o   => vga_hs,
         vga_vs_o   => vga_vs,
         vga_de_o   => vga_de
      ); -- i_democore


   --------------------------------------------------------
   -- Instantiate MEGA65 framework
   --------------------------------------------------------

   i_framework : entity work.framework
      port map (
         vga_clk_i   => vga_clk,
         vga_r_i     => vga_r,
         vga_g_i     => vga_g,
         vga_b_i     => vga_b,
         vga_hs_i    => vga_hs,
         vga_vs_i    => vga_vs,
         vga_de_i    => vga_de,
         clk         => clk,
         reset_n     => reset_n,
         hr_resetn   => hr_resetn,
         hr_csn      => hr_csn,
         hr_ck       => hr_ck,
         hr_rwds     => hr_rwds,
         hr_dq       => hr_dq,
         kb_io0      => kb_io0,
         kb_io1      => kb_io1,
         kb_io2      => kb_io2,
         hdmi_data_p => hdmi_data_p,
         hdmi_data_n => hdmi_data_n,
         hdmi_clk_p  => hdmi_clk_p,
         hdmi_clk_n  => hdmi_clk_n
      ); -- i_framework

end architecture synthesis;

