module adder_tree(
    input  logic clk,
    input  logic rst_n,

    // Flattened input: 10 elements * 16 bits = 160 bits
    input  logic signed [159:0] in_flat,

    output logic signed [19:0] out
);

    // Create a local wire array to map the flattened input back to 10x16 bits
    // This allows you to use in[0], in[1], etc. without port errors
    logic signed [15:0] in [0:9];
    
    genvar k;
    generate
        for (k = 0; k < 10; k = k + 1) begin : unpack_in
            assign in[k] = in_flat[k*16 +: 16];
        end
    endgenerate

    // Pipeline Stages
    logic signed [16:0] s1 [0:4];
    logic signed [17:0] s2 [0:1];
    logic signed [16:0] s1_for_pass1;
    logic signed [18:0] s3;
    logic signed [16:0] s1_for_pass2;

    integer i;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 20'sd0;
            s3  <= 19'sd0;
            s1_for_pass1 <= 17'sd0;
            s1_for_pass2 <= 17'sd0;

            for (i = 0; i < 5; i = i + 1) s1[i] <= 17'sd0;
            for (i = 0; i < 2; i = i + 1) s2[i] <= 18'sd0;
        end
        else begin
            // Stage 1: 10 inputs -> 5 sums
            s1[0] <= in[0] + in[1];
            s1[1] <= in[2] + in[3];
            s1[2] <= in[4] + in[5];
            s1[3] <= in[6] + in[7];
            s1[4] <= in[8] + in[9];

            // Stage 2: 5 sums -> 2 sums + 1 bypass
            s2[0] <= s1[0] + s1[1];
            s2[1] <= s1[2] + s1[3];
            s1_for_pass1 <= s1[4];

            // Stage 3: 2 sums -> 1 sum + 1 bypass
            s3 <= s2[0] + s2[1];
            s1_for_pass2 <= s1_for_pass1;

            // Final Stage: Sum the final branch
            out <= s3 + s1_for_pass2;
        end
    end

endmodule