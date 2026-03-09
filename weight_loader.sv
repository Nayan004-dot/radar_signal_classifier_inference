module weight_loader(
    input  logic clk,
    input  logic rst_n,
    input  logic load_start,
    output logic ram_we,
    output logic ram_bias_sel,
    output logic [13:0] ram_w_addr,
    output logic [6:0]  ram_b_addr,
    output logic signed [7:0] ram_w_data,
    output logic signed [7:0] ram_b_data,
    output logic load_done
);

    logic signed [7:0] weight_mem [0:8799];
    logic signed [7:0] bias_mem   [0:99];
    logic [13:0] count;
    logic        active;

    initial begin
        $readmemh("q_w1_batch0.mem", weight_mem, 0, 639);
        $readmemh("q_w1_batch1.mem", weight_mem, 640, 1279);
        $readmemh("q_w1_batch2.mem", weight_mem, 1280, 1919);
        $readmemh("q_w1_batch3.mem", weight_mem, 1920, 2559);
        $readmemh("q_w1_batch4.mem", weight_mem, 2560, 3199);
        $readmemh("q_w1_batch5.mem", weight_mem, 3200, 3839);
        $readmemh("q_w1_batch6.mem", weight_mem, 3840, 4479);
        $readmemh("q_w1_batch7.mem", weight_mem, 4480, 5119);
        $readmemh("q_w1_batch8.mem", weight_mem, 5120, 5759);
        $readmemh("q_w1_batch9.mem", weight_mem, 5760, 6399);
        $readmemh("q_w2_batch0.mem", weight_mem, 6400, 6719);
        $readmemh("q_w2_batch1.mem", weight_mem, 6720, 7039);
        $readmemh("q_w2_batch2.mem", weight_mem, 7040, 7359);
        $readmemh("q_w2_batch3.mem", weight_mem, 7360, 7679);
        $readmemh("q_w2_batch4.mem", weight_mem, 7680, 7999);
        $readmemh("q_w2_batch5.mem", weight_mem, 8000, 8319);
        $readmemh("q_w2_batch6.mem", weight_mem, 8320, 8639);
        $readmemh("q_w3_batch0.mem", weight_mem, 8640, 8679);
        $readmemh("q_w3_batch1.mem", weight_mem, 8680, 8719);
        $readmemh("q_w3_batch2.mem", weight_mem, 8720, 8759);
        $readmemh("q_w3_batch3.mem", weight_mem, 8760, 8799);
        $readmemh("q_b1.mem", bias_mem, 0, 63);
        $readmemh("q_b2.mem", bias_mem, 64, 95);
        $readmemh("q_b3.mem", bias_mem, 96, 99);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 14'd0;
            active <= 1'b0;
            ram_we <= 1'b0;
            ram_bias_sel <= 1'b0;
            load_done <= 1'b0;
            ram_w_addr <= 14'd0;
            ram_b_addr <= 7'd0;
            ram_w_data <= 8'sd0;
            ram_b_data <= 8'sd0;
        end else begin
            if (load_start && !load_done) active <= 1'b1;
            
            if (active) begin
                if (count < 14'd8800) begin
                    ram_we <= 1'b1;
                    ram_bias_sel <= 1'b0;
                    ram_w_addr <= count;
                    ram_w_data <= weight_mem[count];
                    count <= count + 14'd1;
                end else if (count < 14'd8900) begin
                    ram_we <= 1'b1;
                    ram_bias_sel <= 1'b1;
                    ram_b_addr <= count - 14'd8800;
                    ram_b_data <= bias_mem[count - 14'd8800];
                    count <= count + 14'd1;
                end else begin
                    ram_we <= 1'b0;
                    active <= 1'b0;
                    load_done <= 1'b1;
                end
            end
        end
    end
endmodule