module weight_bias_ram(
    input  logic clk,
    input  logic rst_n,

    // Write port - Expanded w_addr to 14 bits
    input  logic we,
    input  logic bias_sel,
    input  logic [13:0] w_addr, 
    input  logic [6:0]  b_addr,
    input  logic signed [7:0] w_data_in,
    input  logic signed [7:0] b_data_in,

    // Read port - Expanded r_w_addr to 14 bits
    input  logic re,
    input  logic bias_sel_r,
    input  logic [13:0] r_w_addr,
    input  logic [6:0]  r_b_addr,

    output logic signed [7:0]  w_data_out,
    output logic signed [31:0] b_data_out
);

    ////////////////////////////////////////////////////////////
    // Memory
    ////////////////////////////////////////////////////////////
    // 8800 weights total
    logic signed [7:0] weight_mem [0:8799];
    // 100 biases total
    logic signed [7:0] bias_mem   [0:99];

    ////////////////////////////////////////////////////////////
    // Write Logic
    ////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin
        if(we) begin
            if(!bias_sel) begin
                // Ensure index is within bounds for simulation stability
                if (w_addr < 14'd8800)
                    weight_mem[w_addr] <= w_data_in;
            end
            else begin
                if (b_addr < 7'd100)
                    bias_mem[b_addr] <= b_data_in;
            end
        end
    end

    ////////////////////////////////////////////////////////////
    // Read Logic
    ////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin
        if(re) begin
            if(!bias_sel_r) begin
                if (r_w_addr < 14'd8800)
                    w_data_out <= weight_mem[r_w_addr];
                else
                    w_data_out <= 8'sd0;
            end
            else begin
                if (r_b_addr < 7'd100)
                    // Sign extend 8-bit bias to 32-bit
                    b_data_out <= {{24{bias_mem[r_b_addr][7]}}, bias_mem[r_b_addr]};
                else
                    b_data_out <= 32'sd0;
            end
        end
    end

endmodule