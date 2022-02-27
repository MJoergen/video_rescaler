library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xpm;
use xpm.vcomponents.all;

entity framework is
   port (
      -- Core connections
      vga_clk_i   : in    std_logic;
      vga_r_i     : in    std_logic_vector(7 downto 0);
      vga_g_i     : in    std_logic_vector(7 downto 0);
      vga_b_i     : in    std_logic_vector(7 downto 0);
      vga_hs_i    : in    std_logic; -- h sync
      vga_vs_i    : in    std_logic; -- v sync
      vga_de_i    : in    std_logic; -- display enable

      -- MEGA65 I/O connections
      clk         : in    std_logic;                  -- 100 MHz clock
      reset_n     : in    std_logic;                  -- CPU reset button (active low)
      hr_resetn   : out   std_logic;
      hr_csn      : out   std_logic;
      hr_ck       : out   std_logic;
      hr_rwds     : inout std_logic;
      hr_dq       : inout std_logic_vector(7 downto 0);
      kb_io0      : out   std_logic;
      kb_io1      : out   std_logic;
      kb_io2      : in    std_logic;
      hdmi_data_p : out   std_logic_vector(2 downto 0);
      hdmi_data_n : out   std_logic_vector(2 downto 0);
      hdmi_clk_p  : out   std_logic;
      hdmi_clk_n  : out   std_logic
   );
end entity framework;

architecture synthesis of framework is

   -- Output video mode (1280x720 @ 50 Hz, aspect ratio 16:9)
   -- CEA 861-D Format 19
   constant CLK_KHZ     : integer := 74250;     -- 74.25 MHz
   constant CEA_CTA_VIC : integer :=    19;
   constant H_PIXELS    : integer :=  1280;     -- horizontal display width in pixels
   constant V_PIXELS    : integer :=   720;     -- vertical display width in rows
   constant H_FP        : integer :=   440;     -- horizontal front porch width in pixels
   constant H_PULSE     : integer :=    40;     -- horizontal sync pulse width in pixels
   constant H_BP        : integer :=   220;     -- horizontal back porch width in pixels
   constant V_FP        : integer :=     5;     -- vertical front porch width in rows
   constant V_PULSE     : integer :=     5;     -- vertical sync pulse width in rows
   constant V_BP        : integer :=    20;     -- vertical back porch width in rows
   constant H_MAX       : integer :=  1980;
   constant V_MAX       : integer :=   750;
   constant H_POL       : std_logic := '1';     -- horizontal sync pulse polarity (1 = positive, 0 = negative)
   constant V_POL       : std_logic := '1';     -- vertical sync pulse polarity (1 = positive, 0 = negative)

   -- Auto-calculate display dimensions based on an 4:3 aspect ratio
   constant DISP_HMIN : integer := (H_PIXELS-V_PIXELS*4/3)/2;
   constant DISP_HMAX : integer := (H_PIXELS+V_PIXELS*4/3)/2-1;
   constant DISP_VMIN : integer := 0;
   constant DISP_VMAX : integer := V_PIXELS-1;

   -- Clocks
   signal o_clk      : std_logic;
   signal hdmi_clk   : std_logic;
   signal clk_x1     : std_logic;
   signal clk_x2     : std_logic;
   signal clk_x2_del : std_logic;
   signal kbd_clk    : std_logic;
   signal locked     : std_logic;
   alias  avl_clk    : std_logic is clk_x1;

   -- Resets
   signal avl_rst    : std_logic;
   signal kbd_rst    : std_logic;
   signal o_rst      : std_logic;

   -- HDMI video stream
   signal o_r        : unsigned(7 downto 0);
   signal o_g        : unsigned(7 downto 0);
   signal o_b        : unsigned(7 downto 0);
   signal o_hs       : std_logic;
   signal o_vs       : std_logic;
   signal o_de       : std_logic;

   constant C_AVM_ADDRESS_SIZE : integer := 19;
   constant C_AVM_DATA_SIZE    : integer := 128;

   -- Video rescaler interface to HyperRAM
   signal avl_write           : std_logic;
   signal avl_read            : std_logic;
   signal avl_waitrequest     : std_logic;
   signal avl_address         : std_logic_vector(C_AVM_ADDRESS_SIZE-1 DOWNTO 0);
   signal avl_burstcount      : std_logic_vector(7 DOWNTO 0);
   signal avl_byteenable      : std_logic_vector(C_AVM_DATA_SIZE/8-1 DOWNTO 0);
   signal avl_writedata       : std_logic_vector(C_AVM_DATA_SIZE-1 DOWNTO 0);
   signal avl_readdata        : std_logic_vector(C_AVM_DATA_SIZE-1 DOWNTO 0);
   signal avl_readdatavalid   : std_logic;

   constant C_DEBUG_MODE                     : boolean := true;
   attribute mark_debug                      : boolean;
   attribute mark_debug of avl_rst           : signal is C_DEBUG_MODE;
   attribute mark_debug of avl_write         : signal is C_DEBUG_MODE;
   attribute mark_debug of avl_read          : signal is C_DEBUG_MODE;
   attribute mark_debug of avl_waitrequest   : signal is C_DEBUG_MODE;
   attribute mark_debug of avl_address       : signal is C_DEBUG_MODE;
   attribute mark_debug of avl_burstcount    : signal is C_DEBUG_MODE;
   attribute mark_debug of avl_byteenable    : signal is C_DEBUG_MODE;
   attribute mark_debug of avl_writedata     : signal is C_DEBUG_MODE;
   attribute mark_debug of avl_readdata      : signal is C_DEBUG_MODE;
   attribute mark_debug of avl_readdatavalid : signal is C_DEBUG_MODE;

begin

   --------------------------------------------------------
   -- Instantiate clocks
   --------------------------------------------------------

   i_clk : entity work.clk
      port map (
         sys_clk_i    => clk,
         sys_rstn_i   => reset_n,
         o_clk_o      => o_clk,
         hdmi_clk_o   => hdmi_clk,
         clk_x1_o     => clk_x1,
         clk_x2_o     => clk_x2,
         clk_x2_del_o => clk_x2_del,
         kbd_clk_o    => kbd_clk,
         locked_o     => locked
      ); -- i_clk


   ----------------------------------
   -- Reset generation
   ----------------------------------

   i_xpm_cdc_async_rst_kbd : xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1
      )
      port map (
         src_arst  => not locked,     -- input
         dest_clk  => kbd_clk,        -- input
         dest_arst => kbd_rst         -- output
      ); -- i_xpm_cdc_async_rst_kbd

   i_xpm_cdc_async_rst_avl : xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1
      )
      port map (
         src_arst  => not locked,     -- input
         dest_clk  => avl_clk,        -- input
         dest_arst => avl_rst         -- output
      ); -- i_xpm_cdc_async_rst_avl

   i_xpm_cdc_async_rst_o : xpm_cdc_async_rst
      generic map (
         RST_ACTIVE_HIGH => 1
      )
      port map (
         src_arst  => not locked,     -- input
         dest_clk  => o_clk,          -- input
         dest_arst => o_rst           -- output
      ); -- i_xpm_cdc_async_rst_o


   --------------------------------------------------------
   -- Output HDMI generation
   --------------------------------------------------------

   i_hdmi_wrapper : entity work.hdmi_wrapper
      generic map (
         CEA_CTA_VIC => CEA_CTA_VIC
      )
      port map (
         o_clk_i       => o_clk,
         o_rst_i       => o_rst,
         o_r_i         => o_r,
         o_g_i         => o_g,
         o_b_i         => o_b,
         o_hs_i        => o_hs,
         o_vs_i        => o_vs,
         o_de_i        => o_de,
         hdmi_clk_i    => hdmi_clk,
         hdmi_data_p_o => hdmi_data_p,
         hdmi_data_n_o => hdmi_data_n,
         hdmi_clk_p_o  => hdmi_clk_p,
         hdmi_clk_n_o  => hdmi_clk_n
      ); -- i_hdmi_wrapper


   --------------------------------------------------------
   -- HyperRAM wrapper
   --------------------------------------------------------

   i_hyperram_wrapper : entity work.hyperram_wrapper
      generic map (
         N_DW => C_AVM_DATA_SIZE,
         N_AW => C_AVM_ADDRESS_SIZE
      )
      port map (
         avl_clk_i           => avl_clk,
         avl_rst_i           => avl_rst,
         avl_burstcount_i    => avl_burstcount,
         avl_writedata_i     => avl_writedata,
         avl_address_i       => avl_address,
         avl_write_i         => avl_write,
         avl_read_i          => avl_read,
         avl_byteenable_i    => avl_byteenable,
         avl_waitrequest_o   => avl_waitrequest,
         avl_readdata_o      => avl_readdata,
         avl_readdatavalid_o => avl_readdatavalid,
         clk_x2_i            => clk_x2,
         clk_x2_del_i        => clk_x2_del,
         hr_resetn_o         => hr_resetn,
         hr_csn_o            => hr_csn,
         hr_ck_o             => hr_ck,
         hr_rwds_io          => hr_rwds,
         hr_dq_io            => hr_dq
      ); -- i_hyperram_wrapper


   ----------------------------------
   -- Keyboard wrapper
   ----------------------------------

   i_keyboard_wrapper : entity work.keyboard_wrapper
      port map (
         kbd_clk_i  => kbd_clk,
         kbd_rst_i  => kbd_rst,
         kb_io0     => kb_io0,
         kb_io1     => kb_io1,
         kb_io2     => kb_io2,
         return_out => open
      ); -- i_keyboard_wrapper


   --------------------------------------------------------
   -- Instantiate video rescaler
   --------------------------------------------------------

   i_ascal : entity work.ascal
      generic map (
         MASK      => x"ff",
         RAMBASE   => (others => '0'),
         RAMSIZE   => x"0080_0000", -- = 8MB
         INTER     => true,
         HEADER    => true,
         DOWNSCALE => true,
         BYTESWAP  => true,
         PALETTE   => true,
         PALETTE2  => true,
         FRAC      => 4,
         OHRES     => 2048,
         IHRES     => 2048,
         N_DW      => C_AVM_DATA_SIZE,
         N_AW      => C_AVM_ADDRESS_SIZE,
         N_BURST   => 256  -- 256 bytes per burst
      )
      port map (
         i_r               => unsigned(vga_r_i),         -- input
         i_g               => unsigned(vga_g_i),         -- input
         i_b               => unsigned(vga_b_i),         -- input
         i_hs              => vga_hs_i,                  -- input
         i_vs              => vga_vs_i,                  -- input
         i_fl              => '0',                       -- input
         i_de              => vga_de_i,                  -- input
         i_ce              => '1',                       -- input
         i_clk             => vga_clk_i,                 -- input
         o_r               => o_r,                       -- output
         o_g               => o_g,                       -- output
         o_b               => o_b,                       -- output
         o_hs              => o_hs,                      -- output
         o_vs              => o_vs,                      -- output
         o_de              => o_de,                      -- output
         o_vbl             => open,                      -- output
         o_ce              => '1',                       -- input
         o_clk             => o_clk,                     -- input
         o_border          => X"886644",                 -- input
         o_fb_ena          => '0',                       -- input
         o_fb_hsize        => 0,                         -- input
         o_fb_vsize        => 0,                         -- input
         o_fb_format       => "000100",                  -- input
         o_fb_base         => x"0000_0000",              -- input
         o_fb_stride       => (others => '0'),           -- input
         pal1_clk          => '0',                       -- input
         pal1_dw           => x"000000000000",           -- input
         pal1_dr           => open,                      -- output
         pal1_a            => "0000000",                 -- input
         pal1_wr           => '0',                       -- input
         pal_n             => '0',                       -- input
         pal2_clk          => '0',                       -- input
         pal2_dw           => x"000000",                 -- input
         pal2_dr           => open,                      -- output
         pal2_a            => "00000000",                -- input
         pal2_wr           => '0',                       -- input
         o_lltune          => open,                      -- output
         iauto             => '1',                       -- input
         himin             => 0,                         -- input
         himax             => 0,                         -- input
         vimin             => 0,                         -- input
         vimax             => 0,                         -- input
         i_hdmax           => open,                      -- output
         i_vdmax           => open,                      -- output
         run               => '1',                       -- input
         freeze            => '0',                       -- input
         mode              => "00000",                   -- input
         htotal            => H_MAX,                     -- input
         hsstart           => H_PIXELS + H_FP,           -- input
         hsend             => H_PIXELS + H_FP + H_PULSE, -- input
         hdisp             => H_PIXELS,                  -- input
         vtotal            => V_MAX,                     -- input
         vsstart           => V_PIXELS + V_FP,           -- input
         vsend             => V_PIXELS + V_FP + V_PULSE, -- input
         vdisp             => V_PIXELS,                  -- input
         hmin              => DISP_HMIN,                 -- input
         hmax              => DISP_HMAX,                 -- input
         vmin              => DISP_VMIN,                 -- input
         vmax              => DISP_VMAX,                 -- input
         format            => "01",                      -- input
         poly_clk          => '0',                       -- input
         poly_dw           => (others => '0'),           -- input
         poly_a            => (others => '0'),           -- input
         poly_wr           => '0',                       -- input
         avl_clk           => avl_clk,                   -- input
         avl_waitrequest   => avl_waitrequest,           -- input
         avl_readdata      => avl_readdata,              -- input
         avl_readdatavalid => avl_readdatavalid,         -- input
         avl_burstcount    => avl_burstcount,            -- output
         avl_writedata     => avl_writedata,             -- output
         avl_address       => avl_address,               -- output
         avl_write         => avl_write,                 -- output
         avl_read          => avl_read,                  -- output
         avl_byteenable    => avl_byteenable,            -- output
         reset_na          => locked                     -- input
      ); -- i_ascal

end architecture synthesis;

