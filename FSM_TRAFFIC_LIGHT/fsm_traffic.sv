`timescale 1ns / 1ps

module fsm_traffic #(
    // 100 MHz clock ? 100,000,000 cycles per second
    parameter int unsigned GREEN_T = 200_000_000, // 2 seconds
    parameter int unsigned YELLOW_T = 100_000_000,  // 1 seconds
    parameter int unsigned RED_T = 200_000_000,
    parameter int unsigned WALK_T = 200_000_000,  // 2 seconds
    parameter int unsigned REQ_DELAY_T = 100_000_000
)(
    input  logic clk,
    input  logic rst,
    input  logic ped_req,

    output logic car_green,
    output logic car_yellow,
    output logic car_red,
    output logic ped_walk,
    output logic ped_dont
);
    //had to make my logic 3 bits cause after i 
    //added the request i had more than 4 states 
    typedef enum logic [2:0] { 
        S_MAIN_GREEN,
        S_REQUEST_DELAY,
        S_MAIN_YELLOW,
        S_MAIN_RED,
        S_PED_WALK
    } state_t;

    state_t state, next_state;

    logic [31:0] timer;
    logic [31:0] limit;
    logic timer_done;
    
    logic ped_pending;

    // State duration selection
    always_comb begin
        unique case (state)
            S_MAIN_GREEN:  limit = GREEN_T;
            S_REQUEST_DELAY: limit = REQ_DELAY_T;
            S_MAIN_YELLOW: limit = YELLOW_T;
            S_MAIN_RED: limit = RED_T;
            S_PED_WALK: limit = WALK_T;
            default: limit = GREEN_T;
        endcase
    end

    assign timer_done = (timer >= (limit - 1));

    // Next-state + outputs
    always_comb begin
        // defaults
        next_state = state;

        car_red    = 1'b0;
        car_yellow = 1'b0;
        car_green  = 1'b0;

        ped_walk   = 1'b0;
        ped_dont   = 1'b1;   // default safe

        unique case (state)

            S_MAIN_GREEN: begin
                car_green = 1'b1;
                ped_dont = 1'b1;

                // transition on button press OR time done
                if (timer_done)
                    next_state = S_MAIN_YELLOW;
            end
            
            S_MAIN_YELLOW: begin
                car_yellow = 1'b1;
                ped_dont   = 1'b1;

                if (timer_done)
                    next_state = S_MAIN_RED;                   
            end
            
            S_MAIN_RED: begin
                car_red  = 1'b1;
                ped_dont = 1'b1;

                if (timer_done) begin
                    if (ped_pending)
                        next_state = S_REQUEST_DELAY;
                    else
                        next_state = S_MAIN_GREEN;
                end
            end
            
            S_REQUEST_DELAY: begin
                car_red = 1'b1;
                ped_dont = 1'b1;
                
                if (timer_done)
                    next_state = S_PED_WALK;
            end
            
            S_PED_WALK: begin
                car_red = 1'b1;
                ped_walk = 1'b1;
                ped_dont = 1'b0;
                
                if (timer_done)
                    next_state = S_MAIN_GREEN;
            end
                        
            default: begin
                next_state = S_MAIN_GREEN;
            end
        endcase
    end

        always_ff @(posedge clk) begin
            if (rst) begin
                state <= S_MAIN_GREEN;
                timer <= 32'd0;
                ped_pending <= 1'b0;
            end else begin
                state <= next_state;
        
                if (state != next_state)
                    timer <= 32'd0;
                else
                    timer <= timer + 32'd1;
        
                if (ped_req)
                    ped_pending <= 1'b1;
        
                if (state == S_REQUEST_DELAY && next_state == S_PED_WALK)
                    ped_pending <= 1'b0;
        end
    end
endmodule