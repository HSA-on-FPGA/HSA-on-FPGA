-- Copyright (C) 2017 Philipp Holzinger
-- Copyright (C) 2017 Martin Stumpf
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity tb_design_simulation_wrapper is
end tb_design_simulation_wrapper;

architecture structure of tb_design_simulation_wrapper is

	signal clock : std_logic;

begin

inst_design_simulation_wrapper: entity work.design_simulation_wrapper
	port map (
		clk => clock
	);

clock_P: process
begin
clock <= '0';
wait for 5 ns;
clock <= '1';
wait for 5 ns;
end process;

end structure;

