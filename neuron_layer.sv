module neuron_layer (
    input  logic clk, rst_n, start,
    input  logic signed [2047:0] bias_flat,
    input  logic signed [799:0]  data_in_flat,
    input  logic signed [51199:0] weights_flat,
    output logic signed [2047:0] out_flat,
    output logic out_valid
);
    logic signed [31:0] bias [0:63];
    logic signed [7:0]  data_in [0:99];
    logic signed [7:0]  weights [0:63][0:99];
    logic signed [31:0] out [0:63];

    genvar b, n, w, i;
    generate
        for (b = 0; b < 10; b = b + 1) begin : batch_lp
            for (n = 0; n < 64; n = n + 1) begin : nrn_lp
                for (w = 0; w < 10; w = w + 1) begin : w_lp
                    // Offset: 640
                    assign weights[n][b*10 + w] = weights_flat[(b*640 + n*10 + w)*8 +: 8];
                end
            end
        end
        for (i = 0; i < 64; i = i + 1) begin : misc
            assign bias[i] = bias_flat[i*32 +: 32];
            assign out_flat[i*32 +: 32] = out[i];
        end
        for (i = 0; i < 100; i = i + 1) begin : d_in
            assign data_in[i] = data_in_flat[i*8 +: 8];
        end
    endgenerate

    logic [3:0] batch_cnt;
    logic [5:0] v_pipe; 
    wire res_v = v_pipe[5];

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n || start) begin batch_cnt <= 0; v_pipe <= 0; out_valid <= 0; end
        else begin
            v_pipe <= {v_pipe[4:0], (batch_cnt < 10)};
            if (batch_cnt < 10) batch_cnt <= batch_cnt + 1;
            out_valid <= (batch_cnt == 10 && res_v);
        end
    end

    logic [79:0] cur_d;
    logic [79:0] cur_w [0:63];
    integer m, nx;

    always_ff @(posedge clk) begin
        for(m = 0; m < 10; m = m + 1) begin
            cur_d[m*8 +: 8] <= data_in[(batch_cnt * 10) + m];
            for(nx = 0; nx < 64; nx = nx + 1) begin
                cur_w[nx][m*8 +: 8] <= weights[nx][(batch_cnt * 10) + m];
            end
        end
    end

    genvar g;
    generate
        for(g = 0; g < 64; g = g + 1) begin : nrns
            logic signed [19:0] mv; logic signed [31:0] ac;
            mac u_m (.clk(clk), .rst_n(rst_n), .in_vec(cur_d), .weights_vec(cur_w[g]), .out(mv));
            always_ff @(posedge clk or negedge rst_n) begin
                if(!rst_n || start) ac <= 0;
                else if(res_v) ac <= ac + {{12{mv[19]}}, mv};
            end
            relu u_r (.clk(clk), .rst_n(rst_n), .in(ac + bias[g]), .out(out[g]));
        end
    endgenerate
endmodule