`timescale 1ns/10ps

module systolic_array_tb;

    // ------------------------------------------------------------------------
    // Parameters (match DUT + Python generator)
    // ------------------------------------------------------------------------
    parameter int rows     = 16;
    parameter int cols     = 16;
    parameter int ip_width = 8;
    parameter int op_width = 32;
    parameter int k_dim    = 128;  // Stream length (K dimension)

    // Must match DUT default unless you override DUT instantiation
    parameter int pipe_lat = 3;

    // ------------------------------------------------------------------------
    // DUT I/O
    // ------------------------------------------------------------------------
    logic clk;
    logic rst;
    logic en;
    logic clr;

    logic [rows*ip_width-1:0] input_matrix;
    logic [cols*ip_width-1:0] weight_matrix;

    logic compute_done;
    logic [31:0] cycles_count;
    logic [rows*cols*op_width-1:0] output_matrix;

    // ------------------------------------------------------------------------
    // Test vector memories
    // ------------------------------------------------------------------------
    logic [rows*ip_width-1:0]        inputs_mem     [0:k_dim-1];
    logic [cols*ip_width-1:0]        weights_mem    [0:k_dim-1];
    logic [rows*cols*op_width-1:0]   golden_ref_mem [0:0];

    // ------------------------------------------------------------------------
    // DUT instantiation
    // ------------------------------------------------------------------------
    systolic_array #(
        .rows(rows),
        .cols(cols),
        .ip_width(ip_width),
        .op_width(op_width),
        .pipe_lat(pipe_lat)
    ) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .clr(clr),
        .input_matrix(input_matrix),
        .weight_matrix(weight_matrix),
        .compute_done(compute_done),
        .cycles_count(cycles_count),
        .output_matrix(output_matrix)
    );

    // ------------------------------------------------------------------------
    // Clock Generation (10ns period)
    // ------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------------------
    // Waveform / Activity Dump Controls (optional)
    // Define one of:
    //   +define+DUMP_SHM              (Cadence SimVision SHM)
    //   +define+DUMP_VCD              (Full-run VCD)
    //   +define+DUMP_ACTIVITY_VCD     (Windowed VCD for power)
    // ------------------------------------------------------------------------

`ifdef DUMP_SHM
    initial begin
        $shm_open("waves.shm");
        $shm_probe(systolic_array_tb, "AS");
    end
`endif

`ifdef DUMP_ACTIVITY_VCD
  // Windowed VCD for power/activity extraction.
  // Use plusargs to override without editing TB:
  //   +DUMP_START_CYC=20 +DUMP_LEN_CYC=500
  int dump_start_cyc;
  int dump_len_cyc;

  initial begin : activity_vcd_dump
    if (!$value$plusargs("DUMP_START_CYC=%d", dump_start_cyc)) dump_start_cyc = 20;
    if (!$value$plusargs("DUMP_LEN_CYC=%d",   dump_len_cyc))   dump_len_cyc   = 500;

    // IMPORTANT:
    // 1) Call dumpfile/dumpvars at time 0 so signals get registered.
    // 2) Dump ONLY the DUT (not the whole TB), otherwise VCD explodes.
    $dumpfile("activity.vcd");
    $dumpvars(0, dut);

    // Keep dumping OFF until window begins
    $dumpoff;

    // Start window after reset deassert + feed begins
    wait (rst === 1'b0);
    wait (en  === 1'b1);

    repeat (dump_start_cyc) @(posedge clk);
    $dumpon;

    repeat (dump_len_cyc) @(posedge clk);
    $dumpoff;

    // flush to ensure file is written cleanly
    $dumpflush;

    $display("[VCD] activity.vcd dumped: start=%0d cycles, len=%0d cycles (scope=dut)",
             dump_start_cyc, dump_len_cyc);
  end
`elsif DUMP_VCD
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, dut);
  end
`endif




    // ------------------------------------------------------------------------
    // Scalable Timeout Watchdog (cycle-based, sweep-safe)
    // NOTE: Your DUT's done logic triggers after en deasserts and then counts
    // down roughly: skew_lat + pipe_lat + rows cycles.
    // Total expected from first feed cycle to done ≈ k_dim + (skew_lat+pipe_lat+rows) + margin.
    // ------------------------------------------------------------------------
    localparam int skew_lat       = (rows - 1) + (cols - 1);
    localparam int postfeed_lat   = skew_lat + pipe_lat + rows;
    localparam int exp_total_cyc  = k_dim + postfeed_lat;
    localparam int timeout_cycles = exp_total_cyc + 200;

    initial begin : watchdog
        int cyc;
        cyc = 0;

        // Wait until reset is released
        wait (rst === 1'b0);

        // Count cycles until done or timeout
        while ((compute_done !== 1'b1) && (cyc < timeout_cycles)) begin
            @(posedge clk);
            cyc++;
        end

        if (compute_done !== 1'b1) begin
            $display("ERROR: Simulation Timed Out! compute_done never went high.");
            $display("  rows=%0d cols=%0d ip=%0d op=%0d k=%0d pipe_lat=%0d",
                     rows, cols, ip_width, op_width, k_dim, pipe_lat);
            $display("  Timeout at %0d cycles (expected approx %0d).",
                     timeout_cycles, exp_total_cyc);
            $finish;
        end
    end

    // ------------------------------------------------------------------------
    // Main Test
    // ------------------------------------------------------------------------
    initial begin : main
        // Metadata (helps in sweep logs)
        $display("RUN CFG: rows=%0d cols=%0d ip=%0d op=%0d k=%0d pipe_lat=%0d",
                 rows, cols, ip_width, op_width, k_dim, pipe_lat);

        // 1) Load vectors
        $readmemh("input_matrix.hex",  inputs_mem);
        $readmemh("weight_matrix.hex", weights_mem);
        $readmemh("golden_output.hex", golden_ref_mem);

        // 2) Initialize
        rst          = 1'b1;
        en           = 1'b0;
        clr          = 1'b0;
        input_matrix = '0;
        weight_matrix= '0;

        // 3) Reset sequence
        repeat(10) @(posedge clk);
        #1 rst = 1'b0;

        // 4) Feed data
        $display("Starting Feed... K_DIM=%0d", k_dim);
        for (int k = 0; k < k_dim; k++) begin
            @(posedge clk);
            #1; // small delay to model TB drive after clock edge
            en           = 1'b1;
            clr          = (k == 0);   // clear accumulators on first token
            input_matrix = inputs_mem[k];
            weight_matrix= weights_mem[k];
        end

        // 5) End feed
        @(posedge clk);
        #1;
        en           = 1'b0;
        clr          = 1'b0;
        input_matrix = '0;
        weight_matrix= '0;

        $display("Feed Complete. Waiting for computation...");

        // 6) Wait for result (synchronous, edge-safe)
        @(posedge clk iff (compute_done === 1'b1));

        // 7) Check result
        #10;
        if (output_matrix === golden_ref_mem[0]) begin
            $display("\n========================================");
            $display("   TEST PASSED! Dimensions: %0dx%0d", rows, cols);
            $display("   cycles_count (DUT): %0d", cycles_count);
            $display("========================================\n");
            // Uncomment for smaller configs only (very large buses are hard to print)
            //$display("Expected: %h", golden_ref_mem[0]);
            //$display("Got:      %h", output_matrix);
        end else begin
            $display("\n========================================");
            $display("   TEST FAILED!");
            $display("   cycles_count (DUT): %0d", cycles_count);
            // Uncomment for smaller configs only (very large buses are hard to print)
            //$display("Expected: %h", golden_ref_mem[0]);
            //$display("Got:      %h", output_matrix);
            $display("========================================\n");
        end

        $finish;
    end

endmodule
