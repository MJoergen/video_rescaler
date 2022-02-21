library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keyboard_wrapper is
   port (
      kbd_clk_i  : in  std_logic;
      kbd_rst_i  : in  std_logic;
      return_out : out std_logic;     -- Active low

      -- MEGA65 keyboard
      kb_io0     : out std_logic;
      kb_io1     : out std_logic;
      kb_io2     : in  std_logic
   );
end entity keyboard_wrapper;

architecture synthesis of keyboard_wrapper is

begin


   i_keyboard : entity work.keyboard
      port map (
         cpuclock    => kbd_clk_i,
         flopled     => '0',
         powerled    => '1',
         kio8        => kb_io0,
         kio9        => kb_io1,
         kio10       => kb_io2,
         delete_out  => open,
         return_out  => return_out,
         fastkey_out => open
      ); -- i_keyboard

end architecture synthesis;

