library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity democore is
   port (
      sys_clk_i     : in  std_logic;
      sys_rstn_i    : in  std_logic;
      audio_clk_o   : out std_logic;
      audio_rst_o   : out std_logic;
      audio_left_o  : out std_logic_vector(15 downto 0); -- signed
      audio_right_o : out std_logic_vector(15 downto 0); -- signed
      vga_clk_o     : out std_logic;
      vga_r_o       : out std_logic_vector(7 downto 0);
      vga_g_o       : out std_logic_vector(7 downto 0);
      vga_b_o       : out std_logic_vector(7 downto 0);
      vga_hs_o      : out std_logic;
      vga_vs_o      : out std_logic;
      vga_de_o      : out std_logic
   );
end democore;

architecture synthesis of democore is

begin

   i_democore_clk : entity work.democore_clk
      port map (
         sys_clk_i   => sys_clk_i,
         sys_rstn_i  => sys_rstn_i,
         audio_clk_o => audio_clk_o,
         audio_rst_o => audio_rst_o,
         vga_clk_o   => vga_clk_o,
         vga_rst_o   => open
      ); -- i_democore_clk

   i_democore_video : entity work.democore_video
      port map (
         vga_clk_i => vga_clk_o,
         vga_r_o   => vga_r_o,
         vga_g_o   => vga_g_o,
         vga_b_o   => vga_b_o,
         vga_hs_o  => vga_hs_o,
         vga_vs_o  => vga_vs_o,
         vga_de_o  => vga_de_o
      ); -- i_democore_video

   i_democore_audio : entity work.democore_audio
      port map (
         audio_clk_i   => audio_clk_o,
         audio_left_o  => audio_left_o,
         audio_right_o => audio_right_o
      ); -- i_democore_audio

end architecture synthesis;

