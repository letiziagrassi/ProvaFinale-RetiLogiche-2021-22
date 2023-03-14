-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Fabio Salice - Anno 2021/2022
-- Letizia Grassi (Codice Persona 10577745 Matricola 886555)
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
  port (
  i_clk     : in std_logic;
  i_rst     : in std_logic;
  i_start   : in std_logic;
  i_data    : in std_logic_vector(7 downto 0);
  o_address : out std_logic_vector(15 downto 0);
  o_done    : out std_logic;
  o_en      : out std_logic;
  o_we      : out std_logic;
  o_data    : out std_logic_vector(7 downto 0)
  );
end project_reti_logiche;

architecture behavioral of project_reti_logiche is
  type state_type is (SLEEP, READ_N, SET_N, SET_COUNTERS, READ_FIRST_WORD, EXECUTE_7, EXECUTE_6, EXECUTE_5, EXECUTE_4, EXECUTE_3, EXECUTE_2, EXECUTE_1, EXECUTE_0, DONE);
  signal current_state: state_type := SLEEP;
  signal uk : std_logic;
  signal uk1 : std_logic:='0';
  signal uk2 : std_logic:='0';

  procedure encode_and_shift (signal uk : in std_logic;
                      signal uk1, uk2 : inout std_logic;
                      variable pk1, pk2 : out std_logic) is
  begin
    pk1 := std_logic(uk xor uk2);
    pk2 := std_logic((uk xor uk2) xor uk1);
    uk2 <= uk1;
    uk1 <= uk;
  end procedure encode_and_shift;

begin
  mainProcess: process(i_clk, i_rst)
  variable n_saved : boolean;
  variable c_in, c_out : unsigned (10 downto 0);
  variable n : unsigned (7 downto 0);
  variable word : std_logic_vector(7 downto 0);
  variable odds, evens : std_logic_vector(7 downto 0);
  constant OFFSET : unsigned := "00000";
  constant NUM_OF_WORDS : unsigned := "00000000000";
  constant FIRST_INPUT_ADDRESS : unsigned := "00000000001";
  constant FIRST_OUTPUT_ADDRESS : unsigned :="01111100111";--indirizzo 999.

    begin

      if(i_rst = '1') then
        n := "00000000";
        word := "00000000";
        n_saved := false;
        o_we <= '0';
        o_en <= '0';
        o_done <= '0';
        o_address <= "0000000000000000";
        uk2 <= '0';
        uk1 <= '0';
        current_state <= SLEEP;
      else if(i_clk'event and i_clk='1') then
        CASE current_state is

          when SLEEP =>
            if(i_start = '1') then
              o_we <= '0';
              o_en <= '1';
              o_address <= std_logic_vector(OFFSET & NUM_OF_WORDS);
              current_state <= READ_N;
            end if;

           WHEN READ_N =>
            current_state <= SET_N;

          when SET_N =>
            if(not n_saved) then
              n := unsigned(i_data);
              n_saved := true;
              o_en <= '0';
              o_we <= '0';
            end if;
            if (to_integer(n) = 0) then
                current_state <= DONE;
                o_we <= '0';
                o_en <= '0';
              else
                current_state <= SET_COUNTERS;
                o_we <= '0';
                o_en <= '1';
            end if;
            o_address <= std_logic_vector(OFFSET) & std_logic_vector(FIRST_INPUT_ADDRESS);

            when SET_COUNTERS=>
                c_in := "00000000001";
                c_out := "00000000000";
                uk2 <= '0';
                uk1 <= '0';
                current_state <= READ_FIRST_WORD;

          when READ_FIRST_WORD =>
            word := i_data;
            o_we <= '0';
            o_en <= '0';
            uk <= word(7);
            current_state <= EXECUTE_7;

          when EXECUTE_7 =>
            if(to_integer(c_in) =  to_integer(n)+1) then
                o_done <= '1';
                current_state <= DONE;
            else
                encode_and_shift(uk, uk1, uk2, odds(7), evens(7));
                o_we <='0';
                o_en <='0';
                o_done <= '0';
                uk <= word(6);
                current_state <= EXECUTE_6;
             end if;

          when EXECUTE_6 =>
            encode_and_shift(uk, uk1, uk2, odds(6), evens(6));
            o_we <= '0';
            o_en <= '0';
            uk <= std_logic(word(5));
            current_state <= EXECUTE_5;

          when EXECUTE_5 =>
            encode_and_shift(uk, uk1, uk2, odds(5), evens(5));
            o_we <= '0';
            o_en <= '0';
            uk <= std_logic(word(4));
            current_state <= EXECUTE_4;

          when EXECUTE_4 =>
            encode_and_shift(uk, uk1, uk2, odds(4), evens(4));
            o_we <='1';
            o_en <='1';
            c_out :=c_out + "00000000001";
            o_data <= odds(7)&evens(7)&odds(6)&evens(6)&odds(5)&evens(5)&odds(4)&evens(4);
            o_address <= std_logic_vector(OFFSET & (FIRST_OUTPUT_ADDRESS + c_out));
            uk <= std_logic(word(3));
            current_state <= EXECUTE_3;

          when EXECUTE_3 =>
            encode_and_shift(uk, uk1, uk2, odds(3), evens(3));
            o_we <= '0';
            o_en <= '0';
            uk <= std_logic(word(2));
            current_state <= EXECUTE_2;

          when EXECUTE_2 =>
            encode_and_shift(uk, uk1, uk2, odds(2), evens(2));
            o_we <='0';
            o_en <='1';
            o_address <=std_logic_vector(OFFSET & (FIRST_INPUT_ADDRESS + c_in));
            uk <= std_logic(word(1));
            current_state <= EXECUTE_1;

          when EXECUTE_1 =>
            encode_and_shift(uk, uk1, uk2, odds(1), evens(1));
            uk <= std_logic(word(0));
            current_state <= EXECUTE_0;

          when EXECUTE_0 =>
            encode_and_shift(uk, uk1, uk2, odds(0), evens(0));
            c_in := c_in + "00000000001";
            c_out :=c_out +"00000000001";
            o_we <='1';
            o_en <='1';
            word := std_logic_vector(i_data);
            o_data <= odds(3)&evens(3)&odds(2)&evens(2)&odds(1)&evens(1)&odds(0)&evens(0);
            o_address <= std_logic_vector(OFFSET & (FIRST_OUTPUT_ADDRESS + c_out));
            uk <= std_logic(word(7));
            current_state <= EXECUTE_7;

          when DONE =>
            if(i_start = '0') then
              o_done <= '0';
              current_state <= SLEEP;
            else
                o_done <= '1';
                current_state <= DONE;
            end if;
              o_address <= "0000000000000000";
              c_in := "00000000000";
              c_out := "00000000000";
              n_saved:= false;
              o_we <='0';
              o_en <='0';
          end case;
      end if;
    end if;
  end process;
end behavioral;
