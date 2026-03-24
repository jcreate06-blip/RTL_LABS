`timescale 1ns / 1ps
// tick_gen is a Parameterized modulo-N counter that generates a one cycle
// tick pulse every DIVISOR clk cycle. Used as the 1Hz timebase
// used for the RTC system. DIVISOR can be changed to whatever we decide
module tick_gen #(
    parameter DIVISOR = 100_000_000 //100 Mhz / 100,000,000 = 1Hz
) (
    input logic clk,    // 100 Mhz on board clk
    input logic rst,    // synchronous high reset 
    output logic tick   // one cycle pulse every DIVISOR clk cycles
    );
    
    //27 bits covers up a lot of bits which is > 100,000,000
    logic [26:0] count;
    
    always @(posedge clk) begin
        if (rst) begin
            count <= 0; // clears counter on reset 
            tick <= 0; // forces the tick low on reset
        end
        else begin
            if (count == DIVISOR - 1) begin
                count <= 0; // at terminal count it resets the counter
                tick <= 1; // fire a one cycle pulse
            end
            else begin 
                count <= count + 1; // increment the counter on every cycle 
                tick <= 0; //keep tick low between pulses
            end
        end
    end
endmodule
