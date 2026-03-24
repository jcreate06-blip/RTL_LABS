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
------------------------------------------------------
Files | Description
------------------------------------------------------
fsm_traffic.sv : 5-State Moore FSM (Core Controlling Logic)

sync_debounce.sv : Two-stage synchronizer + a 50ms debouncing 

top.sv : Top-level: wires debouncer, FSM, edge detector, and PWM RGB driver
------------------------------------------------------

# Simulation 
------------------------------------------------------
Files | Description
------------------------------------------------------
constraints.xdc : Pin assignment for the Nexys A7-100T
------------------------------------------------------

# LED Mapping 
LED    Represents    Green    Yellow    Red

LED16  Car Traffic Light  car_green  car_yellow  car_red

LED17  Pedestrian Signal  ped_walk              ped_dont


