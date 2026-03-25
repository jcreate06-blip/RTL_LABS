`timescale 1ns / 1ps
// hours : modulo-24 counter
// only increment when min_rollover fire every 60 minutes
// no rollover output needed 
// also support manual increment with btnr
module hours(
    input logic clk,
    input logic rst,
    input logic min_rollover,   // pulse given from the minutes module (every 60 minutes)
    input logic btnr,           // hold to manually increment hours
    input logic tick_10hz,      // rate btnr increments
    output logic [4:0] hours    // current hours value (0 - 23)
    );
    
    always @(posedge clk) begin
        if (rst) begin
            hours <= 0;
        end else begin
            
        // path which only increments when minutes rollover
        if (min_rollover) begin
            if (hours == 5'd23) begin
                // modulo 24 rollover which then wraps and goes back to 0
                hours <= 0;
            end else begin
                hours <= hours + 1;
            end
        // manual button hold which fires as 10Hz
        end else if (btnr && tick_10hz) begin
            if (hours == 5'd23)
                // same rollover behavior, but no cascade needed for hours 
                hours <= 0;
            else 
                hours <= hours + 1;
            end
        end
    end

endmodule
