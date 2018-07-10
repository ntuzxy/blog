----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:34:14 03/12/2018 
-- Design Name: 
-- Module Name:    Top_SenderReceiver - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
-- This is a customized FIFO with external I/O (Tx and Rx)
-- It splits the original FIFO to two FIFOs (orig_fifo and shadow_fifo) and inserts UART_TXD and UART_RXD.
-- need create AER_FIFO_IO IP to run
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity Top_SenderReceiver is
  Port ( 
  rst     : IN STD_LOGIC;
  clk     : IN STD_LOGIC;
  wr_en 	: IN STD_LOGIC;
  rd_en 	: IN STD_LOGIC;
	din 	  : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
  dout 	  : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
  full 	  : OUT STD_LOGIC;
  empty 	: OUT STD_LOGIC;
  valid 	: OUT STD_LOGIC;
	
	tx      : OUT STD_LOGIC;
	rx      : IN STD_LOGIC
  );
end Top_SenderReceiver;

architecture Behavioral of Top_SenderReceiver is

------------------ Opal Kelly IP --------------------- 
 -- component AER_FIFO_IO
   -- port (
   -- rst : IN STD_LOGIC;
    -- wr_clk : IN STD_LOGIC;
    -- rd_clk : IN STD_LOGIC;
    -- din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    -- wr_en : IN STD_LOGIC;
    -- rd_en : IN STD_LOGIC;
    -- dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    -- full : OUT STD_LOGIC;
    -- empty : OUT STD_LOGIC;
    -- valid : OUT STD_LOGIC
   -- );
 -- end component;

------------------- MicroSemi IP --------------------- 
component AER_FIFO_IO
   port(
       -- Inputs
       DATA   : in  std_logic_vector(63 downto 0);
       RCLOCK : in  std_logic;
       RE     : in  std_logic;
       RESET  : in  std_logic;
       WCLOCK : in  std_logic;
       WE     : in  std_logic;
       -- Outputs
       DVLD   : out std_logic;
       EMPTY  : out std_logic;
       FULL   : out std_logic;
       Q      : out std_logic_vector(63 downto 0)
       );
end component;

component FifoBridgeReceiver
	Port ( 
        clk 	: in  STD_LOGIC; --main clock input 
        reset 	: in  STD_LOGIC;
        rx 		: in  STD_LOGIC;

        fifo_wr_en 	: out  STD_LOGIC;
        fifo_wr_clk : out  STD_LOGIC; --same as input clk 
        fifo_rst 	: out  STD_LOGIC;
        fifo_dout 	: out STD_LOGIC_VECTOR(63 downto 0)
    );
end component;

component FifoBridgeSender
  port ( 		
    clk 				    : in  std_logic; -- main clock input 
    reset				    : in  std_logic;
    fifo_din               	: in  STD_LOGIC_VECTOR(63 DOWNTO 0);
    fifo_full               : in  std_logic;
    fifo_empty              : in  std_logic;
    fifo_valid              : in  std_logic;

    fifo_rd_clk             : out  std_logic;
    fifo_rd_en              : out  std_logic;

    -- output to receiver
    tx 						: out std_logic
  );
end component;
--------------------------------------------------------------------------------

signal	orig_fifo_dout       : std_logic_vector(63 downto 0);
signal	orig_fifo_rd_clk     : std_logic;
signal	orig_fifo_rd_en      : std_logic;
signal	orig_fifo_full       : std_logic;
signal	orig_fifo_empty      : std_logic;
signal	orig_fifo_valid      : std_logic;
signal	shadow_fifo_din      : std_logic_vector(63 downto 0);
signal	shadow_fifo_wr_en    : std_logic;
signal	shadow_fifo_wr_clk   : std_logic;

 begin
--orig_fifo
------------------ Opal Kelly IP --------------------- 
   -- Inst_AER_FIFO_origin:  AER_FIFO_IO
   -- port map (
     -- -- input
	 -- rst	                => rst, --keep original
     -- din				 	=> din, --keep original 
     -- wr_clk	            => clk, --keep original 
     -- wr_en	            => wr_en, --keep original
	 -- -- input from sender
     -- rd_clk              => orig_fifo_rd_clk,
     -- rd_en               => orig_fifo_rd_en,
     -- -- output to sender
     -- dout               	=> orig_fifo_dout,
     -- full                => orig_fifo_full,
     -- empty               => orig_fifo_empty,
     -- valid               => orig_fifo_valid
   -- );

------------------- MicroSemi IP --------------------- 
 Inst_AER_FIFO_origin:  AER_FIFO_IO
 port map (
   -- input
   DATA 				=> din, --keep original 
	-- input from sender
   RCLOCK              => orig_fifo_rd_clk,
   RE               	=> orig_fifo_rd_en,
	RESET               => rst, --keep original
   WCLOCK              => clk, --keep original 
   WE               	=> wr_en, --keep original
   -- output to sender
   DVLD                => open, --orig_fifo_valid,
   EMPTY               => orig_fifo_empty,
   FULL                => orig_fifo_full,
   Q   				=> orig_fifo_dout
 );
  orig_fifo_valid <= not orig_fifo_empty;		
--sender
Sender: FifoBridgeSender
port map(
  clk 			  => clk,
  reset			  => rst,
  --input from orig_fifo
  fifo_din        => orig_fifo_dout,
  fifo_full       => orig_fifo_full,
  fifo_empty      => orig_fifo_empty,
  fifo_valid      => orig_fifo_valid,
  --output to orig_fifo
  fifo_rd_en      => orig_fifo_rd_en,
  fifo_rd_clk     => orig_fifo_rd_clk,
  --top output (could be connect to receiver)
  tx    		  => tx 
);
 
-- reveiver
Receiver: FifoBridgeReceiver
port map (
  clk		 	 => clk,
  reset	      	 => rst, 
  --top input
  rx 		  	 => rx,

  --output to shadow fifo
  fifo_wr_en  	 => shadow_fifo_wr_en,
  fifo_wr_clk  	 => shadow_fifo_wr_clk,
  fifo_rst    	 => open,
  fifo_dout   	 => shadow_fifo_din
);

--shadow_fifo
------------------ Opal Kelly IP --------------------- 
   -- Inst_AER_FIFO_Shadow:  AER_FIFO_IO
   -- port map (
     -- --input
     -- rst                 => rst,
     -- rd_clk              => clk,	-- keep original
     -- rd_en               => rd_en,	-- keep original
	 -- --input from reveiver
     -- wr_clk              => shadow_fifo_wr_clk, 	
     -- wr_en               => shadow_fifo_wr_en, 
     -- din                 => shadow_fifo_din,

     -- --output
     -- dout					=> dout, -- keep original 
     -- full                => full, --keep original 
     -- empty               => empty, -- keep original 
     -- valid               => valid -- keep original 
   -- );

  ------------------- MicroSemi IP --------------------- 
 Inst_AER_FIFO_Shadow:  AER_FIFO_IO
 port map (
   --input
   DATA   				=> shadow_fifo_din,
   RCLOCK              => clk,	-- keep original
   RE              	=> rd_en,	-- keep original
   RESET               => rst,
	--input from reveiver
   WCLOCK              => shadow_fifo_wr_clk, 	
   WE            	    => shadow_fifo_wr_en, 

   --output
   DVLD                => open, --valid, -- keep original 
   EMPTY               => empty, -- keep original
   FULL                => full, -- keep original
   Q			 		=> dout -- keep original   
 );
  valid <= not empty;
end Behavioral;

