module fsm_controller (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,

    // Layer1
    output logic        l1_start_new_neuron,
    output logic [3:0]  l1_batch_sel,

    // Layer2
    output logic        l2_start_new_neuron,
    output logic [2:0]  l2_batch_sel,

    // Output layer
    output logic        ol_start_new_neuron,
    output logic [1:0]  ol_batch_sel,

    // RAM read - EXPANDED TO 14 BITS
    output logic        ram_re,
    output logic        ram_bias_sel_r,
    output logic [13:0] ram_r_w_addr, 
    output logic [6:0]  ram_r_b_addr,

    // Status
    output logic        inference_done,
    output logic        busy
);

    typedef enum logic [3:0] {
        IDLE     = 4'd0,
        L1_BIAS  = 4'd1,
        L1_RUN   = 4'd2,
        L1_DRAIN = 4'd3,
        L2_BIAS  = 4'd4,
        L2_RUN   = 4'd5,
        L2_DRAIN = 4'd6,
        OL_BIAS  = 4'd7,
        OL_RUN   = 4'd8,
        OL_DRAIN = 4'd9,
        DONE     = 4'd10
    } state_t;

    state_t state, next_state;

    logic [3:0] batch_cnt;
    logic [2:0] drain_cnt;
    logic [6:0] bias_cnt;

    localparam [2:0]  DRAIN_LIMIT = 3'd6;
    localparam [13:0] L1_W_BASE   = 14'd0;
    localparam [13:0] L2_W_BASE   = 14'd6400;
    localparam [13:0] OL_W_BASE   = 14'd8640;

    //////////////////////////////////////////////////////////
    // State register & Counter Logic
    //////////////////////////////////////////////////////////
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state     <= IDLE;
            batch_cnt <= 4'd0;
            drain_cnt <= 3'd0;
            bias_cnt  <= 7'd0;
        end
        else begin
            state <= next_state;

            case(state)
                L1_BIAS: if(bias_cnt < 7'd63) bias_cnt <= bias_cnt + 7'd1; else bias_cnt <= 7'd0;
                L2_BIAS: if(bias_cnt < 7'd31) bias_cnt <= bias_cnt + 7'd1; else bias_cnt <= 7'd0;
                OL_BIAS: if(bias_cnt < 7'd3)  bias_cnt <= bias_cnt + 7'd1; else bias_cnt <= 7'd0;

                L1_RUN:  if(batch_cnt < 4'd9) batch_cnt <= batch_cnt + 4'd1; else batch_cnt <= 4'd0;
                L2_RUN:  if(batch_cnt < 4'd6) batch_cnt <= batch_cnt + 4'd1; else batch_cnt <= 4'd0;
                OL_RUN:  if(batch_cnt < 4'd3) batch_cnt <= batch_cnt + 4'd1; else batch_cnt <= 4'd0;

                L1_DRAIN, L2_DRAIN, OL_DRAIN:
                    if(drain_cnt < DRAIN_LIMIT) drain_cnt <= drain_cnt + 3'd1;
                    else drain_cnt <= 3'd0;

                default: begin
                    batch_cnt <= 4'd0;
                    drain_cnt <= 3'd0;
                    bias_cnt  <= 7'd0;
                end
            endcase
        end
    end

    //////////////////////////////////////////////////////////
    // Next state logic
    //////////////////////////////////////////////////////////
    always_comb begin
        next_state = state;
        case(state)
            IDLE:     if(start) next_state = L1_BIAS;
            L1_BIAS:  if(bias_cnt == 7'd63) next_state = L1_RUN;
            L1_RUN:   if(batch_cnt == 4'd9) next_state = L1_DRAIN;
            L1_DRAIN: if(drain_cnt == DRAIN_LIMIT) next_state = L2_BIAS;
            L2_BIAS:  if(bias_cnt == 7'd31) next_state = L2_RUN;
            L2_RUN:   if(batch_cnt == 4'd6) next_state = L2_DRAIN;
            L2_DRAIN: if(drain_cnt == DRAIN_LIMIT) next_state = OL_BIAS;
            OL_BIAS:  if(bias_cnt == 7'd3)  next_state = OL_RUN;
            OL_RUN:   if(batch_cnt == 4'd3)  next_state = OL_DRAIN;
            OL_DRAIN: if(drain_cnt == DRAIN_LIMIT) next_state = DONE;
            DONE:     next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

    //////////////////////////////////////////////////////////
    // Output Assignments
    //////////////////////////////////////////////////////////
    assign l1_batch_sel = (state == L1_RUN) ? batch_cnt : 4'd0;
    assign l2_batch_sel = (state == L2_RUN) ? batch_cnt[2:0] : 3'd0;
    assign ol_batch_sel = (state == OL_RUN) ? batch_cnt[1:0] : 2'd0;

    assign l1_start_new_neuron = (state == L1_RUN && batch_cnt == 4'd0);
    assign l2_start_new_neuron = (state == L2_RUN && batch_cnt == 4'd0);
    assign ol_start_new_neuron = (state == OL_RUN && batch_cnt == 4'd0);

    //////////////////////////////////////////////////////////
    // RAM read control
    //////////////////////////////////////////////////////////
    always_comb begin
        ram_re = 1'b0;
        ram_bias_sel_r = 1'b0;
        ram_r_w_addr = 14'd0;
        ram_r_b_addr = 7'd0;

        case(state)
            L1_BIAS: begin
                ram_re = 1'b1; ram_bias_sel_r = 1'b1; ram_r_b_addr = bias_cnt;
            end
            L2_BIAS: begin
                ram_re = 1'b1; ram_bias_sel_r = 1'b1; ram_r_b_addr = 7'd64 + bias_cnt;
            end
            OL_BIAS: begin
                ram_re = 1'b1; ram_bias_sel_r = 1'b1; ram_r_b_addr = 7'd96 + bias_cnt;
            end
            L1_RUN: begin
                ram_re = 1'b1; ram_r_w_addr = L1_W_BASE + (14'({10'd0, batch_cnt}) * 14'd640);
            end
            L2_RUN: begin
                ram_re = 1'b1; ram_r_w_addr = L2_W_BASE + (14'({10'd0, batch_cnt}) * 14'd320);
            end
            OL_RUN: begin
                ram_re = 1'b1; ram_r_w_addr = OL_W_BASE + (14'({10'd0, batch_cnt}) * 14'd40);
            end
            default: ;
        endcase
    end

    assign inference_done = (state == DONE);
    assign busy = (state != IDLE);

endmodule