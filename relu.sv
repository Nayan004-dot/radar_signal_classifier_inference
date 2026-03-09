module relu(
    input  logic        clk,
    input  logic        rst_n,
    input  logic signed [31:0] in,
    output logic signed [31:0] out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out <= 32'b0;
        else begin
            if (in <= 0)
                out <= 32'b0;
            else
                out <= in;
        end
    end

endmodule