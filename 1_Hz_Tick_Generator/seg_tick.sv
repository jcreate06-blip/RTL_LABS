`timescale 1ns / 1ps
// seg_tick is a seconds counter driven by the 1Hz tick enable from the tick_gen.
// Counts from 0 to SECONDS - 1 (in this case 60 - 1) then wraps back around to 0.
// Output 'second' is used by top_tick to drive the seven segment display.
module seg_tick #(
    parameter SECONDS = 60 //wrap point for the counter
) (
    input logic clk,    
    input logic rst,    
    input logic tick,   // 1Hz clk enable from tick_gen
    output logic [6:0] second   // current second value 
    );
    always @(posedge clk) begin
        if (rst) begin
            second <= 0; // clears seconds counter on rst
        end
         else if (tick) // only updates on 1Hz tick enable
            if (second == SECONDS -1) 
                second <= 0; // wraps back to 0 after 59
            else
                second <= second + 1; // increments every second       
            end
endmodule