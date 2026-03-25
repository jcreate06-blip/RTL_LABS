`timescale 1ns / 1ps

module synchronizer #(
    parameter STAGES = 2    // 2 is standard
) (
    input  logic clk,
    input  logic rst_n,     // active-low reset 
    input  logic async_in,  // raw asynchronous input
    output logic sync_out   // synchronized output which is safe to use in clk domain
);

    // The attribute must be applied to the signal, not the always block.
    // Both FFs get the attribute.
    (* ASYNC_REG = "TRUE" *) logic [STAGES-1:0] sync_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sync_reg <= '0;
        else
            // Shift: new data enters at bit 0, exits at MSB
            // In Verilog: {sync_reg[0], async_in} forms a 2-bit value
            // that shifts left each cycle
            sync_reg <= {sync_reg[STAGES-2:0], async_in};
    end

    assign sync_out = sync_reg[STAGES-1];

endmodule

