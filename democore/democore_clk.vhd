library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity democore_clk is
   port (
      sys_clk_i   : in  std_logic;
      sys_rstn_i  : in  std_logic;
      audio_clk_o : out std_logic;
      audio_rst_o : out std_logic;
      vga_clk_o   : out std_logic;
      vga_rst_o   : out std_logic
   );
end democore_clk;

architecture synthesis of democore_clk is

   -- Clock generation
   constant C_VGA_COUNTER_WRAP   : natural := 108_000_000 / 27_000_000;
   constant C_AUDIO_COUNTER_WRAP : natural := 108_000_000 / 48_000;

   signal clkfb       : std_logic;
   signal clkfb_mmcm  : std_logic;
   signal clk108_mmcm : std_logic;
   signal clk108      : std_logic;
   signal locked      : std_logic;

   signal vga_counter   : std_logic_vector(1 downto 0);
   signal audio_counter : std_logic_vector(11 downto 0);

begin

   -- VCO frequency range for Artix 7 speed grade -1 : 600 MHz - 1200 MHz
   -- f_VCO = f_CLKIN * CLKFBOUT_MULT_F / DIVCLK_DIVIDE
   i_clk_108 : MMCME2_ADV
      generic map (
         BANDWIDTH            => "OPTIMIZED",
         CLKOUT4_CASCADE      => FALSE,
         COMPENSATION         => "ZHOLD",
         STARTUP_WAIT         => FALSE,
         CLKIN1_PERIOD        => 10.0,       -- INPUT @ 100 MHz
         REF_JITTER1          => 0.010,
         DIVCLK_DIVIDE        => 1,
         CLKFBOUT_MULT_F      => 10.125,    -- f_VCO = (100 MHz / 1) x 10.125 = 1012.5 MHz
         CLKFBOUT_PHASE       => 0.000,
         CLKFBOUT_USE_FINE_PS => FALSE,
         CLKOUT0_DIVIDE_F     => 9.375,     -- clk0 @ 108.00 MHz
         CLKOUT0_PHASE        => 0.000,
         CLKOUT0_DUTY_CYCLE   => 0.500,
         CLKOUT0_USE_FINE_PS  => FALSE
      )
      port map (
         -- Output clocks
         CLKFBOUT            => clkfb_mmcm,
         CLKOUT0             => clk108_mmcm,
         -- Input clock control
         CLKFBIN             => clkfb,
         CLKIN1              => sys_clk_i,
         CLKIN2              => '0',
         -- Tied to always select the primary input clock
         CLKINSEL            => '1',
         -- Ports for dynamic reconfiguration
         DADDR               => (others => '0'),
         DCLK                => '0',
         DEN                 => '0',
         DI                  => (others => '0'),
         DO                  => open,
         DRDY                => open,
         DWE                 => '0',
         -- Ports for dynamic phase shift
         PSCLK               => '0',
         PSEN                => '0',
         PSINCDEC            => '0',
         PSDONE              => open,
         -- Other control and status signals
         LOCKED              => locked,
         CLKINSTOPPED        => open,
         CLKFBSTOPPED        => open,
         PWRDWN              => '0',
         RST                 => not sys_rstn_i
      ); -- i_clk_108

   -------------------------------------
   -- Clock buffering
   -------------------------------------

   i_bufg_clkfb : BUFG
      port map (
         I => clkfb_mmcm,
         O => clkfb
      ); -- i_bufg_clkfb

   i_bufg_clk108 : BUFG
      port map (
         I => clk108_mmcm,
         O => clk108
      ); -- i_bufg_clk108

   p_vga_clk : process (clk108)
   begin
      if rising_edge(clk108) then
         if unsigned(vga_counter) = 0 then
            vga_counter <= std_logic_vector(to_unsigned(C_VGA_COUNTER_WRAP-1, vga_counter'length));
         else
            vga_counter <= std_logic_vector(unsigned(vga_counter) - 1);
         end if;
      end if;
   end process;

   vga_clk_o <= vga_counter(vga_counter'left);

   p_audio_clk : process (clk108)
   begin
      if rising_edge(clk108) then
         if unsigned(audio_counter) = 0 then
            audio_counter <= std_logic_vector(to_unsigned(C_AUDIO_COUNTER_WRAP-1, audio_counter'length));
         else
            audio_counter <= std_logic_vector(unsigned(audio_counter) - 1);
         end if;
      end if;
   end process;

   audio_clk_o <= audio_counter(audio_counter'left);


   -------------------------------------
   -- Reset generation
   -------------------------------------

   i_xpm_cdc_sync_rst_video : xpm_cdc_sync_rst
      generic map (
         RST_ACTIVE_HIGH => 1
      )
      port map (
         src_rst  => not (sys_rstn_i and locked),  -- 1-bit input: Source reset signal.
         dest_clk => vga_clk_o,                    -- 1-bit input: Destination clock.
         dest_rst => vga_rst_o                     -- 1-bit output: src_rst synchronized to the destination clock domain.
                                                   -- This output is registered.
      ); -- i_xpm_cdc_sync_rst_video

   i_xpm_cdc_sync_rst_audio : xpm_cdc_sync_rst
      generic map (
         RST_ACTIVE_HIGH => 1
      )
      port map (
         src_rst  => not (sys_rstn_i and locked),  -- 1-bit input: Source reset signal.
         dest_clk => audio_clk_o,                  -- 1-bit input: Destination clock.
         dest_rst => audio_rst_o                   -- 1-bit output: src_rst synchronized to the destination clock domain.
                                                   -- This output is registered.
      ); -- i_xpm_cdc_sync_rst_audio

end architecture synthesis;

