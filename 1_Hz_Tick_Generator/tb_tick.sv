`timescale 1ns / 1ps

module tb_tick;

    logic clk;
    logic rst;
    logic tick;
    
    parameter DIV = 8;
    
    tick_gen #(.DIVISIOR(DIV)) dut ( 
        .clk(clk),
        .rst(rst),
        .tick(tick)    
    );
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    integer cycle_count;
    
    initial begin 
        rst = 1;
        cycle_count =0;
        #20 rst = 0;
        #500 $display("PASS");
        $finish;
    end
    
    always @(posedge clk) begin
        if (rst)
            cycle_count = 0;
        else begin
            cycle_count = cycle_count + 1;
            
            if (tick) begin
                if (cycle_count != DIV) begin
                    $display("FAIL: wrong interval");
                    $finish;
                end
                    cycle_count = 0;
                end
            end
        end     
endmodule
