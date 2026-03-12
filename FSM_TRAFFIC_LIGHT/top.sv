`timescale 1ns / 1ps

module top # (
    parameter int unsigned DEBOUNCE_CYCLES = 5_000_000,
    parameter int unsigned  PWM_BITS = 8
) ( 
    input logic CLK100MHZ,
    input logic CPU_RESETN,
    input logic BTNC, //please lemme cross the street
    output logic LED16_R,
    output logic LED16_G,
    output logic LED16_B,
    output logic LED17_R,
    output logic LED17_G,
    output logic LED17_B
    );
    
    logic rst;
    assign rst = ~CPU_RESETN;
    
    logic ped_btn_clean;
    
    sync_debounce # (
        .DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)
    ) u_db (
        .clk(CLK100MHZ),
        .rst(rst),
        .async_btn(BTNC),
        .btn_clean(ped_btn_clean)
    );
    
    logic ped_btn_prev;
    logic ped_req_pulse;
    
    always_ff @(posedge CLK100MHZ) begin
        if (rst)
            ped_btn_prev <= 1'b0;
        else
            ped_btn_prev <= ped_btn_clean;
    end
    
    assign ped_req_pulse = (ped_btn_clean && ~ped_btn_prev);
    
    logic car_red, car_yellow, car_green;
    logic ped_walk, ped_dont;
    
    fsm_traffic u_fsm (
        .clk(CLK100MHZ),
        .rst(rst),
        .ped_req(ped_req_pulse),
        .car_red(car_red),
        .car_yellow(car_yellow),
        .car_green(car_green),
        .ped_walk(ped_walk),
        .ped_dont(ped_dont)
    );
    
    //Now we begin mapping the rbb with hex codes and such
    logic [7:0] car_R, car_G, car_B;
    logic [7:0] ped_R, ped_G, ped_B;
    
    always_comb begin
        car_R = 8'h00; car_G = 8'h00; car_B = 8'h00; // off by default

        if (car_red) begin
            car_R = 8'hFF; car_G = 8'h00; car_B = 8'h00;
        end else if (car_yellow) begin
            car_R = 8'hFF; car_G = 8'hDF; car_B = 8'h00;
        end else if (car_green) begin
            car_R = 8'h00; car_G = 8'hFF; car_B = 8'h00;
        end
    end
    
    always_comb begin
        ped_R = 8'h00; ped_G = 8'h00; ped_B = 8'h00; // off by default

        if (ped_dont) begin
            ped_R = 8'hFF; ped_G = 8'h00; ped_B = 8'h00;
        end else if (ped_walk) begin
            ped_R = 8'h00; ped_G = 8'hFF; ped_B = 8'h00;
        end
    end
    
    logic [PWM_BITS-1:0] pwm_cnt;

    always_ff @(posedge CLK100MHZ) begin
        if (rst)
            pwm_cnt <= '0;
        else
            pwm_cnt <= pwm_cnt + 1'b1;
    end

    //if desired intensity > pwm counter => LED on for that slice
    always_comb begin
        LED16_R = (car_R > pwm_cnt);
        LED16_G = (car_G > pwm_cnt);
        LED16_B = (car_B > pwm_cnt);

        LED17_R = (ped_R > pwm_cnt);
        LED17_G = (ped_G > pwm_cnt);
        LED17_B = (ped_B > pwm_cnt);
    end
    
endmodule
