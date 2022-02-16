library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyboard_wrapper is
   port (
      clk     : in    std_logic;                  -- 100 MHz clock
      reset_n : in    std_logic;                  -- CPU reset button (active low)

      -- MEGA65 keyboard
      kb_io0  : out   std_logic;
      kb_io1  : out   std_logic;
      kb_io2  : in    std_logic
   );
end entity keyboard_wrapper;

architecture synthesis of keyboard_wrapper is

   -- Keyboard
   signal kbd_clk : std_logic;

begin


   i_clk_kbd : entity work.clk_kbd
      port map (
         sys_clk_i  => clk,
         sys_rstn_i => reset_n,
         kbd_clk_o  => kbd_clk
      ); -- i_clk_kbd


   i_keyboard : entity work.keyboard
      port map (
         cpuclock    => kbd_clk,
         flopled     => '0',
         powerled    => '1',
         kio8        => kb_io0,
         kio9        => kb_io1,
         kio10       => kb_io2,
         delete_out  => open,
         return_out  => open,
         fastkey_out => open
      ); -- i_keyboard

end architecture synthesis;

