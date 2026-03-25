`timescale 1ns / 1ps
// No ports needed - testbenches are self-contained.
// Everything is declared and driven internally.
module tb_time_core;

    // These are the wires/regs you'll drive into the DUT and
    // observe coming out. reg = driven by testbench, wire = output.
    logic clk;
    logic rst;
    logic tick_1hz;

    logic [5:0] seconds;
    logic [5:0] minutes;
    logic [4:0] hours;
    logic sec_rollover;
    logic min_rollover;

    // These are software integers that mirror what the hardware
    // should be doing. Every tick we update these and compare
    // against the DUT outputs.
    integer exp_s, exp_m, exp_h;
    integer error_count;

    // We instantiate seconds, minutes, and hours separately so
    // we can observe all internal signals including rollovers.
    seconds u_sec (
        .clk(clk),
        .rst(rst),
        .tick_1hz(tick_1hz),
        .seconds(seconds),
        .sec_rollover(sec_rollover)
    );

    minutes u_min (
        .clk(clk),
        .rst(rst),
        .sec_rollover(sec_rollover),
        .minutes(minutes),
        .min_rollover(min_rollover)
    );

    hours u_hr (
        .clk(clk),
        .rst(rst),
        .min_rollover(min_rollover),
        .hours(hours)
    );

    // CLOCK GENERATION
    // Toggles every 5ns = 10ns period = 100MHz.
    // forever means it runs for the entire simulation.
    initial clk = 0;
    always #5 clk = ~clk;
    // TICK TASK
    // Instead of waiting a real second, we manually pulse tick_1hz
    // for exactly one clock cycle. This is how we accelerate time.
    // After each tick we update the scoreboard and run all checks.
    task send_tick;
    begin
        @(posedge clk);
        tick_1hz <= 1;
        @(posedge clk);
        tick_1hz <= 0;

        // Update scoreboard
        step_expected;

        // Wait one more cycle for outputs to settle
        @(posedge clk);

        // Check scoreboard against DUT
        if (seconds !== exp_s) begin
            $display("ERROR: seconds=%0d expected=%0d at time %0t", seconds, exp_s, $time);
            error_count = error_count + 1;
        end
        if (minutes !== exp_m) begin
            $display("ERROR: minutes=%0d expected=%0d at time %0t", minutes, exp_m, $time);
            error_count = error_count + 1;
        end
        if (hours !== exp_h) begin
            $display("ERROR: hours=%0d expected=%0d at time %0t", hours, exp_h, $time);
            error_count = error_count + 1;
        end

        // Range checks
        if (seconds > 59) begin
            $display("ERROR: seconds out of range: %0d", seconds);
            error_count = error_count + 1;
        end
        if (minutes > 59) begin
            $display("ERROR: minutes out of range: %0d", minutes);
            error_count = error_count + 1;
        end
        if (hours > 23) begin
            $display("ERROR: hours out of range: %0d", hours);
            error_count = error_count + 1;
        end
    end
    endtask
    // SCOREBOARD TASK
    // Mirrors the hardware counter logic in software.
    // Called every tick to advance expected values.
    task step_expected;
    begin
        exp_s = exp_s + 1;
        if (exp_s == 60) begin
            exp_s = 0;
            exp_m = exp_m + 1;
            if (exp_m == 60) begin
                exp_m = 0;
                exp_h = exp_h + 1;
                if (exp_h == 24) exp_h = 0;
            end
        end
    end
    endtask
    // ROLLOVER PULSE WIDTH CHECKER
    // Runs in parallel with the main test using a continuous
    // always block. If sec_rollover or min_rollover is ever high
    // for two consecutive cycles, it flags an error immediately.
    logic sec_rollover_prev, min_rollover_prev;

    always @(posedge clk) begin
        sec_rollover_prev <= sec_rollover;
        min_rollover_prev <= min_rollover;

        if (sec_rollover && sec_rollover_prev) begin
            $display("ERROR: sec_rollover high for 2+ cycles at time %0t", $time);
            error_count = error_count + 1;
        end
        if (min_rollover && min_rollover_prev) begin
            $display("ERROR: min_rollover high for 2+ cycles at time %0t", $time);
            error_count = error_count + 1;
        end
    end
    // MAIN TEST SEQUENCE
    // All test cases run here in order. Each section is labeled
    // so you can see exactly what is being tested.
    initial begin
        // Initialize everything
        tick_1hz     = 0;
        rst          = 1;
        exp_s        = 0;
        exp_m        = 0;
        exp_h        = 0;
        error_count  = 0;
        sec_rollover_prev = 0;
        min_rollover_prev = 0;

        // Hold reset for a few cycles then release
        repeat(4) @(posedge clk);
        rst = 0;
        @(posedge clk);
        // TEST A: Normal seconds 58->59->00 rollover
        // Drive seconds up to 58 then watch it roll
        $display("TEST A: seconds 58->59->00 rollover");
        repeat(58) send_tick;
        send_tick; // 59
        send_tick; // should roll to 00 and fire sec_rollover
        // TEST B: Minutes 58->59->00 rollover
        // Keep counting until minutes rolls over
        $display("TEST B: minutes rollover");
        // We're at 00:01:00, run to 00:58:00 then watch rollover
        repeat(58 * 60) send_tick;
        repeat(60) send_tick; // 00:59:00 -> 01:00:00
        // TEST C: 23:59:59 -> 00:00:00 midnight boundary
        // Force the time to 23:59:50 then run past midnight
        $display("TEST C: 23:59:59 -> 00:00:00");
        rst = 1;
        @(posedge clk);
        rst = 0;
        exp_s = 0; exp_m = 0; exp_h = 0;

        // Run to 23:59:50 by ticking enough times
        repeat(23*3600 + 59*60 + 50) send_tick;

        // Now run past midnight
        repeat(15) send_tick;
        // TEST D: Reset during rollover
        // Assert rst one cycle before seconds hits 59
        $display("TEST D: reset during rollover");
        rst = 1;
        @(posedge clk);
        rst = 0;
        exp_s = 0; exp_m = 0; exp_h = 0;

        repeat(58) send_tick;

        // Assert reset right before rollover would happen
        @(posedge clk);
        rst = 1;
        tick_1hz = 1;
        @(posedge clk);
        tick_1hz = 0;
        rst = 0;
        exp_s = 0; exp_m = 0; exp_h = 0;
        @(posedge clk);

        if (seconds !== 0) begin
            $display("ERROR: reset during rollover failed, seconds=%0d", seconds);
            error_count = error_count + 1;
        end
        if (sec_rollover !== 0) begin
            $display("ERROR: sec_rollover should be 0 after reset");
            error_count = error_count + 1;
        end
        // TEST E: Force seconds=59 but tick_1hz=0
        // Seconds should NOT change without a tick
        $display("TEST E: seconds=59 no tick");
        rst = 1; @(posedge clk); rst = 0;
        exp_s = 0; exp_m = 0; exp_h = 0;

        repeat(59) send_tick; // get to 59
        // Now hold tick low for 10 cycles and confirm no change
        repeat(10) @(posedge clk);
        if (seconds !== 59) begin
            $display("ERROR: seconds changed without tick, seconds=%0d", seconds);
            error_count = error_count + 1;
        end
        // FINAL RESULT
        if (error_count == 0)
            $display("PASS: all tests passed with 0 errors");
        else
            $display("FAIL: %0d error(s) detected", error_count);

        $finish;
    end

endmodule