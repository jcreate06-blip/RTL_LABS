`timescale 1ns / 1ps
// seconds : a modulo-60 counter 
// increments every tick and rolls over from 59 to 0
// on rollover, fire sec_rollover for one cycle to trigger minutes
// btnl allows a manual way to increment at a rate of 10Hz
module seconds(
    input logic clk,
    input logic rst, 
    input logic tick_1hz,   // 1Hz pulse from tick_gen, normal counting 
    input logic btnl,       // hold to manually increment 
    input logic tick_10hz,  // controls how fast the btnl increments
    output logic [5:0] seconds,     // seconds value
    output logic sec_rollover       // goes high on every cycle after the rollover
    
    );
    
    always @(posedge clk) begin
        if (rst) begin
            seconds <= 0;
            sec_rollover <= 0;
        end else begin
            // default rollover to 0 every cycle so it only stays high for one cycle
            sec_rollover <= 0;
            
            // normal 1Hz counting 
            if (tick_1hz) begin
                if (seconds == 6'd59) begin
                    //rollover reset to 0 and talks to minutes
                    seconds <= 0;
                    sec_rollover <= 1;
                end else begin
                    seconds <= seconds + 1;
                end
            // manual btn increment firing at 10Hz 
            end else if (btnl && tick_10hz) begin
                if (seconds == 6'd59) begin
                    //same rollover behavior with cascading into minutes
                    seconds <= 0;
                    sec_rollover <= 1;
                end else
                    seconds <= seconds + 1;
            end
        end
    end
endmodule
