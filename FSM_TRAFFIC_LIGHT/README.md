# FPGA-FSM-Traffic-Controller

This traffic controller is made up of 5 states
  MAIN_GREEN -> MAIN_YELLOW -> MAIN_RED -> REQUEST_DELAY -> PED_WALK -> MAIN_GREEN ->...

# Basic how it works
- MAIN_GREEN, the car light is green and pedestrians dont walk.
- Press BTNC, which is the pedestrian request to cross the street. The BTN is latched and is kept in memory.
- After MAIN_RED the FSM enters REQUEST_DELAY, then into PED_WALK where now the pedestrians get green and the cars get red.
- After wthe walk timer is done it cycles back again to MAIN_GREEN.

# Hardware
------------------------------------------------------
Board           |                                FPGA
------------------------------------------------------
Nexys A7-100T       Xilinx Artix-7 (xc7a100tcsg324-1)
------------------------------------------------------

# RTL Source Files
