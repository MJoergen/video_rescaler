library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types_pkg.all;

entity hdmi_wrapper is
   port (
      clk_i         : in  std_logic;                  -- 100 MHz clock
      reset_n_i     : in  std_logic;                  -- CPU reset button (active low)

      i_clk_o       : out std_logic;
      o_clk_o       : out std_logic;
      locked_o      : out std_logic;                  -- Asserted asynchronous, when clocks are valid

      o_rst_i       : in  std_logic;
      o_r_i         : in  unsigned(7 downto 0);
      o_g_i         : in  unsigned(7 downto 0);
      o_b_i         : in  unsigned(7 downto 0);
      o_hs_i        : in  std_logic; -- h sync
      o_vs_i        : in  std_logic; -- v sync
      o_de_i        : in  std_logic; -- display enable
      o_vbl_i       : in  std_logic; -- v blank

      -- MEGA65 Digital Video (HDMI)
      hdmi_data_p_o : out std_logic_vector(2 downto 0);
      hdmi_data_n_o : out std_logic_vector(2 downto 0);
      hdmi_clk_p_o  : out std_logic;
      hdmi_clk_n_o  : out std_logic
   );
end entity hdmi_wrapper;

architecture synthesis of hdmi_wrapper is

   constant N_DW : natural range 64 to 128 := 128;
   constant N_AW : natural range 8 to 32 := 22;

   signal hdmi_clk   : std_logic;
   signal video_data : slv_9_0_t(0 to 2);              -- parallel HDMI symbol stream x 3 channels

begin

   i_clk_hdmi : entity work.clk_hdmi
      port map (
         sys_clk_i  => clk_i,
         sys_rstn_i => reset_n_i,
         i_clk_o    => i_clk_o,
         o_clk_o    => o_clk_o,
         hdmi_clk_o => hdmi_clk,
         locked_o   => locked_o
      ); -- i_clk_hdmi


   i_audio_video_to_hdmi : entity work.audio_video_to_hdmi
      port map (
         select_44100 => '0',
         dvi          => '0',
         vic          => std_logic_vector(to_unsigned(4,8)),  -- CEA/CTA VIC 4=720p @ 60 Hz
         aspect       => "10",                                -- 01=4:3, 10=16:9
         pix_rep      => '0',                                 -- no pixel repetition
         vs_pol       => '1',                                 -- horizontal polarity: positive
         hs_pol       => '1',                                 -- vertaical polarity: positive

         vga_rst      => o_rst_i,
         vga_clk      => o_clk_o,                             -- video pixel clock
         vga_vs       => o_vs_i,
         vga_hs       => o_hs_i,
         vga_de       => o_de_i,
         vga_r        => std_logic_vector(o_r_i),
         vga_g        => std_logic_vector(o_g_i),
         vga_b        => std_logic_vector(o_b_i),

         -- PCM audio
         pcm_rst      => '0',
         pcm_clk      => '0',
         pcm_clken    => '0',

         -- PCM audio is signed
         pcm_l        => X"0000",
         pcm_r        => X"0000",

         pcm_acr      => '0',
         pcm_n        => X"00000",
         pcm_cts      => X"00000",

         -- TMDS output (parallel)
         tmds         => video_data
      ); -- i_audio_video_to_hdmi


   -- serialiser: in this design we use HDMI SelectIO outputs
   gen_hdmi_data: for i in 0 to 2 generate
   begin
      i_serialiser_10to1_selectio_data: entity work.serialiser_10to1_selectio
         port map (
            rst_i    => o_rst_i,
            clk_i    => o_clk_o,
            d_i      => video_data(i),
            clk_x5_i => hdmi_clk,
            out_p_o  => hdmi_data_p_o(i),
            out_n_o  => hdmi_data_n_o(i)
         ); -- i_serialiser_10to1_selectio_data
   end generate gen_hdmi_data;


   i_serialiser_10to1_selectio_clk : entity work.serialiser_10to1_selectio
   port map (
         rst_i    => o_rst_i,
         clk_i    => o_clk_o,
         d_i      => "0000011111",
         clk_x5_i => hdmi_clk,
         out_p_o  => hdmi_clk_p_o,
         out_n_o  => hdmi_clk_n_o
      ); -- i_serialiser_10to1_selectio_clk

end architecture synthesis;

