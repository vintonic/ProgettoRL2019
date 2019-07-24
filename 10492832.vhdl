-- ———————————————————————————
-- Company: 
-- Engineer: VITTORIO ANTONICELLI ( COD.PERSONA: 10492832, N.MATRICOLA: 846674 )
-- 
-- Create Date: 14.07.2019 16:22:40
-- Design Name: 
-- Module Name: 10492832 - Behavioral
-- Project Name: 10492832
--———————————————————————————


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package constants is

    -- indirizzi di maschere di ingresso e uscita
    constant mask_in_address : std_logic_vector := "0000000000000000" ;
    constant mask_out_address : std_logic_vector := "0000000000010011" ;
    -- indirizzo iniziale del gruppo di 8 punti
    constant first_point_x_address : std_logic_vector := "0000000000000001" ;
    -- indirizzi delle coordinate del punto dal quale calcolare la distanza
    constant comp_point_x_address : std_logic_vector := "0000000000010001" ;
    constant comp_point_y_address : std_logic_vector := "0000000000010010" ;

end constants;
 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use work.constants.all;

entity project_reti_logiche is
    port (
        i_clk         : in  std_logic;
        i_start       : in  std_logic;
        i_rst         : in  std_logic;
        i_data        : in  std_logic_vector(7 downto 0);
        o_address     : out std_logic_vector(15 downto 0);
        o_done        : out std_logic;
        o_en          : out std_logic;
        o_we          : out std_logic;
        o_data        : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type S is (reset_state, save_data_state, mask_in_check_state, read_point_x_state, read_point_y_state, dist_calc_state, dist_check_state, end_check_state, set_result_state, ending_state);

    -- stato attuale della macchina a stati
    signal current_state: S;

    -- indirizzo da cui si sta scrivendo o leggendo attualmente
    signal current_address: std_logic_vector(15 downto 0);
    -- contatore di quanti punti sono già stati analizzati
    signal point_counter: std_logic_vector(7 downto 0);
    -- coordinate punto da comparare
    signal comp_point_x: std_logic_vector(7 downto 0);
    signal comp_point_y: std_logic_vector(7 downto 0);
    -- coordinate punto attuale sul quale si sta misurando la distanza
    signal curr_point_x: std_logic_vector(7 downto 0);
    signal curr_point_y: std_logic_vector(7 downto 0);
    -- distanza minima trovata e distanza attuale del punto considerato
    signal min_dist: std_logic_vector(8 downto 0);
    signal curr_dist: std_logic_vector(8 downto 0);
    -- mask in e mask out
    signal mask_in: std_logic_vector(7 downto 0);
    signal mask_out: std_logic_vector(7 downto 0);

    begin

    UNIQUE_PROCESS:process(i_clk)
    begin

        if i_clk'event and i_clk = '0' then
        
            if i_rst = '1' then
    
                -- stato attuale della macchina a stati
                current_state <= reset_state;            
                
            else

                case current_state is
                        
                when reset_state => 
                
                    -- azzero gli output
                    o_en <= '0';
                    o_we <= '0';
                    o_data <= "00000000";
                    o_done <= '0';
        
                    -- stato attuale della macchina a stati
                    current_state <= reset_state;

                    -- impostazione indirizzo per acquisire il prossimo dato [mask_in_address]
                    current_address <= mask_in_address;
                    o_address <= mask_in_address; 
                    -- contatore di quanti punti sono già stati analizzati
                    point_counter <= "00000000";
                    -- coordinate punto da comparare
                    comp_point_x <= "00000000";
                    comp_point_y <= "00000000";
                    -- coordinate punto attuale sul quale si sta misurando la distanza
                    curr_point_x <= "00000000";
                    curr_point_y <= "00000000";
                    -- distanza minima trovata e distanza attuale del punto considerato
                    min_dist <= "111111111";
                    curr_dist <= "000000000";
                    -- mask in e mask out
                    mask_in <= "00000000";
                    mask_out <= "00000000";

                    -- start ricevuto (clock 0)
                    if i_start = '1' then
                        -- enable della ram
                        o_en <= '1';
                        -- cambio stato [acquisizione maschera ingresso mask_in_address]
                        current_state <= save_data_state;
                    end if;
            
                when save_data_state =>
            
                    -- acquisione maschera di ingresso (clock 1)
                    if current_address = mask_in_address then
                        -- salvataggio dato [mask_in]
                        mask_in <= i_data;
                        -- impostazione indirizzo per acquisire il prossimo dato [comp_point_x]
                        current_address <= comp_point_x_address;
                        o_address <= comp_point_x_address; 

                    -- acquisione x del punto da computare (clock 2)
                    elsif current_address = comp_point_x_address then    
                        -- salvataggio dato [comp_point_x]
                        comp_point_x <= i_data;
                        -- impostazione indirizzo per acquisire il prossimo dato [comp_point_y]
                        current_address <= current_address + 1;
                        o_address <= current_address + 1; 
                    
                    -- acquisione y del punto da computare (clock 3)
                    else   
                        -- salvataggio dato [comp_point_y]
                        comp_point_y <= i_data;
                        -- impostazione indirizzo per acquisire il primo centroide (iniziando da curr_point_x)
                        current_address <= first_point_x_address;
                        o_address <= first_point_x_address;
                        -- cambio stato [check della maschera di ingresso]
                        current_state <= mask_in_check_state;
                    end if;    
                
                when mask_in_check_state =>
                    -- controllo se la maschera di ingresso sia 0 per il centroide attuale
                    if mask_in(to_integer(unsigned(point_counter))) = '0' then
                        -- salto il centroide attuale e imposto indirizzo per acquisire il prossimo centroide (iniziando da curr_point_x)
                        current_address <= current_address + 2;
                        o_address <= current_address + 2;
                        -- cambio stato: verifica fine iterazione sui centroidi
                        current_state <= end_check_state;
                    -- caso in cui la maschera di ingresso è 1 per questo centroide
                    else
                        -- cambio stato [acquisizione del centroide attuale, iniziando da curr_point_x]
                        current_state <= read_point_x_state;
                    end if;

                when read_point_x_state =>
                    -- salvataggio dato [curr_point_x]
                    curr_point_x <= i_data;
                    -- impostazione indirizzo per acquisire il prossimo dato [curr_point_y]
                    current_address <= current_address + 1;
                    o_address <= current_address + 1;
                    -- cambio stato [acquisizione di curr_point_y]
                    current_state <= read_point_y_state;

                when read_point_y_state =>
                    -- salvataggio dato [curr_point_y]
                    curr_point_y <= i_data;
                    -- impostazione indirizzo per acquisire il prossimo centroide [comp_point_y]
                    current_address <= current_address + 1;
                    o_address <= current_address + 1;
                    -- cambio stato [calcolo della distanza]
                    current_state <= dist_calc_state;

                when dist_calc_state =>

                    -- calcolo della distanza 
                    curr_dist <= std_logic_vector(abs(signed('0' & comp_point_x) - signed('0' & curr_point_x)) + abs(signed('0' & comp_point_y) - signed('0' & curr_point_y)));
                    -- cambio stato [check della distanza]
                    current_state <= dist_check_state;

                when dist_check_state =>
                    
                    -- check della distanza
                    if curr_dist < min_dist then
                        -- reset maschera in uscita
                        mask_out <= "00000000";
                        -- aggiorno la distanza minima
                        min_dist <= curr_dist;
                    elsif curr_dist = min_dist then
                        mask_out(to_integer(unsigned(point_counter))) <= '1';
                        -- aggiorno la maschera in uscita
                        current_state <= end_check_state;
                    else
                        -- cambio stato: verifica fine iterazione sui centroidi
                        current_state <= end_check_state;
                    end if;
                
                when end_check_state =>

                    -- verifica fine iterazione sui centroidi
                    if point_counter = "00000111" then
                        -- impostazione indirizzo per scrivere il risultato in ram [mask_out]
                        current_address <= mask_out_address;
                        o_address <= mask_out_address;
                        -- enable scrittura in ram
                        o_we <= '1';
                        -- mando il risultato [mask_out] sull'uscita [o_data], per scriverlo sulla ram
                        o_data <= mask_out;
                        -- cambio stato: scrivo risultato
                        current_state <= set_result_state;
                    else
                        -- aggiorna il contatore dell'iterazione sui centroidi
                        point_counter <= point_counter +1;
                        -- cambio stato: elabora il prossimo centroide
                        current_state <= mask_in_check_state;
                    end if;
        
                when set_result_state =>
                
                    -- cambio stato: fine elaborazione
                    current_state <= ending_state;
        
                when ending_state =>

                    if i_start = '0' then
                        o_done <= '0';
                        current_state <= reset_state;
                    else
                        o_done <= '1';
                        o_we <= '0'; 
                    end if;
                
                end case;

            end if;

        end if;
    
    end process;    
        
end Behavioral;
