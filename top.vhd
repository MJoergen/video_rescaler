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

   constant N_DW : natural range 64 to 128 := 128;
   constant N_AW : natural range 8 to 32 := 19;

   signal i_clk             : std_logic;
   signal o_clk             : std_logic;
   signal avl_clk           : std_logic;
   signal poly_clk          : std_logic := '0';
   signal pal1_clk          : std_logic := '0';

   signal o_r               : unsigned(7 downto 0);
   signal o_g               : unsigned(7 downto 0);
   signal o_b               : unsigned(7 downto 0);
   signal o_hs              : std_logic; -- h sync
   signal o_vs              : std_logic; -- v sync
   signal o_de              : std_logic; -- display enable
   signal o_vbl             : std_logic; -- v blank

   signal avl_waitrequest   : std_logic;
   signal avl_readdata      : std_logic_vector(N_DW-1 downto 0);
   signal avl_readdatavalid : std_logic;
   signal avl_burstcount    : std_logic_vector(7 downto 0);
   signal avl_writedata     : std_logic_vector(N_DW-1 downto 0);
   signal avl_address       : std_logic_vector(N_AW-1 downto 0);
   signal avl_write         : std_logic;
   signal avl_read          : std_logic;
   signal avl_byteenable    : std_logic_vector(N_DW/8-1 downto 0);

   constant DEBUG_MODE                       : boolean := false;
   attribute mark_debug                      : boolean;
   attribute mark_debug of o_r               : signal is DEBUG_MODE;
   attribute mark_debug of o_g               : signal is DEBUG_MODE;
   attribute mark_debug of o_b               : signal is DEBUG_MODE;
   attribute mark_debug of o_hs              : signal is DEBUG_MODE;
   attribute mark_debug of o_vs              : signal is DEBUG_MODE;
   attribute mark_debug of o_de              : signal is DEBUG_MODE;

   attribute mark_debug of avl_waitrequest   : signal is DEBUG_MODE;
   attribute mark_debug of avl_readdata      : signal is DEBUG_MODE;
   attribute mark_debug of avl_readdatavalid : signal is DEBUG_MODE;
   attribute mark_debug of avl_burstcount    : signal is DEBUG_MODE;
   attribute mark_debug of avl_writedata     : signal is DEBUG_MODE;
   attribute mark_debug of avl_address       : signal is DEBUG_MODE;
   attribute mark_debug of avl_write         : signal is DEBUG_MODE;
   attribute mark_debug of avl_read          : signal is DEBUG_MODE;
   attribute mark_debug of avl_byteenable    : signal is DEBUG_MODE;

begin

   --------------------------------------------------------
   -- Instantiate DUT
   --------------------------------------------------------

   i_sys : entity work.sys
      generic map (
         N_DW => N_DW,
         N_AW => N_AW
      )
      port map (
         i_clk             => i_clk,
         o_clk             => o_clk,
         avl_clk           => avl_clk,
         poly_clk          => poly_clk,
         pal1_clk          => pal1_clk,
         reset_na          => reset_n,
         o_r               => o_r,
         o_g               => o_g,
         o_b               => o_b,
         o_hs              => o_hs,
         o_vs              => o_vs,
         o_de              => o_de,
         o_vbl             => o_vbl,
         avl_write         => avl_write,
         avl_read          => avl_read,
         avl_address       => avl_address,
         avl_writedata     => avl_writedata,
         avl_byteenable    => avl_byteenable,
         avl_burstcount    => avl_burstcount,
         avl_readdata      => avl_readdata,
         avl_readdatavalid => avl_readdatavalid,
         avl_waitrequest   => avl_waitrequest
      ); -- i_sys


   --------------------------------------------------------
   -- Output HDMI generation
   --------------------------------------------------------

   i_hdmi_wrapper : entity work.hdmi_wrapper
      port map (
         clk         => clk,
         reset_n     => reset_n,
         i_clk       => i_clk,
         o_r         => o_r,
         o_g         => o_g,
         o_b         => o_b,
         o_hs        => o_hs,
         o_vs        => o_vs,
         o_de        => o_de,
         o_vbl       => o_vbl,
         o_clk       => o_clk,
         hdmi_data_p => hdmi_data_p,
         hdmi_data_n => hdmi_data_n,
         hdmi_clk_p  => hdmi_clk_p,
         hdmi_clk_n  => hdmi_clk_n
      ); -- i_hdmi_wrapper


   --------------------------------------------------------
   -- HyperRAM wrapper
   --------------------------------------------------------

   i_hyperram_wrapper : entity work.hyperram_wrapper
      generic map (
         N_DW => N_DW,
         N_AW => N_AW
      )
      port map (
         sys_clk_i           => clk,
         sys_reset_n_i       => reset_n,
         avl_clk_o           => avl_clk,  -- output
         avl_rst_o           => open,
         avl_burstcount_i    => avl_burstcount,
         avl_writedata_i     => avl_writedata,
         avl_address_i       => avl_address,
         avl_write_i         => avl_write,
         avl_read_i          => avl_read,
         avl_byteenable_i    => avl_byteenable,
         avl_waitrequest_o   => avl_waitrequest,
         avl_readdata_o      => avl_readdata,
         avl_readdatavalid_o => avl_readdatavalid,
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
         clk     => clk,
         reset_n => reset_n,
         kb_io0  => kb_io0,
         kb_io1  => kb_io1,
         kb_io2  => kb_io2
      ); -- i_keyboard_wrapper

end architecture synthesis;

