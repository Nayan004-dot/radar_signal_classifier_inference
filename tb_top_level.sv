`timescale 1ns / 1ps

module tb_top_level;

    reg clk;
    reg rst_btn;
    reg start_btn;
    reg [1:0] sw;
    wire [1:0] led_pred;
    wire led_done;

    top_level dut (
        .clk(clk),
        .rst_btn(rst_btn),
        .start_btn(start_btn),
        .sw(sw),
        .led_pred(led_pred),
        .led_done(led_done)
    );

    always #5 clk = ~clk;

    initial begin
        $display("Starting Top-Level Physical Simulation...");
        clk = 0; start_btn = 0; sw = 2'b00;
        
        rst_btn = 1; #30; rst_btn = 0; #30; // Reset pulse
        $display("========================================");

        // TEST DRONE (Switch 00)
        $display("Testing Switch [00] - Drone...");
        sw = 2'b00; #20;
        start_btn = 1; #50; start_btn = 0; 
        
        wait(led_done == 1'b1);
        $display("L3 Scores -> C0:%d, C1:%d, C2:%d, C3:%d", 
                 $signed(dut.anomaly_detector.l3[0]), $signed(dut.anomaly_detector.l3[1]), 
                 $signed(dut.anomaly_detector.l3[2]), $signed(dut.anomaly_detector.l3[3]));
        $display("Prediction LED: %d\n", led_pred);
        #50;

        // TEST BIRD (Switch 01)
        $display("Testing Switch [01] - Bird...");
        sw = 2'b01; #20;
        start_btn = 1; #50; start_btn = 0; 
        
        wait(led_done == 1'b1);
        $display("L3 Scores -> C0:%d, C1:%d, C2:%d, C3:%d", 
                 $signed(dut.anomaly_detector.l3[0]), $signed(dut.anomaly_detector.l3[1]), 
                 $signed(dut.anomaly_detector.l3[2]), $signed(dut.anomaly_detector.l3[3]));
        $display("Prediction LED: %d", led_pred);
        $display("========================================");
        
        #20;
        // ---------------------------------------------------------
        // TEST 3: Simulate testing Class 2 (Car)
        // ---------------------------------------------------------
        $display("Testing Switch [10] - Car...");
        sw = 2'b10; // Flip the physical switch to 2
        #20;
        
        // "Press" the start button
        start_btn = 1; #50; start_btn = 0; 
        
        // Wait for inference to finish
        wait(led_done == 1'b1);
        
        $display("L3 Scores -> C0:%d, C1:%d, C2:%d, C3:%d", 
                 $signed(dut.anomaly_detector.l3[0]), $signed(dut.anomaly_detector.l3[1]), 
                 $signed(dut.anomaly_detector.l3[2]), $signed(dut.anomaly_detector.l3[3]));
                 
        $display("Prediction LED: %d", led_pred);
        $display("========================================");
        #50;
         $finish;
    end
endmodule