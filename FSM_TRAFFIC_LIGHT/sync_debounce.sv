`timescale 1ns / 1ps

module sync_debounce # (
    parameter int unsigned DEBOUNCE_CYCLES = 5_000_000 //50ms -> 100MHz
) (
    input logic clk,
    input logic rst,
    input logic async_btn,
    output logic btn_clean
    );
    
    logic sync1, sync2;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            sync1 <= 1'b0;
            sync2 <= 1'b0;
        end else begin
            sync1 <= async_btn;
            sync2 <= sync1;
        end
    end
    
    logic btn_sync;
    assign btn_sync = sync2;
    
    //our debounce logic
    logic [$clog2(DEBOUNCE_CYCLES):0] counter;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            counter <= '0;
            btn_clean <= 1'b0;
        end else begin 
        
            if (btn_sync == btn_clean) begin 
                //No change - reset counter 
                counter <= '0;
            end else begin 
                //potential change detection 
                counter <= counter + 1;
                
                if (counter >= DEBOUNCE_CYCLES-1) begin 
                    //input has been stable for long enough
                    btn_clean <= btn_sync;
                    counter <= '0;
                 end
             end
         end
     end
endmodule
