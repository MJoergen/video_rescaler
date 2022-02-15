library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.types_pkg.all;

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

   constant MASK      : unsigned(7 downto 0) := x"ff";
   constant RAMBASE   : unsigned(31 downto 0) := (others => '0');
   constant RAMSIZE   : unsigned(31 downto 0) := x"0080_0000"; -- = 8MB
   constant INTER     : boolean := true;
   constant HEADER    : boolean := true;
   constant DOWNSCALE : boolean := true;
   constant BYTESWAP  : boolean := true;
   constant PALETTE   : boolean := true;
   constant PALETTE2  : boolean := true;
   constant FRAC      : natural range 4 to 6 := 4;
   constant OHRES     : natural range 1 to 4096 := 2048;
   constant IHRES     : natural range 1 to 2048 := 2048;
   constant N_DW      : natural range 64 to 128 := 128;
   constant N_AW      : natural range 8 to 32 := 22;
   constant N_BURST   : natural := 256; -- 256 bytes per burst

   ------------------------------------
   -- input video
   signal i_r                : unsigned(7 downto 0);
   signal i_g                : unsigned(7 downto 0);
   signal i_b                : unsigned(7 downto 0);
   signal i_hs               : std_logic; -- h sync
   signal i_vs               : std_logic; -- v sync
   signal i_fl               : std_logic; -- interlaced field
   signal i_de               : std_logic; -- display enable
   signal i_ce               : std_logic; -- clock enable
   signal i_clk              : std_logic; -- input clock

   ------------------------------------
   -- output video
   signal o_r                : unsigned(7 downto 0);
   signal o_g                : unsigned(7 downto 0);
   signal o_b                : unsigned(7 downto 0);
   signal o_hs               : std_logic; -- h sync
   signal o_vs               : std_logic; -- v sync
   signal o_de               : std_logic; -- display enable
   signal o_vbl              : std_logic; -- v blank
   signal o_ce               : std_logic; -- clock enable
   signal o_clk              : std_logic; -- output clock

   -- border colour r g b
   signal o_border           : unsigned(23 downto 0) := x"000000";

   ------------------------------------
   -- framebuffer mode
   signal o_fb_ena           : std_logic :='0'; -- enable framebuffer mode
   signal o_fb_hsize         : natural range 0 to 4095 :=0;
   signal o_fb_vsize         : natural range 0 to 4095 :=0;
   signal o_fb_format        : unsigned(5 downto 0) :="000100";
   signal o_fb_base          : unsigned(31 downto 0) :=x"0000_0000";
   signal o_fb_stride        : unsigned(13 downto 0) :=(others =>'0');

   -- framebuffer palette in 8bpp mode
   signal pal1_clk           : std_logic :='0';
   signal pal1_dw            : unsigned(47 downto 0) :=x"000000000000"; -- r1 g1 b1 r0 g0 b0
   signal pal1_dr            : unsigned(47 downto 0) :=x"000000000000";
   signal pal1_a             : unsigned(6 downto 0)  :="0000000"; -- colour index/2
   signal pal1_wr            : std_logic :='0';

   signal pal_n              : std_logic :='0';

   signal pal2_clk           : std_logic :='0';
   signal pal2_dw            : unsigned(23 downto 0) :=x"000000"; -- r g b
   signal pal2_dr            : unsigned(23 downto 0) :=x"000000";
   signal pal2_a             : unsigned(7 downto 0)  :="00000000"; -- colour index
   signal pal2_wr            : std_logic :='0';

   ------------------------------------
   -- low lag pll tuning
   signal o_lltune           : unsigned(15 downto 0);

   ------------------------------------
   -- input video parameters
   signal iauto              : std_logic :='1'; -- 1=autodetect image size 0=choose window
   signal himin              : natural range 0 to 4095 :=0; -- min < max, min >=0, max < disp
   signal himax              : natural range 0 to 4095 :=0;
   signal vimin              : natural range 0 to 4095 :=0;
   signal vimax              : natural range 0 to 4095 :=0;

   -- detected input image size
   signal i_hdmax            : natural range 0 to 4095;
   signal i_vdmax            : natural range 0 to 4095;

   -- output video parameters
   signal run                : std_logic :='1'; -- 1=enable output image. 0=no image
   signal freeze             : std_logic :='0'; -- 1=disable framebuffer writes
   signal mode               : unsigned(4 downto 0);
   -- sync  |_________________________/"""""""""\_______|
   -- de    |""""""""""""""""""\________________________|
   -- rgb   |    <#image#>      ^hdisp                  |
   --            ^hmin   ^hmax        ^hsstart  ^hsend  ^htotal
   signal htotal             : natural range 0 to 4095;
   signal hsstart            : natural range 0 to 4095;
   signal hsend              : natural range 0 to 4095;
   signal hdisp              : natural range 0 to 4095;
   signal hmin               : natural range 0 to 4095;
   signal hmax               : natural range 0 to 4095; -- 0 <= hmin < hmax < hdisp
   signal vtotal             : natural range 0 to 4095;
   signal vsstart            : natural range 0 to 4095;
   signal vsend              : natural range 0 to 4095;
   signal vdisp              : natural range 0 to 4095;
   signal vmin               : natural range 0 to 4095;
   signal vmax               : natural range 0 to 4095; -- 0 <= vmin < vmax < vdisp

   -- scaler format. 00=16bpp 565, 01=24bpp 10=32bpp
   signal format             : unsigned(1 downto 0) :="01";

   ------------------------------------
   -- polyphase filter coefficients
   -- order:
   --   [horizontal] [vertical]
   --   [0]...[2**frac-1]
   --   [-1][0][1][2]
   signal poly_clk           : std_logic;
   signal poly_dw            : unsigned(8 downto 0);
   signal poly_a             : unsigned(FRAC+2 downto 0);
   signal poly_wr            : std_logic;

   ------------------------------------
   -- avalon
   signal avl_clk            : std_logic; -- avalon clock
   signal avl_waitrequest    : std_logic;
   signal avl_readdata       : std_logic_vector(N_DW-1 downto 0);
   signal avl_readdatavalid  : std_logic;
   signal avl_burstcount     : std_logic_vector(7 downto 0);
   signal avl_writedata      : std_logic_vector(N_DW-1 downto 0);
   signal avl_address        : std_logic_vector(N_AW-1 downto 0);
   signal avl_write          : std_logic;
   signal avl_read           : std_logic;
   signal avl_byteenable     : std_logic_vector(N_DW/8-1 downto 0);

   ------------------------------------
   signal reset_na           : std_logic;

   -- HDMI output
   signal video_clk          : std_logic;
   signal video_rst          : std_logic;
   signal hdmi_clk           : std_logic;
   signal video_data         : slv_9_0_t(0 to 2);              -- parallel HDMI symbol stream x 3 channels

   -- HyperRAM
   signal avm_write          : std_logic;
   signal avm_read           : std_logic;
   signal avm_address        : std_logic_vector(21 downto 0);
   signal avm_writedata      : std_logic_vector(15 downto 0);
   signal avm_byteenable     : std_logic_vector(1 downto 0);
   signal avm_burstcount     : std_logic_vector(7 downto 0);
   signal avm_readdata       : std_logic_vector(15 downto 0);
   signal avm_readdatavalid  : std_logic;
   signal avm_waitrequest    : std_logic;

   signal clk_x1             : std_logic; -- Main clock
   signal clk_x2             : std_logic; -- Physical I/O only
   signal clk_x2_del         : std_logic; -- Double frequency, phase shifted
   signal rst                : std_logic; -- Synchronous reset
   signal hr_rwds_in         : std_logic;
   signal hr_rwds_out        : std_logic;
   signal hr_rwds_oe         : std_logic;   -- Output enable for RWDS
   signal hr_dq_in           : std_logic_vector(7 downto 0);
   signal hr_dq_out          : std_logic_vector(7 downto 0);
   signal hr_dq_oe           : std_logic;    -- Output enable for DQ

begin


   --------------------------------------------------------
   -- Generate input video
   --------------------------------------------------------

   i_gen_video : entity work.gen_video
      port map (
         clk_i => i_clk,
         r_o   => i_r,
         g_o   => i_g,
         b_o   => i_b,
         hs_o  => i_hs,
         vs_o  => i_vs,
         de_o  => i_de
      ); -- i_gen_video


   --------------------------------------------------------
   -- Instantiate video rescaler
   --------------------------------------------------------

   i_ascal : entity work.ascal
      generic map (
         MASK      => MASK,
         RAMBASE   => RAMBASE,
         RAMSIZE   => RAMSIZE,
         INTER     => INTER,
         HEADER    => HEADER,
         DOWNSCALE => DOWNSCALE,
         BYTESWAP  => BYTESWAP,
         PALETTE   => PALETTE,
         PALETTE2  => PALETTE2,
         FRAC      => FRAC,
         OHRES     => OHRES,
         IHRES     => IHRES,
         N_DW      => N_DW,
         N_AW      => N_AW,
         N_BURST   => N_BURST
      )
      port map (
         i_r               => i_r,
         i_g               => i_g,
         i_b               => i_b,
         i_hs              => i_hs,
         i_vs              => i_vs,
         i_fl              => i_fl,
         i_de              => i_de,
         i_ce              => i_ce,
         i_clk             => i_clk,
         o_r               => o_r,
         o_g               => o_g,
         o_b               => o_b,
         o_hs              => o_hs,
         o_vs              => o_vs,
         o_de              => o_de,
         o_vbl             => o_vbl,
         o_ce              => o_ce,
         o_clk             => o_clk,
         o_border          => o_border,
         o_fb_ena          => o_fb_ena,
         o_fb_hsize        => o_fb_hsize,
         o_fb_vsize        => o_fb_vsize,
         o_fb_format       => o_fb_format,
         o_fb_base         => o_fb_base,
         o_fb_stride       => o_fb_stride,
         pal1_clk          => pal1_clk,
         pal1_dw           => pal1_dw,
         pal1_dr           => pal1_dr,
         pal1_a            => pal1_a,
         pal1_wr           => pal1_wr,
         pal_n             => pal_n,
         pal2_clk          => pal2_clk,
         pal2_dw           => pal2_dw,
         pal2_dr           => pal2_dr,
         pal2_a            => pal2_a,
         pal2_wr           => pal2_wr,
         o_lltune          => o_lltune,
         iauto             => iauto,
         himin             => himin,
         himax             => himax,
         vimin             => vimin,
         vimax             => vimax,
         i_hdmax           => i_hdmax,
         i_vdmax           => i_vdmax,
         run               => run,
         freeze            => freeze,
         mode              => mode,
         htotal            => htotal,
         hsstart           => hsstart,
         hsend             => hsend,
         hdisp             => hdisp,
         hmin              => hmin,
         hmax              => hmax,
         vtotal            => vtotal,
         vsstart           => vsstart,
         vsend             => vsend,
         vdisp             => vdisp,
         vmin              => vmin,
         vmax              => vmax,
         format            => format,
         poly_clk          => poly_clk,
         poly_dw           => poly_dw,
         poly_a            => poly_a,
         poly_wr           => poly_wr,
         avl_clk           => avl_clk,
         avl_waitrequest   => avl_waitrequest,
         avl_readdata      => avl_readdata,
         avl_readdatavalid => avl_readdatavalid,
         avl_burstcount    => avl_burstcount,
         avl_writedata     => avl_writedata,
         avl_address       => avl_address,
         avl_write         => avl_write,
         avl_read          => avl_read,
         avl_byteenable    => avl_byteenable,
         reset_na          => reset_na
      ); -- i_ascal


   --------------------------------------------------------
   -- Output HDMI generation
   --------------------------------------------------------

   i_clk_hdmi : entity work.clk_hdmi
      port map (
         sys_clk_i    => clk,
         sys_rstn_i   => reset_n,
         pixel_clk_o  => video_clk,
         pixel_rst_o  => video_rst,
         pixel_clk5_o => hdmi_clk
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

         vga_rst      => video_rst,                           -- active high reset
         vga_clk      => video_clk,                           -- video pixel clock
         vga_vs       => o_vs,
         vga_hs       => o_hs,
         vga_de       => o_de,
         vga_r        => std_logic_vector(o_r),
         vga_g        => std_logic_vector(o_g),
         vga_b        => std_logic_vector(o_b),

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
            rst_i    => video_rst,
            clk_i    => video_clk,
            d_i      => video_data(i),
            clk_x5_i => hdmi_clk,
            out_p_o  => hdmi_data_p(i),
            out_n_o  => hdmi_data_n(i)
         ); -- i_serialiser_10to1_selectio_data
   end generate gen_hdmi_data;


   i_serialiser_10to1_selectio_clk : entity work.serialiser_10to1_selectio
   port map (
         rst_i    => video_rst,
         clk_i    => video_clk,
         clk_x5_i => hdmi_clk,
         d_i      => "0000011111",
         out_p_o  => hdmi_clk_p,
         out_n_o  => hdmi_clk_n
      ); -- i_serialiser_10to1_selectio_clk



   --------------------------------------------------------
   -- Generate clocks for HyperRAM controller
   --------------------------------------------------------

   i_clk_hr : entity work.clk_hr
      generic map
      (
         G_HYPERRAM_FREQ_MHZ => 100,
         G_HYPERRAM_PHASE    => 162.0
      )
      port map
      (
         sys_clk_i    => clk,
         sys_rstn_i   => reset_n,
         clk_x1_o     => clk_x1,
         clk_x2_o     => clk_x2,
         clk_x2_del_o => clk_x2_del,
         rst_o        => rst
      ); -- i_clk_hr


   --------------------------------------------------------
   -- Convert from ascaler data width to HyperRAM data width
   --------------------------------------------------------

   i_avm_decrease : entity work.avm_decrease
      generic map (
         G_ADDRESS_SIZE     => 22,
         G_SLAVE_DATA_SIZE  => 128,
         G_MASTER_DATA_SIZE => 16
      )
      port map (
         clk_i                 => clk_x1,
         rst_i                 => rst,
         s_avm_write_i         => avl_write,
         s_avm_read_i          => avl_read,
         s_avm_address_i       => avl_address,
         s_avm_writedata_i     => avl_writedata,
         s_avm_byteenable_i    => avl_byteenable,
         s_avm_burstcount_i    => avl_burstcount,
         s_avm_readdata_o      => avl_readdata,
         s_avm_readdatavalid_o => avl_readdatavalid,
         s_avm_waitrequest_o   => avl_waitrequest,
         m_avm_write_o         => avm_write,
         m_avm_read_o          => avm_read,
         m_avm_address_o       => avm_address,
         m_avm_writedata_o     => avm_writedata,
         m_avm_byteenable_o    => avm_byteenable,
         m_avm_burstcount_o    => avm_burstcount,
         m_avm_readdata_i      => avm_readdata,
         m_avm_readdatavalid_i => avm_readdatavalid,
         m_avm_waitrequest_i   => avm_waitrequest
      ); -- i_avm_decrease


   --------------------------------------------------------
   -- Instantiate HyperRAM controller
   --------------------------------------------------------

   i_hyperram : entity work.hyperram
      port map (
         clk_x1_i            => clk_x1,
         clk_x2_i            => clk_x2,
         clk_x2_del_i        => clk_x2_del,
         rst_i               => rst,
         avm_write_i         => avm_write,
         avm_read_i          => avm_read,
         avm_address_i       => "0000000000" & avm_address,
         avm_writedata_i     => avm_writedata,
         avm_byteenable_i    => avm_byteenable,
         avm_burstcount_i    => avm_burstcount,
         avm_readdata_o      => avm_readdata,
         avm_readdatavalid_o => avm_readdatavalid,
         avm_waitrequest_o   => avm_waitrequest,
         hr_resetn_o         => hr_resetn,
         hr_csn_o            => hr_csn,
         hr_ck_o             => hr_ck,
         hr_rwds_in_i        => hr_rwds_in,
         hr_rwds_out_o       => hr_rwds_out,
         hr_rwds_oe_o        => hr_rwds_oe,
         hr_dq_in_i          => hr_dq_in,
         hr_dq_out_o         => hr_dq_out,
         hr_dq_oe_o          => hr_dq_oe
      ); -- i_hyperram


   ----------------------------------
   -- Tri-state buffers for HyperRAM
   ----------------------------------

   hr_rwds    <= hr_rwds_out when hr_rwds_oe = '1' else 'Z';
   hr_dq      <= hr_dq_out   when hr_dq_oe   = '1' else (others => 'Z');
   hr_rwds_in <= hr_rwds;
   hr_dq_in   <= hr_dq;

end architecture synthesis;

