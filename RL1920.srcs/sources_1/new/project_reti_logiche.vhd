----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Tomas Antonio Lopez
-- 
-- Create Date: 12/15/2019 02:48:03 PM
-- Design Name: RL1920
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: Progetto Reti Logiche
-- Target Devices: xc7a200tfbg484-1
-- Tool Versions: 2018.3
-- Description: Component for this year's assignment
-- 
-- Dependencies: None
-- 
-- Revision: 1.1 - Moved wz_loaded logic inside delta process
-- Revision: 1.0 - Tested and functional
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity address_reg is
    port ( clk: in STD_LOGIC;
           rst: in STD_LOGIC;
           we: in STD_LOGIC;
           i_addr: in STD_LOGIC_VECTOR (7 downto 0);
           o_addr: out STD_LOGIC_VECTOR (7 downto 0));
end address_reg;

architecture rtl of address_reg is
begin
    reg: process (clk, rst)
    begin
        if rst = '1' then
            o_addr <= (others => '0');
        elsif (clk'event and clk = '1' and we = '1') then
            o_addr <= i_addr;
        end if;
    end process;
end rtl;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR (7 downto 0);
           o_address : out STD_LOGIC_VECTOR (15 downto 0);
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR (7 downto 0));
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type state is (R, LZ1, LZ2, LA, WA, D, S);

    signal currs, nexs: state;
    signal inv_clk: STD_LOGIC;
    signal input_address: STD_LOGIC_VECTOR (7 downto 0);
    signal new_mem_addr: UNSIGNED (15 downto 0);
    signal curr_mem_addr: UNSIGNED (15 downto 0);

    signal we_bus: STD_LOGIC_VECTOR (8 downto 0);
    signal reg_bus: STD_LOGIC_VECTOR (63 downto 0);
    signal base: STD_LOGIC_VECTOR (7 downto 0);

    signal active_zone: STD_LOGIC_VECTOR (7 downto 0);
    signal offset: UNSIGNED (7 downto 0);
    signal zone_number: STD_LOGIC_VECTOR (2 downto 0);
    signal encoded_addr: STD_LOGIC_VECTOR (7 downto 0);

    signal sync_o_done: STD_LOGIC;

    function offset_to_oh (i: UNSIGNED (7 downto 0))
    return STD_LOGIC_VECTOR is
        variable offoh: STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
    begin
        offoh(to_integer(i(1 downto 0))) := '1';
        return offoh;
    end offset_to_oh;

begin
    inv_clk <= not i_clk;
    -- Input address register
    input_reg: entity work.address_reg(rtl)
    port map(
                clk => inv_clk,
                rst => i_rst,
                we => we_bus(8),
                i_addr => i_data,
                o_addr => input_address
            );

    -- Generate registers and membership logic for each zone
    zones: for a in 7 downto 0 generate
        signal local_base: STD_LOGIC_VECTOR (7 downto 0);
    begin
        base: entity work.address_reg(rtl)
        port map(
                    clk => inv_clk,
                    rst => i_rst,
                    we => we_bus(a),
                    i_addr => i_data,
                    o_addr => local_base
                );

        reg_bus((a * 8 + 7) downto (a * 8)) <= local_base;
        active_zone(a) <= '1' when (UNSIGNED(input_address) >= UNSIGNED(local_base))
                            and (UNSIGNED(input_address) < (UNSIGNED(local_base) + to_unsigned(4,8))) else
                          '0';
    end generate;

    -- Select the base of the active zone, if the current address is inisde one
    with active_zone select
        base <= reg_bus(7 downto 0) when "00000001",
                reg_bus(15 downto 8) when "00000010",
                reg_bus(23 downto 16) when "00000100",
                reg_bus(31 downto 24) when "00001000",
                reg_bus(39 downto 32) when "00010000",
                reg_bus(47 downto 40) when "00100000",
                reg_bus(55 downto 48) when "01000000",
                reg_bus(63 downto 56) when "10000000",
                "--------" when others;

    -- Calculate the zone's number
    with active_zone select
        zone_number <= "000" when "00000001",
                       "001" when "00000010",
                       "010" when "00000100",
                       "011" when "00001000",
                       "100" when "00010000",
                       "101" when "00100000",
                       "110" when "01000000",
                       "111" when "10000000",
                       "---" when others;

    -- Calculate offset from the WZ's base address
    offset <= (UNSIGNED(input_address) - UNSIGNED(base));

    -- Stitch toghether the encoded address
    encoded_addr <= '1' & zone_number & offset_to_oh(offset);

    -- Check if WZ encoding has taken place.
    -- If that's the case, output the encoded address, otherwise copy the input to the output
    with active_zone select
        o_data <= input_address when "00000000",
                  encoded_addr when others;

    state_output: process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            currs <= R;
            curr_mem_addr <= (others => '0');
            o_address <= (others => '0');
        elsif i_clk'event and i_clk = '0' then
            currs <= nexs;
            curr_mem_addr <= new_mem_addr;
            o_address <= STD_LOGIC_VECTOR(new_mem_addr);
        end if;
    end process state_output;

    -- Synchronize o_done on the rising edge to avoid glitches
    sync_done: process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            o_done <= '0';
        elsif i_clk'event and i_clk = '1' then
            o_done <= sync_o_done;
        end if;
    end process sync_done;

    -- Generates WE signals for the internal registers based on the current memory address
    we_sigs_phaser: process (i_clk, i_rst)
        -- Support variable to compute new write-enable signals for internatl registers
        variable new_we_sigs:STD_LOGIC_VECTOR (9 downto 0);
    begin
        new_we_sigs := (others => '0');

        if i_rst = '1' then
            we_bus <= (others => '0');
        elsif i_clk'event and i_clk = '1' then
            -- Based on the current memory address, set the write-enable signal of the correct register.
            -- new_we_sigs has an extra bit because curr_mem_addr is used for pointing to the
            -- result-cell's address too.
            new_we_sigs(to_integer(curr_mem_addr)) := '1';
            we_bus <= new_we_sigs(8 downto 0);
        end if;
    end process we_sigs_phaser;

    delta: process (currs, i_start, curr_mem_addr)
    begin
        case currs is
            when R =>
                if i_start = '1' then
                    nexs <= LZ1;
                else
                    nexs <= R;
                end if;
            when LZ1 =>
                nexs <= LZ2;
            when LZ2 =>
                -- Start encoding when base addresses are loaded
                if curr_mem_addr >= to_unsigned(7, 15) then
                    nexs <= LA;
                else
                    nexs <= LZ1;
                end if;
            when LA =>
                nexs <= WA;
            when WA =>
                nexs <= D;
            when D =>
                if i_start = '1' then
                    nexs <= D;
                else
                    nexs <= S;
                end if;
            when S =>
                if i_start = '1' then
                    nexs <= LA;
                else
                    nexs <= S;
                end if;
        end case;
    end process delta;

    lambda: process (currs, curr_mem_addr)
    begin
        case currs is
            when R =>
                new_mem_addr <= (others => '0');
                sync_o_done <= '0';
                o_en <= '0';
                o_we <= '-';
            when LZ1 =>
                new_mem_addr <= curr_mem_addr + to_unsigned(1, 16);
                sync_o_done <= '0';
                o_en <= '1';
                o_we <= '0';
            when LZ2 =>
                new_mem_addr <= curr_mem_addr + to_unsigned(1, 16);
                sync_o_done <= '0';
                o_en <= '1';
                o_we <= '0';
            when LA =>
                new_mem_addr <= curr_mem_addr + to_unsigned(1, 16);
                sync_o_done <= '0';
                o_en <= '1';
                o_we <= '0';
            when WA =>
                new_mem_addr <= to_unsigned(8, 16);
                sync_o_done <= '0';
                o_en <= '1';
                o_we <= '1';
            when D =>
                new_mem_addr <= curr_mem_addr;
                sync_o_done <= '1';
                o_en <= '0';
                o_we <= '-';
            when S =>
                new_mem_addr <= curr_mem_addr;
                sync_o_done <= '0';
                o_en <= '0';
                o_we <= '-';
        end case;
    end process lambda;
end Behavioral;
