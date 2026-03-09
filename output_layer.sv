module output_layer (
    input  logic clk, rst_n, start_new_neuron,
    input  logic signed [127:0] bias_flat,
    input  logic signed [1023:0] data_in_flat,
    input  logic signed [959:0] weights_flat, 
    input  logic [1:0] batch_sel,
    output logic signed [127:0] neuron_out_flat,
    output logic [1:0] argmax_out
);
    logic signed [31:0] bias [0:3];
    logic signed [31:0] data_in [0:31];
    logic signed [7:0]  weights [0:3][0:39];
    logic signed [31:0] n_out [0:3];

    genvar b, n, w, i;
    generate
        for (b = 0; b < 4; b = b + 1) begin : b_lp
            for (n = 0; n < 4; n = n + 1) begin : n_lp
                for (w = 0; w < 10; w = w + 1) begin : w_lp
                    // Offset: 40
                    assign weights[n][b*10 + w] = weights_flat[(b*40 + n*10 + w)*8 +: 8];
                end
            end
        end
        for (i = 0; i < 4; i = i + 1) begin : unpack_misc
            assign bias[i] = bias_flat[i*32 +: 32];
            assign neuron_out_flat[i*32 +: 32] = n_out[i];
        end
        for (i = 0; i < 32; i = i + 1) begin : unpack_data
            assign data_in[i] = data_in_flat[i*32 +: 32];
        end
    endgenerate

    logic [79:0] cur_data;
    logic [79:0] cur_weights [0:3];
    integer m, n_idx;

    always_ff @(posedge clk) begin
        for(m = 0; m < 10; m = m + 1) begin
            if (m > 7) 
                cur_data[m*8 +: 8] <= 8'sd0;
            else 
                cur_data[m*8 +: 8] <= data_in[(batch_sel * 8) + m][7:0];
            
            for(n_idx = 0; n_idx < 4; n_idx = n_idx + 1) begin
                cur_weights[n_idx][m*8 +: 8] <= weights[n_idx][batch_sel*10 + m];
            end
        end
    end

    genvar nrn;
    generate
        for(nrn = 0; nrn < 4; nrn = nrn + 1) begin : nrn_blk
            logic signed [19:0] mv; logic signed [31:0] ac;
            mac u_m (.clk(clk),.rst_n(rst_n),.in_vec(cur_data),.weights_vec(cur_weights[nrn]),.out(mv));
            always_ff @(posedge clk or negedge rst_n) begin
                if(!rst_n || start_new_neuron) ac <= 32'sd0;
                else ac <= ac + {{12{mv[19]}}, mv};
            end
            assign n_out[nrn] = ac + bias[nrn];
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) argmax_out <= 2'd0;
        else begin
            if(n_out[0]>=n_out[1] && n_out[0]>=n_out[2] && n_out[0]>=n_out[3]) argmax_out <= 2'd0;
            else if(n_out[1]>=n_out[2] && n_out[1]>=n_out[3]) argmax_out <= 2'd1;
            else if(n_out[2]>=n_out[3]) argmax_out <= 2'd2;
            else argmax_out <= 2'd3;
        end
    end
endmodule