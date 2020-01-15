----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/27/2019 02:22:39 PM
-- Design Name: 
-- Module Name: unitb - unitb_arch
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;

use STD.TEXTIO.all;
use IEEE.STD_LOGIC_TEXTIO.all;

entity unitb is
end unitb;

architecture unitb_arch of unitb is
    constant c_CLOCK_PERIOD: time := 100 ns;
    signal tb_done: std_logic;
    signal mem_address: std_logic_vector (15 downto 0) := (others => '0');
    signal tb_rst: std_logic := '0';
    signal tb_start: std_logic := '0';
    signal tb_clk: std_logic := '0';
    signal mem_o_data, mem_i_data: std_logic_vector (7 downto 0);

    signal enable_wire: std_logic;
    signal mem_we: std_logic;
    signal ext_en: std_logic;
    signal ext_we: std_logic;

    signal input_data, set_data: std_logic_vector (7 downto 0);
    signal input_address, set_address: std_logic_vector (15 downto 0);
    signal input_select_internal: std_logic;

    type ram_type is array (65535 downto 0) of std_logic_vector (7 downto 0);
    signal RAM: ram_type;

    component project_reti_logiche is
        port (
                 i_clk: in std_logic;
                 i_start: in std_logic;
                 i_rst: in std_logic;
                 i_data: in std_logic_vector(7 downto 0);
                 o_address: out std_logic_vector(15 downto 0);
                 o_done: out std_logic;
                 o_en: out std_logic;
                 o_we: out std_logic;
                 o_data: out std_logic_vector (7 downto 0));
    end component project_reti_logiche;
begin

    UUT: project_reti_logiche
    port map (
                 i_clk => tb_clk,
                 i_start => tb_start,
                 i_rst => tb_rst,
                 i_data => mem_o_data,
                 o_address => input_address,
                 o_done => tb_done,
                 o_en => ext_en,
                 o_we => ext_we,
                 o_data => input_data
             );

    p_CLK_GEN: process is
    begin
        wait for c_CLOCK_PERIOD/2;
        tb_clk <= not tb_clk;
    end process p_CLK_GEN;

    with input_select_internal select
        mem_i_data <= input_data when '0',
                      set_data when '1',
                      (others => 'X') when others;

    with input_select_internal select
        mem_address <= input_address when '0',
                       set_address when '1',
                       (others => 'X') when others;

    enable_wire <= ext_en or input_select_internal;
    mem_we <= ext_we or input_select_internal;

    MEM: process(tb_clk)
    begin
        if tb_clk'event and tb_clk = '1' then
            if enable_wire = '1' then
                if mem_we = '1' then
                    RAM(conv_integer(mem_address)) <= mem_i_data;
                    mem_o_data <= mem_i_data after 1 ns;
                else mem_o_data <= RAM(conv_integer(mem_address)) after 1 ns;
                end if;
            end if;
        end if;
    end process;

    SEQUENCER: process
        file text_file: text open read_mode is "/home/tlopez/Devel/Hardware/RL1920/electrosaint.pertini.txt";
        variable text_line: line;
        variable ok: boolean;
        variable char: character;
        variable wait_time: time;
        variable reset: std_logic;
        variable start: std_logic;
        variable activate_internal: std_logic;
        variable address: std_logic_vector (15 downto 0);
        variable data: std_logic_vector (7 downto 0);
    begin
        while not endfile(text_file) loop
            readline(text_file, text_line);

            -- Skip empty lines and single-line comments
            if text_line.all'length = 0 or text_line.all(1) = '#' then
                next;
            end if;
            --

            -- See if we reached a verification checkpoint
            read(text_line, char, ok);
            if char = 'V' then
                read(text_line, char, ok); -- Read blank
                hread(text_line, expected_output, ok);
                assert ok report "Read 'expected_output' failed for line: " &
                 text_line.all severity failure;

                -- When 'done' is signaled by the UUT, check results
                wait until tb_done = '1';

                assert RAM(9) = RAM(10) report "TEST FAILED. Expected " &
                 integer'image(to_integer(unsigned(RAM(10)))) &
                 ", found " &
                 integer'image(to_integer(unsigned(RAM(9)))) &
                 "." severity failure;

                wait for c_CLOCK_PERIOD;
                tb_start <= '0';
                wait until tb_done = '0';

                assert RAM(9) = RAM(10) report "TEST FAILED. Expected " &
                 integer'image(to_integer(unsigned(RAM(10)))) &
                 ", found " &
                 integer'image(to_integer(unsigned(RAM(9)))) &
                 "." severity failure;

                 next;
            end if;
            --

            read(text_line, wait_time, ok);
            assert ok report "Read 'wait_time' failed for line: " & text_line.all severity failure;

            read(text_line, reset, ok);
            assert ok report "Read 'rst' failed for line: " & text_line.all severity failure;
            tb_rst <= reset;

            read(text_line, start, ok);
            assert ok report "Read 'start' failed for line: " & text_line.all severity failure;
            tb_start <= start;

            read(text_line, activate_internal, ok);
            assert ok report "Read 'activate_internal' failed for line: " & text_line.all severity failure;
            input_select_internal <= activate_internal;

            hread(text_line, address, ok);
            assert ok report "Read 'address' failed for line: " & text_line.all severity failure;
            set_address <= address;

            hread(text_line, data, ok);
            assert ok report "Read 'data' failed for line: " & text_line.all severity failure;
            set_data <= data;

            wait for wait_time;

            -- Print trailing comment to console, if any
            read(text_line, char, ok); -- Skip space
            read(text_line, char, ok);

            if char = '#' then
                read(text_line, char, ok); -- Skip space
                report text_line.all;
            end if;
            --
        end loop;

        report "All tests succesfully completed ";
        std.env.stop;
    end process;
end unitb_arch;
