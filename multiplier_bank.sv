module multiplier_bank (
    input  logic clk,
    input  logic rst_n,

    // Flattened inputs: 10 elements * 8 bits = 80 bits
    input  logic signed [79:0] data_in_flat,
    input  logic signed [79:0] weights_flat,

    // Flattened output: 10 elements * 16 bits = 160 bits
    output logic signed [159:0] products_flat
);

    // Internal unpacked arrays for logic processing
    logic signed [7:0]  data_in  [0:9];
    logic signed [7:0]  weights  [0:9];
    logic signed [15:0] products [0:9];

    // 1. Unpack flattened inputs
    genvar k;
    generate
        for (k = 0; k < 10; k = k + 1) begin : unpack_ports
            assign data_in[k] = data_in_flat[k*8 +: 8];
            assign weights[k] = weights_flat[k*8 +: 8];
            // 2. Pack internal products into the flattened output port
            assign products_flat[k*16 +: 16] = products[k];
        end
    endgenerate

    integer i;

    // 3. Multiplication Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 10; i = i + 1) begin
                products[i] <= 16'sd0; // Match the 16-bit width
            end
        end
        else begin
            for (i = 0; i < 10; i = i + 1) begin
                // Standard 8x8 signed multiply producing a 16-bit result
                products[i] <= data_in[i] * weights[i];
            end
        end
    end

endmodule