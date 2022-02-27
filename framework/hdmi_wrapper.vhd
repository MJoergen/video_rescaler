library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types_pkg.all;

entity hdmi_wrapper is
   generic (
      G_VIDEO_CLK : natural := 74_250_000;
      G_AUDIO_CLK : natural := 48_000;
      CEA_CTA_VIC : natural
   );
   port (
      video_clk_i   : in  std_logic;
      video_rst_i   : in  std_logic;
      video_r_i     : in  unsigned(7 downto 0);
      video_g_i     : in  unsigned(7 downto 0);
      video_b_i     : in  unsigned(7 downto 0);
      video_hs_i    : in  std_logic;
      video_vs_i    : in  std_logic;
      video_de_i    : in  std_logic;

      audio_clk_i   : in  std_logic;
      audio_rst_i   : in  std_logic;
      audio_left_i  : in  std_logic_vector(15 downto 0); -- signed
      audio_right_i : in  std_logic_vector(15 downto 0); -- signed

      hdmi_clk_i    : in  std_logic;
      hdmi_data_p_o : out std_logic_vector(2 downto 0);
      hdmi_data_n_o : out std_logic_vector(2 downto 0);
      hdmi_clk_p_o  : out std_logic;
      hdmi_clk_n_o  : out std_logic
   );
end entity hdmi_wrapper;

architecture synthesis of hdmi_wrapper is

   signal video_data : slv_9_0_t(0 to 2);              -- parallel HDMI symbol stream x 3 channels

   signal pcm_n   : std_logic_vector(19 downto 0);
   signal pcm_cts : std_logic_vector(19 downto 0);

   signal pcm_acr : std_logic_vector(47 downto 0) := X"000000000001";

begin

   -- N and CTS values for HDMI Audio Clock Regeneration.
   -- depends on pixel clock and audio sample rate
   pcm_n   <= std_logic_vector(to_unsigned((G_AUDIO_CLK * 128) / 1000, pcm_n'length));
   pcm_cts <= std_logic_vector(to_unsigned(G_VIDEO_CLK / 1000, pcm_cts'length));

   p_acr : process (audio_clk_i)
   begin
      if rising_edge(audio_clk_i) then
         pcm_acr <= pcm_acr(46 downto 0) & pcm_acr(47);
      end if;
   end process p_acr;

   i_audio_video_to_hdmi : entity work.audio_video_to_hdmi
      port map (
         select_44100 => '0',
         dvi          => '0',
         vic          => std_logic_vector(to_unsigned(CEA_CTA_VIC,8)),
         aspect       => "10",                                -- 01=4:3, 10=16:9
         pix_rep      => '0',                                 -- no pixel repetition
         vs_pol       => '1',                                 -- horizontal polarity: positive
         hs_pol       => '1',                                 -- vertaical polarity: positive

         vga_rst      => video_rst_i,
         vga_clk      => video_clk_i,                         -- video pixel clock
         vga_vs       => video_vs_i,
         vga_hs       => video_hs_i,
         vga_de       => video_de_i,
         vga_r        => std_logic_vector(video_r_i),
         vga_g        => std_logic_vector(video_g_i),
         vga_b        => std_logic_vector(video_b_i),

         -- PCM audio
         pcm_rst      => audio_rst_i,
         pcm_clk      => audio_clk_i,
         pcm_clken    => '1',
         pcm_l        => audio_left_i,
         pcm_r        => audio_right_i,
         pcm_acr      => pcm_acr(47),
         pcm_n        => pcm_n,
         pcm_cts      => pcm_cts,

         -- TMDS output (parallel)
         tmds         => video_data
      ); -- i_audio_video_to_hdmi


   -- serialiser: in this design we use HDMI SelectIO outputs
   gen_hdmi_data: for i in 0 to 2 generate
   begin
      i_serialiser_10to1_selectio_data: entity work.serialiser_10to1_selectio
         port map (
            rst_i    => video_rst_i,
            clk_i    => video_clk_i,
            d_i      => video_data(i),
            clk_x5_i => hdmi_clk_i,
            out_p_o  => hdmi_data_p_o(i),
            out_n_o  => hdmi_data_n_o(i)
         ); -- i_serialiser_10to1_selectio_data
   end generate gen_hdmi_data;


   i_serialiser_10to1_selectio_clk : entity work.serialiser_10to1_selectio
   port map (
         rst_i    => video_rst_i,
         clk_i    => video_clk_i,
         d_i      => "0000011111",
         clk_x5_i => hdmi_clk_i,
         out_p_o  => hdmi_clk_p_o,
         out_n_o  => hdmi_clk_n_o
      ); -- i_serialiser_10to1_selectio_clk

end architecture synthesis;

