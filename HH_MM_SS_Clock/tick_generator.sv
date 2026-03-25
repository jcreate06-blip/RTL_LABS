`timescale 1ns / 1ps
// tick_gen : is a parameterized clock divider
// generates a single cycle high pulse every DIVISOR cycle
// default is 100,000,000 which on a 100MHz board becomes 1Hz
// the DIVISOR can be changed for different rates 
module tick_gen #(
    parameter DIVISOR = 100_000_000
) (
    input logic clk,
    input logic rst,
    output logic tick
    );
    
    //27 bits covers up a lot of bits which is > 100,000,000
    logic [26:0] count;
    
    always @(posedge clk) begin
        if (rst) begin
            count <= 0; // clears count on reset
            tick <= 0; // forces tick low on reset 
        end
        else begin
            // when count hits terminal count it resets and fires the tick pulse
            if (count == DIVISOR - 1) begin
                count <= 0;
                tick <= 1;
            end
            // if doesnt hit terminal count it just keeps counting up while tick stays low
            else begin 
                count <= count + 1;
                tick <= 0;
            end
        end
    end
endmodule
