`timescale 1ns / 1ps
// top : HH:MM:SS digital clk top level module
// wires together all other submodules: tick generators, counters,
// synchronizers/debouncers, and seven segment display
module top(
    input logic CLK100MHZ,  // 100MHz board clk
    input logic CPU_RESETN, // active low rst button
    input logic BTNL,       // manual increment seconds
    input logic BTNC,       // manual increment minutes
    input logic BTNR,       // manual increment hours
    output logic [7:0] SEG, // seven segment lines (active low)
    output logic [7:0] AN   // seven segment anode select lines
    );
    
    // wires buttons to button sync and debounce
    logic btnl_sync, btnc_sync, btnr_sync;  
    logic btnl_clean, btnc_clean, btnr_clean;
    
    // tick signals for different clk rates
    logic tick;         // 1Hz for seconds counter
    logic tick_1khz;    // 1kHz for seven segment refresh
    logic tick_10hz;    // 10Hz for button incrementing
    
    // counter outputs
    logic [5:0] seconds_top;
    logic [5:0] minutes_top;
    logic [4:0] hours_top;
    
    // rollover pulses to the cascading counters
    logic sec_rollover_top;
    logic min_rollover_top;
        
    // current digit displayed being split into in their values 
    logic [3:0] digit;      // put into the seg_decoder each refresh cycle
    logic [3:0] sec_tens;
    logic [3:0] sec_ones;
    logic [3:0] min_tens;
    logic [3:0] min_ones;
    logic [3:0] hrs_tens;
    logic [3:0] hrs_ones;
    
    // 1Hz tick generator
    tick_gen u_tick (.clk(CLK100MHZ),.rst(~CPU_RESETN),.tick(tick));
    
    // cascaded counter chain 
    seconds u_sec (.clk(CLK100MHZ),.rst(~CPU_RESETN),.tick_1hz(tick),.tick_10hz(tick_10hz),.seconds(seconds_top),.sec_rollover(sec_rollover_top),.btnl(btnl_clean));
    minutes u_min (.clk(CLK100MHZ),.rst(~CPU_RESETN),.tick_10hz(tick_10hz),.sec_rollover(sec_rollover_top),.minutes(minutes_top),.min_rollover(min_rollover_top),.btnc(btnc_clean));
    hours u_hr (.clk(CLK100MHZ),.rst(~CPU_RESETN),.tick_10hz(tick_10hz),.min_rollover(min_rollover_top),.hours(hours_top),.btnr(btnr_clean));
    
    // button input chain 
    synchronizer u_sync_btnl (.clk(CLK100MHZ), .rst_n(CPU_RESETN), .async_in(BTNL), .sync_out(btnl_sync));
    synchronizer u_sync_btnc (.clk(CLK100MHZ), .rst_n(CPU_RESETN), .async_in(BTNC), .sync_out(btnc_sync));
    synchronizer u_sync_btnr (.clk(CLK100MHZ), .rst_n(CPU_RESETN), .async_in(BTNR), .sync_out(btnr_sync));
    debounce u_deb_btnl (.clk(CLK100MHZ), .rst_n(CPU_RESETN), .btn_in(btnl_sync), .btn_stable(btnl_clean));
    debounce u_deb_btnc (.clk(CLK100MHZ), .rst_n(CPU_RESETN), .btn_in(btnc_sync), .btn_stable(btnc_clean));
    debounce u_deb_btnr (.clk(CLK100MHZ), .rst_n(CPU_RESETN), .btn_in(btnr_sync), .btn_stable(btnr_clean));  
    
    // 10Hz tick
    tick_gen #(.DIVISOR(10_000_000)) clk_10hz (.clk(CLK100MHZ), .rst(~CPU_RESETN), .tick(tick_10hz));
    
    // 1kHz tick
    tick_gen #(.DIVISOR(100_000)) clk_1k (.rst(~CPU_RESETN),.clk(CLK100MHZ),.tick(tick_1khz));
    
    // segment decoder
    seg_decoder u_seg (.x(digit), .seg(SEG));
        
    //seconds split into tens : ones
    assign sec_tens = seconds_top / 10;
    assign sec_ones = seconds_top % 10;
        
    //minutes split into tens : ones
    assign min_tens = minutes_top / 10;
    assign min_ones = minutes_top % 10;
      
    //hours split into tens : ones
    assign hrs_tens = hours_top / 10;
    assign hrs_ones = hours_top % 10;
    
    // digit selector : based on which anode is right 
    // runs combinationally so it reflects the AN state
    always @(*) begin
        case(AN)
            8'b11111110: digit = sec_ones;  // digit one
            8'b11111101: digit = sec_tens;  // digit two 
            8'b11111011: digit = min_ones;  // digit three
            8'b11110111: digit = min_tens;  // digit four
            8'b11101111: digit = hrs_ones;  // digit five
            8'b11011111: digit = hrs_tens;  // digit six
            default: digit = 0;
        endcase
    end
    
    // anode multiplexer : cycles through six positions 
    // the zero bit shfts left each tick which activates one digit at a time
    // cycles too fast for the eye to see so all look lit at the same time
    always @(posedge CLK100MHZ) begin
        if (~CPU_RESETN)
            AN <= 8'b11111110;
        else if (tick_1khz) begin            
            case (AN)
                8'b11111110: AN <= 8'b11111101;
                8'b11111101: AN <= 8'b11111011;
                8'b11111011: AN <= 8'b11110111;
                8'b11110111: AN <= 8'b11101111;
                8'b11101111: AN <= 8'b11011111;
                8'b11011111: AN <= 8'b11111110;

                default: AN <= 8'b11111110;
            endcase
        end
    end

    
    
endmodule
