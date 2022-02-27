library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity democore_audio is
   port (
      audio_clk_i   : in  std_logic;
      audio_left_o  : out std_logic_vector(15 downto 0);
      audio_right_o : out std_logic_vector(15 downto 0)
   );
end democore_audio;

architecture synthesis of democore_audio is

   signal audio : std_logic_vector(15 downto 0);
   signal balance : std_logic_vector(15 downto 0);

begin

   p_audio : process (audio_clk_i)
   begin
      if rising_edge(audio_clk_i) then
         audio <= std_logic_vector(unsigned(audio) + 1000);
      end if;
   end process p_audio;

   p_balance : process (audio_clk_i)
   begin
      if rising_edge(audio_clk_i) then
         balance <= std_logic_vector(unsigned(balance) + 1);
      end if;
   end process p_balance;

   audio_left_o  <= audio when balance(15) = '1' else (others => '0');
   audio_right_o <= audio when balance(15) = '0' else (others => '0');

end architecture synthesis;

