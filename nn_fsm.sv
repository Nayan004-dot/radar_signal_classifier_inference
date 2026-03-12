module nn_fsm(
    input  wire clk,
    input  wire rst_n,          
    input  wire start,          
    input  wire [799:0] in_flat, 
    output reg  [1:0] prediction,
    output reg  done            
);

wire signed [7:0] in [0:99];
genvar g;
generate
    for(g = 0; g < 100; g = g + 1) begin : unpack_inputs
        assign in[g] = in_flat[g*8 +: 8]; 
    end
endgenerate

localparam IDLE    = 3'd0;
localparam CALC_L1 = 3'd1;
localparam CALC_L2 = 3'd2;
localparam CALC_L3 = 3'd3;
localparam ARGMAX  = 3'd4;

reg [2:0] state;
reg [6:0] n_idx;     

reg signed [7:0]  w1 [0:63][0:99];
reg signed [7:0]  w2 [0:31][0:63];
reg signed [7:0]  w3 [0:3][0:31];
reg signed [31:0] b1 [0:63];
reg signed [31:0] b2 [0:31];
reg signed [31:0] b3 [0:3];

reg signed [31:0] l1 [0:63];
reg signed [31:0] l2 [0:31];
reg signed [31:0] l3 [0:3];

reg signed [7:0] w1_flat [0:6399];
reg signed [7:0] w2_flat [0:2047];
reg signed [7:0] w3_flat [0:127];

integer i, j, idx;
reg signed [31:0] acc;       
reg signed [31:0] mult_res;

initial begin
    $readmemh("w1_neuron_major.mem", w1_flat);
    $readmemh("w2_neuron_major.mem", w2_flat);
    $readmemh("w3_neuron_major.mem", w3_flat);
    $readmemh("q_b1.mem", b1);
    $readmemh("q_b2.mem", b2);
    $readmemh("q_b3.mem", b3);

    idx = 0; for(i=0; i<64; i=i+1) for(j=0; j<100; j=j+1) begin w1[i][j] = w1_flat[idx]; idx = idx + 1; end
    idx = 0; for(i=0; i<32; i=i+1) for(j=0; j<64; j=j+1)  begin w2[i][j] = w2_flat[idx]; idx = idx + 1; end
    idx = 0; for(i=0; i<4;  i=i+1) for(j=0; j<32; j=j+1)  begin w3[i][j] = w3_flat[idx]; idx = idx + 1; end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state      <= IDLE;
        done       <= 1'b0;
        prediction <= 2'd0;
        n_idx      <= 7'd0;
    end else begin
        case (state)
            IDLE: begin
                done <= 1'b0;
                if (start) begin
                    state <= CALC_L1;
                    n_idx <= 7'd0;
                end
            end

            CALC_L1: begin
                acc = b1[n_idx];
                for(j=0; j<100; j=j+1) begin
                    mult_res = $signed(in[j]) * $signed(w1[n_idx][j]);
                    acc = acc + mult_res;
                end
                acc = acc >>> 7;
                if(acc < 0) acc = 0; // 32-bit ReLU
                l1[n_idx] <= acc;
                
                if (n_idx == 63) begin
                    n_idx <= 7'd0;
                    state <= CALC_L2;
                end else begin
                    n_idx <= n_idx + 1;
                end
            end

            CALC_L2: begin
                acc = b2[n_idx];
                for(j=0; j<64; j=j+1) begin
                    mult_res = $signed(l1[j]) * $signed(w2[n_idx][j]);
                    acc = acc + mult_res;
                end
                acc = acc >>> 7;
                if(acc < 0) acc = 0; // 32-bit ReLU
                l2[n_idx] <= acc;
                
                if (n_idx == 31) begin
                    n_idx <= 7'd0;
                    state <= CALC_L3;
                end else begin
                    n_idx <= n_idx + 1;
                end
            end

            CALC_L3: begin
                acc = b3[n_idx];
                for(j=0; j<32; j=j+1) begin
                    mult_res = $signed(l2[j]) * $signed(w3[n_idx][j]);
                    acc = acc + mult_res;
                end
                acc = acc >>> 7; 
                l3[n_idx] <= acc;
                
                if (n_idx == 3) begin
                    state <= ARGMAX;
                end else begin
                    n_idx <= n_idx + 1;
                end
            end

            ARGMAX: begin
                if(l3[0]>=l3[1] && l3[0]>=l3[2] && l3[0]>=l3[3]) prediction <= 2'd0;
                else if(l3[1]>=l3[2] && l3[1]>=l3[3])            prediction <= 2'd1;
                else if(l3[2]>=l3[3])                            prediction <= 2'd2;
                else                                             prediction <= 2'd3;
                    
                done  <= 1'b1;
                state <= IDLE;
            end
        endcase
    end
end
endmodule