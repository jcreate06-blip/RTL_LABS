`timescale 1ns / 1ps
// minutes : module-60 counter 
// increments only when sec_rollover fires from seconds 
// fires min_rollover for one cycle on rollover to trigger hours 
// btnc manually increments when held down at 10Hz as well
module minutes(
    input logic clk,
    input logic rst,
    input logic sec_rollover,   // the oulse from the seconds module
    input logic btnc,           // manually increments minutes when held
    input logic tick_10hz,      // controls hpw fast btnc increments
    output logic [5:0] minutes, // minutes value of 0 - 59
    output logic min_rollover   // gies high for one cycle when minutes 
    );
    
    always @(posedge clk) begin
        if (rst) begin
            minutes <= 0;
            min_rollover <= 0;
        end else begin
            // default rollover to 0 every cycle so its only high for one cycle
            min_rollover <= 0;
            
            // normal path only increments when seconds roll over 
            if (sec_rollover) begin
                // rollover reset to 0 and tells the hours module
                if (minutes == 6'd59) begin 
                    minutes <= 0;
                    min_rollover <= 1;
                end else begin
                    minutes <= minutes + 1;
                end
            // manual button hold path - only fires on 10Hz 
            end else if (btnc && tick_10hz) begin 
                if (minutes == 6'd59) begin
                    // rollover but also cascades when button is held 
                    minutes <= 0;
                    min_rollover <= 1;
                end else
                    minutes <= minutes + 1;
                end
            end
        end
                
endmodule
