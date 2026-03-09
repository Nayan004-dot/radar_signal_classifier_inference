module mac(
    input  logic clk,
    input  logic rst_n,
    input  logic signed [79:0] in_vec,      // Renamed for total clarity
    input  logic signed [79:0] weights_vec,
    output logic signed [19:0] out
);
    wire signed [159:0] prod_vec;

    multiplier_bank u_bank (
        .clk(clk),
        .rst_n(rst_n),
        .data_in_flat(in_vec),
        .weights_flat(weights_vec),
        .products_flat(prod_vec)
    );

    adder_tree u_tree (
        .clk(clk),
        .rst_n(rst_n),
        .in_flat(prod_vec),
        .out(out)
    );
endmodule