module neuron_layer2 (
    input  logic clk, rst_n, start_new_neuron,
    input  logic signed [1023:0] bias_flat,
    input  logic signed [2047:0] data_in_flat,
    input  logic signed [17919:0] weights_flat, 
    input  logic [2:0] batch_sel,
    output logic signed [1023:0] out_flat
);
    logic signed [31:0] bias [0:31];
    logic signed [31:0] data_in [0:63];
    logic signed [7:0]  weights [0:31][0:69];
    logic signed [31:0] out [0:31];

    genvar b, n, w, i;
    generate
        for (b = 0; b < 7; b = b + 1) begin : b_lp
            for (n = 0; n < 32; n = n + 1) begin : n_lp
                for (w = 0; w < 10; w = w + 1) begin : w_lp
                    // Offset: 320
                    assign weights[n][b*10 + w] = weights_flat[(b*320 + n*10 + w)*8 +: 8];
                end
            end
        end
        for (i = 0; i < 32; i = i + 1) begin : unpack_misc
            assign bias[i] = bias_flat[i*32 +: 32];
            assign out_flat[i*32 +: 32] = out[i];
        end
        for (i = 0; i < 64; i = i + 1) begin : unpack_data
            assign data_in[i] = data_in_flat[i*32 +: 32];
        end
    endgenerate

    logic [79:0] cur_data;
    logic [79:0] cur_weights [0:31];
    integer m, n_idx;

    always_ff @(posedge clk) begin
        for(m = 0; m < 10; m = m + 1) begin
            if (batch_sel == 3'd6 && m > 3) 
                cur_data[m*8 +: 8] <= 8'sd0;
            else 
                cur_data[m*8 +: 8] <= data_in[(batch_sel * 10) + m][7:0];
            
            for(n_idx = 0; n_idx < 32; n_idx = n_idx + 1) begin
                cur_weights[n_idx][m*8 +: 8] <= weights[n_idx][batch_sel*10 + m];
            end
        end
    end

    genvar nrn;
    generate
        for(nrn = 0; nrn < 32; nrn = nrn + 1) begin : nrn_blk
            logic signed [19:0] mv; logic signed [31:0] ac;
            mac u_m (.clk(clk),.rst_n(rst_n),.in_vec(cur_data),.weights_vec(cur_weights[nrn]),.out(mv));
            always_ff @(posedge clk or negedge rst_n) begin
                if(!rst_n || start_new_neuron) ac <= 32'sd0;
                else ac <= ac + {{12{mv[19]}}, mv};
            end
            relu u_r (.clk(clk),.rst_n(rst_n),.in(ac + bias[nrn]),.out(out[nrn]));
        end
    endgenerate
endmodule