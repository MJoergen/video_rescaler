library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
end entity tb;

architecture simulation of tb is

   constant N_DW : natural range 64 to 128 := 128;
   constant N_AW : natural range 8 to 32 := 19;

   signal i_clk             : std_logic;
   signal o_clk             : std_logic;
   signal avl_clk           : std_logic;
   signal avl_clk_x2        : std_logic;
   signal avl_clk_x2_del    : std_logic;
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

   signal avm_waitrequest   : std_logic;
   signal avm_readdata      : std_logic_vector(15 downto 0);
   signal avm_readdatavalid : std_logic;
   signal avm_burstcount    : std_logic_vector(7 downto 0);
   signal avm_writedata     : std_logic_vector(15 downto 0);
   signal avm_address       : std_logic_vector(31 downto 0) := (others => '0');
   signal avm_write         : std_logic;
   signal avm_read          : std_logic;
   signal avm_byteenable    : std_logic_vector(1 downto 0);

   -- HyperRAM device interface
   signal hr_resetn         : std_logic;
   signal hr_csn            : std_logic;
   signal hr_ck             : std_logic;
   signal hr_rwds           : std_logic;
   signal hr_dq             : std_logic_vector(7 downto 0);
   signal hr_rwds_in        : std_logic;
   signal hr_dq_in          : std_logic_vector(7 downto 0);
   signal hr_rwds_out       : std_logic;
   signal hr_dq_out         : std_logic_vector(7 downto 0);
   signal hr_rwds_oe        : std_logic;
   signal hr_dq_oe          : std_logic;

   component s27kl0642 is
      port (
         DQ7      : inout std_logic;
         DQ6      : inout std_logic;
         DQ5      : inout std_logic;
         DQ4      : inout std_logic;
         DQ3      : inout std_logic;
         DQ2      : inout std_logic;
         DQ1      : inout std_logic;
         DQ0      : inout std_logic;
         RWDS     : inout std_logic;
         CSNeg    : in    std_logic;
         CK       : in    std_logic;
         CKn      : in    std_logic;
         RESETNeg : in    std_logic
      );
   end component s27kl0642;

begin


   --------------------------------------------------------
   -- Generate clocks and reset
   --------------------------------------------------------

   i_tb_clk : entity work.tb_clk
      port map (
         i_clk_o          => i_clk,
         o_clk_o          => o_clk,
         avl_clk_o        => avl_clk,
         avl_clk_x2_o     => avl_clk_x2,
         avl_clk_x2_del_o => avl_clk_x2_del,
         poly_clk_o       => poly_clk,
         pal_clk_o        => pal1_clk
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
   -- Convert from ascaler data width to HyperRAM data width
   --------------------------------------------------------

   i_avm_decrease : entity work.avm_decrease
      generic map (
         G_SLAVE_ADDRESS_SIZE  => N_AW,
         G_SLAVE_DATA_SIZE     => N_DW,
         G_MASTER_ADDRESS_SIZE => 22,  -- HyperRAM size is 4 MWords = 8 MBbytes.
         G_MASTER_DATA_SIZE    => 16
      )
      port map (
         clk_i                 => avl_clk,
         rst_i                 => not reset_na,
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
         m_avm_address_o       => avm_address(21 downto 0), -- MSB defaults to zero
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
         clk_x1_i            => avl_clk,
         clk_x2_i            => avl_clk_x2,
         clk_x2_del_i        => avl_clk_x2_del,
         rst_i               => not reset_na,
         avm_write_i         => avm_write,
         avm_read_i          => avm_read,
         avm_address_i       => avm_address,
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


   ---------------------------------------------------------
   -- Instantiate HyperRAM simulation model
   ---------------------------------------------------------

   i_s27kl0642 : s27kl0642
      port map (
         DQ7      => hr_dq(7),
         DQ6      => hr_dq(6),
         DQ5      => hr_dq(5),
         DQ4      => hr_dq(4),
         DQ3      => hr_dq(3),
         DQ2      => hr_dq(2),
         DQ1      => hr_dq(1),
         DQ0      => hr_dq(0),
         RWDS     => hr_rwds,
         CSNeg    => hr_csn,
         CK       => hr_ck,
         CKn      => not hr_ck,
         RESETNeg => hr_resetn
      ); -- i_s27kl0642

end architecture simulation;

