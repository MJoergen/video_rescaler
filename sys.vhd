library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sys is
   generic (
      N_DW : natural range 64 to 128 := 128;
      N_AW : natural range 8 to 32 := 22
   );
   port (
      i_clk              : in  std_logic;
      o_clk              : in  std_logic;
      avl_clk            : in  std_logic;
      poly_clk           : in  std_logic;
      pal1_clk           : in  std_logic;
      reset_na           : in  std_logic;
      --
      o_r                : out unsigned(7 downto 0);
      o_g                : out unsigned(7 downto 0);
      o_b                : out unsigned(7 downto 0);
      o_hs               : out std_logic; -- h sync
      o_vs               : out std_logic; -- v sync
      o_de               : out std_logic; -- display enable
      o_vbl              : out std_logic; -- v blank
      --
      avl_write          : out std_logic;
      avl_read           : out std_logic;
      avl_address        : out std_logic_vector(N_AW-1 downto 0);
      avl_writedata      : out std_logic_vector(N_DW-1 downto 0);
      avl_byteenable     : out std_logic_vector(N_DW/8-1 downto 0);
      avl_burstcount     : out std_logic_vector(7 downto 0);
      avl_readdata       : in  std_logic_vector(N_DW-1 downto 0);
      avl_readdatavalid  : in  std_logic;
      avl_waitrequest    : in  std_logic
   );
end entity sys;

architecture synthesis of sys is

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
   constant N_BURST   : natural := 256; -- 256 bytes per burst

   ------------------------------------
   -- input video
   signal i_r                : unsigned(7 downto 0);
   signal i_g                : unsigned(7 downto 0);
   signal i_b                : unsigned(7 downto 0);
   signal i_hs               : std_logic; -- h sync
   signal i_vs               : std_logic; -- v sync
   signal i_de               : std_logic; -- display enable

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
   signal poly_dw            : unsigned(8 downto 0)      := (others => '0');
   signal poly_a             : unsigned(FRAC+2 downto 0) := (others => '0');
   signal poly_wr            : std_logic                 := '0';

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
         i_r               => i_r,                    -- input
         i_g               => i_g,                    -- input
         i_b               => i_b,                    -- input
         i_hs              => i_hs,                   -- input
         i_vs              => i_vs,                   -- input
         i_fl              => '0',                    -- input
         i_de              => i_de,                   -- input
         i_ce              => '1',                    -- input
         i_clk             => i_clk,                  -- input
         o_r               => o_r,                    -- output
         o_g               => o_g,                    -- output
         o_b               => o_b,                    -- output
         o_hs              => o_hs,                   -- output
         o_vs              => o_vs,                   -- output
         o_de              => o_de,                   -- output
         o_vbl             => o_vbl,                  -- output
         o_ce              => '1',                    -- input
         o_clk             => o_clk,                  -- input
         o_border          => X"886644",              -- input
         o_fb_ena          => '0',                    -- input
         o_fb_hsize        => o_fb_hsize,             -- input
         o_fb_vsize        => o_fb_vsize,             -- input
         o_fb_format       => o_fb_format,            -- input
         o_fb_base         => o_fb_base,              -- input
         o_fb_stride       => o_fb_stride,            -- input
         pal1_clk          => pal1_clk,               -- input
         pal1_dw           => pal1_dw,                -- input
         pal1_dr           => pal1_dr,                -- output
         pal1_a            => pal1_a,                 -- input
         pal1_wr           => pal1_wr,                -- input
         pal_n             => pal_n,                  -- input
         pal2_clk          => pal2_clk,               -- input
         pal2_dw           => pal2_dw,                -- input
         pal2_dr           => pal2_dr,                -- output
         pal2_a            => pal2_a,                 -- input
         pal2_wr           => pal2_wr,                -- input
         o_lltune          => o_lltune,               -- output
         iauto             => '1',                    -- input
         himin             => 0,                      -- input
         himax             => 0,                      -- input
         vimin             => 0,                      -- input
         vimax             => 0,                      -- input
         i_hdmax           => i_hdmax,                -- output
         i_vdmax           => i_vdmax,                -- output
         run               => '1',                    -- input
         freeze            => '0',                    -- input
         mode              => "00000",                -- input
         htotal            => 1280 + 110 + 220 + 40,  -- input
         hsstart           => 1280 + 110,             -- input
         hsend             => 1280 + 110 + 40,        -- input
         hdisp             => 1280,                   -- input
         hmin              => 320,                    -- input
         hmax              => 959,                    -- input
         vtotal            => 720 + 5 + 20 + 5,       -- input
         vsstart           => 720 + 5,                -- input
         vsend             => 720 + 5 + 5,            -- input
         vdisp             => 720,                    -- input
         vmin              => 120,                    -- input
         vmax              => 599,                    -- input
         format            => "01",                   -- input
         poly_clk          => poly_clk,               -- input
         poly_dw           => poly_dw,                -- input
         poly_a            => poly_a,                 -- input
         poly_wr           => poly_wr,                -- input
         avl_clk           => avl_clk,                -- input
         avl_waitrequest   => avl_waitrequest,        -- input
         avl_readdata      => avl_readdata,           -- input
         avl_readdatavalid => avl_readdatavalid,      -- input
         avl_burstcount    => avl_burstcount,         -- output
         avl_writedata     => avl_writedata,          -- output
         avl_address       => avl_address,            -- output
         avl_write         => avl_write,              -- output
         avl_read          => avl_read,               -- output
         avl_byteenable    => avl_byteenable,         -- output
         reset_na          => reset_na                -- input
      ); -- i_ascal

end architecture synthesis;

