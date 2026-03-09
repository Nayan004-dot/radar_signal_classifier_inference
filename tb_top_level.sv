`timescale 1ns/1ps

module tb_top_level;

    // Clock and reset
    reg clk;
    reg rst_n;

    // Input signals
    reg load_start;
    reg infer_start;

    // Input data: Unpacked for easy randomizing, then flattened for DUT
    reg signed [7:0] input_data_unpacked [0:99];
    wire [799:0]     input_data_flat;

    // Outputs
    wire [1:0]  argmax_out;
    wire        inference_done;
    wire        load_done;
    wire        busy;

    // Flattening logic for the input port (Icarus requirement)
    genvar k;
    generate
        for (k = 0; k < 100; k = k + 1) begin : flatten_input
            assign input_data_flat[k*8 +: 8] = input_data_unpacked[k];
        end
    endgenerate

    // Instantiate DUT with correct port names
    top_level dut (
        .clk(clk),
        .rst_n(rst_n),
        .load_start(load_start),
        .infer_start(infer_start),
        .data_in_flat(input_data_flat),
        .argmax_out(argmax_out),
        .inference_done(inference_done),
        .load_done(load_done),
        .busy(busy)
    );

    // Clock generation (100 MHz)
    always #5 clk = ~clk;

    integer i;

    initial begin
        // Dump waveform for GTKWave
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top_level);

        // Initialize
        clk = 0;
        rst_n = 0;
        load_start = 0;
        infer_start = 0;

        // Reset pulse
        #20;
        rst_n = 1;

        // 1. Start Weight Loading (Crucial for Radar project)
        #20;
        $display("Starting Weight Load...");
        load_start = 1;
        #10;
        load_start = 0;

        // Wait for loader to finish
        wait(load_done);
        $display("Weights and Biases Loaded.");

        // 2. Prepare Radar Input Data
        for(i = 0; i < 100; i = i + 1) begin
            input_data_unpacked[i] = $random % 50;
        end

        // 3. Start Inference
        #20;
        $display("Starting Inference...");
        infer_start = 1;
        #10;
        infer_start = 0;

        // Wait until classifier finishes
        wait(inference_done);

        $display("-------------------------------------------");
        $display("Classification Result (Argmax) = %d", argmax_out);
        $display("-------------------------------------------");

        #50;
        $finish;
    end

endmodule