`timescale 1ns/1ps

module fsm_traffic_tb;

  // 100 MHz clock
  localparam time CLK_PERIOD = 10ns;

  // Use small values so simulation finishes quickly
  localparam int unsigned GREEN_T_SIM     = 100; 
  localparam int unsigned REQ_DELAY_T_SIM = 10;
  localparam int unsigned YELLOW_T_SIM    = 8;
  localparam int unsigned ALLRED_T_SIM    = 6;
  localparam int unsigned WALK_T_SIM      = 12;

  logic clk;
  logic rst;
  logic ped_req;

  logic car_green, car_yellow, car_red;
  logic ped_walk, ped_dont;

  // DUT
  fsm_traffic #(
    .GREEN_T     (GREEN_T_SIM),
    .YELLOW_T    (YELLOW_T_SIM),
    .ALLRED_T    (ALLRED_T_SIM),
    .WALK_T      (WALK_T_SIM),
    .REQ_DELAY_T (REQ_DELAY_T_SIM)
  ) dut (
    .clk        (clk),
    .rst        (rst),
    .ped_req    (ped_req),
    .car_green  (car_green),
    .car_yellow (car_yellow),
    .car_red    (car_red),
    .ped_walk   (ped_walk),
    .ped_dont   (ped_dont)
  );

  // Clock gen
  initial clk = 1'b0;
  always #(CLK_PERIOD/2) clk = ~clk;

  // Helpers
  function automatic int ones3(input logic a, input logic b, input logic c);
    return (a ? 1 : 0) + (b ? 1 : 0) + (c ? 1 : 0);
  endfunction

  function automatic bit car_onehot();
    return (ones3(car_green, car_yellow, car_red) == 1);
  endfunction

  function automatic bit ped_exclusive();
    return ((ped_walk ^ ped_dont) == 1'b1);
  endfunction

  task automatic tick(input int unsigned n);
    repeat (n) @(posedge clk);
  endtask

  task automatic apply_reset();
    rst = 1'b1;
    ped_req = 1'b0;
    tick(5);
    rst = 1'b0;
    tick(2);
  endtask

  task automatic wait_cycles_or_fatal(
    input string msg,
    input int unsigned max_cycles,
    input bit condition
  );
    int unsigned i;
    for (i = 0; i < max_cycles; i++) begin
      if (condition) return;
      @(posedge clk);
    end
    $fatal(1, "TIMEOUT: %s", msg);
  endtask

  // Basic safety assertions every cycle
  always @(posedge clk) begin
    if (!rst) begin
      if (!car_onehot()) begin
        $fatal(1, "Car lights not one-hot: G=%0b Y=%0b R=%0b", car_green, car_yellow, car_red);
      end
      if (!ped_exclusive()) begin
        $fatal(1, "Ped signals not exclusive: walk=%0b dont=%0b", ped_walk, ped_dont);
      end
      if (ped_walk && !car_red) begin
        $fatal(1, "Safety violation: ped_walk=1 while car_red=0");
      end
    end
  end

  initial begin
    $display("Starting tb_fsm_traffic...");
    apply_reset();

    // 1) After reset: should be car green + ped dont
    if (!(car_green && !car_yellow && !car_red && ped_dont && !ped_walk)) begin
      $fatal(1, "Post-reset wrong: G=%0b Y=%0b R=%0b walk=%0b dont=%0b",
             car_green, car_yellow, car_red, ped_walk, ped_dont);
    end
    $display("PASS: Post-reset state is GREEN + DONT");

    // 2) Press ped_req (pulse 1 cycle)
    @(negedge clk);
    ped_req = 1'b1;
    @(posedge clk);
    ped_req = 1'b0;
    $display("Pressed ped_req");

    // 3) Immediately after request, we should still be GREEN (REQUEST_DELAY keeps green)
    tick(1);
    if (!(car_green && ped_dont)) begin
      $fatal(1, "Expected GREEN during request delay, got: G=%0b Y=%0b R=%0b walk=%0b dont=%0b",
             car_green, car_yellow, car_red, ped_walk, ped_dont);
    end
    $display("PASS: Still GREEN during request delay");

    // 4) After REQ_DELAY_T_SIM cycles, should go YELLOW
    wait_cycles_or_fatal("Expected YELLOW after request delay",
                         REQ_DELAY_T_SIM + 5,
                         (car_yellow && !car_green && !car_red));
    $display("PASS: Entered YELLOW");

    // 5) After YELLOW_T_SIM cycles, should go RED (all-red phase uses car_red)
    wait_cycles_or_fatal("Expected RED after YELLOW",
                         YELLOW_T_SIM + 10,
                         (car_red && !car_green && !car_yellow));
    $display("PASS: Entered RED (ALL_RED)");

    // 6) After ALLRED_T_SIM cycles, should go PED_WALK (ped green)
    wait_cycles_or_fatal("Expected PED_WALK after ALL_RED",
                         ALLRED_T_SIM + 10,
                         (ped_walk && !ped_dont && car_red));
    $display("PASS: Entered PED_WALK");

    // 7) After WALK_T_SIM cycles, return to GREEN + DONT
    wait_cycles_or_fatal("Expected return to GREEN after WALK",
                         WALK_T_SIM + 20,
                         (car_green && !car_yellow && !car_red && ped_dont && !ped_walk));
    $display("PASS: Returned to GREEN + DONT");

    $display("ALL TESTS PASSED ?");
    $finish;
  end

endmodule