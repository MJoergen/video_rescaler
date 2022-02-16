library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
end entity tb;

architecture simulation of tb is

   constant N_DW : natural range 64 to 128 := 128;
   constant N_AW : natural range 8 to 32 := 22;

   signal i_clk             : std_logic;
   signal o_clk             : std_logic;
   signal avl_clk           : std_logic;
   signal poly_clk          : std_logic;
   signal pal1_clk          : std_logic;
   signal reset_na          : std_logic;

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

begin


   --------------------------------------------------------
   -- Generate clocks and reset
   --------------------------------------------------------

   i_tb_clk : entity work.tb_clk
      port map (
         i_clk_o    => i_clk,
         o_clk_o    => o_clk,
         avl_clk_o  => avl_clk,
         poly_clk_o => poly_clk,
         pal_clk_o  => pal1_clk
      ); -- i_tb_clk

   reset_na <= '0', '1' after 1 us;


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
         reset_na          => reset_na,
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
   -- Instantiate Avalon Memory
   --------------------------------------------------------

   i_avm_memory : entity work.avm_memory
      generic map (
         G_ADDRESS_SIZE => 22,
         G_DATA_SIZE    => 128
      )
      port map (
         clk_i               => avl_clk,
         rst_i               => '0',
         avm_write_i         => avl_write,
         avm_read_i          => avl_read,
         avm_address_i       => avl_address,
         avm_writedata_i     => avl_writedata,
         avm_byteenable_i    => avl_byteenable,
         avm_burstcount_i    => avl_burstcount,
         avm_readdata_o      => avl_readdata,
         avm_readdatavalid_o => avl_readdatavalid,
         avm_waitrequest_o   => avl_waitrequest
      ); -- i_avm_memory

end architecture simulation;

