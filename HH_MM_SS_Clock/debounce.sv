`timescale 1ns / 1ps

module debounce #(
    parameter CLK_FREQ_HZ = 100_000_000, 
    parameter DEBOUNCE_MS = 20,           
    parameter DEBOUNCE_CYCLES = CLK_FREQ_HZ / 1000 * DEBOUNCE_MS
) (
    input  logic clk,
    input  logic rst_n,
    input  logic btn_in,      // synchronized button input
    output logic btn_stable   // debounced output - only changes after btn is stable
);

    // Counter width: enough bits to count to DEBOUNCE_CYCLES
    // $clog2 gives us the ceiling log base 2
    localparam CTR_WIDTH = $clog2(DEBOUNCE_CYCLES) + 1;

    logic [CTR_WIDTH-1:0] stable_count;
    logic btn_prev;   // last accepted stable state

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable_count <= '0;
            btn_prev     <= 1'b0;
            btn_stable   <= 1'b0;
        end else begin
            if (btn_in == btn_prev) begin
                // Input matches current stable state - keep counting
                // (We're checking if the input has changed from the last
                //  STABLE output, not the previous raw sample)
                if (stable_count == DEBOUNCE_CYCLES - 1) begin
                    // Held stable long enough - accept the new state
                    btn_stable <= btn_in;
                end else begin
                    stable_count <= stable_count + 1'b1;
                end
            end else begin
                // Input differs from stable output - reset counter, track new level
                stable_count <= '0;
                btn_prev     <= btn_in;
                // NOTE: we do NOT update btn_stable yet - we need it to hold
                // stable for DEBOUNCE_CYCLES before we trust it
            end
        end
    end

endmodule
