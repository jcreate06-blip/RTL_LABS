`timescale 1ns / 1ps
// top_tick is the top level module for the 1Hz timebase system. 
// Instantiates tick_gen for 1Hz and 1 kHz enables, seg_tick for seconds
// counting, and seg_decoder for the seven segment decoder elapsed seconds on two digits
// Toggles all LEDs at 1Hz and displays passed seconds on two digits
module top_tick #(
    parameter DIVISOR = 100_000_000 
        
) (
    input logic CPU_RESETN, 
    input logic CLK100MHZ,
    output logic [15:0] LED,    // all 16 LEDs on the board toggled at 1Hz
    output logic [7:0] SEG,     // seven segment cathode signals
    output logic [7:0] AN       // seven segment anode select
    );
    
    // internal signals
    logic tick;             
    logic [6:0] second;     // seconds value
    logic [3:0] tens;       // tens digit of seconds
    logic [3:0] ones;       // ones digit of seconds
    logic [7:0] seg_tens;   // segment pattern for tens digit
    logic [7:0] seg_ones;   // segment pattern for ones digit
    logic tick_1khz;        // 1kHz clk enable for display mux
    
    // generate 1Hz tick enable - CPU_RESETN is active low so invert
    tick_gen uut(.rst(~CPU_RESETN),.clk(CLK100MHZ),.tick(tick));
    
    // toggle LEDs on every 1Hz tick using clk enable 
    always @(posedge CLK100MHZ) begin 
        if (~CPU_RESETN) 
           LED <= 0; // clears LEDs on rst 
       else if (tick)
        LED <= ~LED; //flip all LEDs once per second
    end
    
    // split seconds into individual digits on display 
    assign tens = second / 10; // tens digit
    assign ones = second % 10; // ones digit
    
    // mux selects seg_ones when anode 0 is active / seg_tens when anode 1
    assign SEG = (AN == 8'b11111110) ? seg_ones : seg_tens;
    
    // counts seconds 
    seg_tick sec_counter(.clk(CLK100MHZ), .rst(~CPU_RESETN), .tick(tick), .second(second));
    
    // generate tick enable for display multiplexing 
    tick_gen #(.DIVISOR(100_000)) clk_1k (.rst(~CPU_RESETN),.clk(CLK100MHZ),.tick(tick_1khz));
        
    // decodes each digit into seven segment patterns
    seg_decoder dec_tens(.x(tens), .seg(seg_tens));
    seg_decoder dec_ones(.x(ones), .seg(seg_ones));
    
    // multiplex between two digits
    // AN active low displays one digit on at a time, switching fast enough to show up at the same time
    always @(posedge CLK100MHZ) begin
        if (~CPU_RESETN)
            AN <= 8'b11111110; // initialize to 0 on rst 
        else if (tick_1khz) begin            
            case (AN)
                8'b11111110: AN <= 8'b11111101; // switch to digit 1 
                8'b11111101: AN <= 8'b11111110; // switch to digit 0
                default: AN <= 8'b11111110; // default at digit 0 
            endcase
        end
    end
endmodule