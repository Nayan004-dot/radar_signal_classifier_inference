module top_level (
    input  wire clk,            
    input  wire rst_btn,        
    input  wire start_btn,      
    input  wire [1:0] sw,       
    output wire [1:0] led_pred, 
    output wire led_done        
);

    // 1. Start Button Edge Detector (Debounce to 1 clock pulse)
    reg btn_sync_0, btn_sync_1;
    wire start_pulse = btn_sync_0 & ~btn_sync_1;
    
    always @(posedge clk) begin
        btn_sync_0 <= start_btn;
        btn_sync_1 <= btn_sync_0;
    end

    // 2. Test Vector ROM
    (* rom_style = "block" *) reg [799:0] test_rom [0:3];
    
    initial begin
        $readmemh("test_vectors.mem", test_rom);
    end

    reg [799:0] selected_input;
    always @(posedge clk) begin
        selected_input <= test_rom[sw];
    end

    // 3. AI Core
    nn_fsm anomaly_detector (
        .clk(clk),
        .rst_n(~rst_btn),      // Active-low internal reset
        .start(start_pulse),
        .in_flat(selected_input),
        .prediction(led_pred),
        .done(led_done)
    );

endmodule