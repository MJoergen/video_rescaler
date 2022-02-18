library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_clk is
   port (
      i_clk_o          : out std_logic;
      o_clk_o          : out std_logic;
      avl_clk_o        : out std_logic;
      avl_clk_x2_o     : out std_logic;
      avl_clk_x2_del_o : out std_logic;
      poly_clk_o       : out std_logic;
      pal_clk_o        : out std_logic
   );
end entity tb_clk;

architecture simulation of tb_clk is

   constant C_I_CLK_PERIOD    : time := 40 ns;     -- 25 MHz
   constant C_O_CLK_PERIOD    : time := 13.468 ns; -- 74.25 MHz
   constant C_AVL_CLK_PERIOD  : time := 10 ns;     -- 100 MHz
   constant C_POLY_CLK_PERIOD : time := 10 ns;
   constant C_PAL_CLK_PERIOD  : time := 10 ns;

begin

   p_i_clk : process
   begin
      i_clk_o <= '1';
      wait for C_I_CLK_PERIOD/2;
      i_clk_o <= '0';
      wait for C_I_CLK_PERIOD/2;
   end process p_i_clk;

   p_o_clk : process
   begin
      o_clk_o <= '1';
      wait for C_O_CLK_PERIOD/2;
      o_clk_o <= '0';
      wait for C_O_CLK_PERIOD/2;
   end process p_o_clk;

   p_avl_clk : process
   begin
      avl_clk_o <= '1';
      wait for C_AVL_CLK_PERIOD/2;
      avl_clk_o <= '0';
      wait for C_AVL_CLK_PERIOD/2;
   end process p_avl_clk;

   p_avl_clk_x2 : process
   begin
      avl_clk_x2_o <= '1';
      wait for C_AVL_CLK_PERIOD/4;
      avl_clk_x2_o <= '0';
      wait for C_AVL_CLK_PERIOD/4;
   end process p_avl_clk_x2;

   avl_clk_x2_del_o <= not avl_clk_x2_o;

   poly_clk_o <= '0';
   pal_clk_o  <= '0';

end architecture simulation;

