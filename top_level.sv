module top_level (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        load_start,
    input  logic        infer_start,
    // Flattened data_in for port compatibility
    input  logic signed [799:0] data_in_flat, 

    output logic [1:0]  argmax_out,
    output logic        inference_done,
    output logic        load_done,
    output logic        busy
);

    //////////////////////////////////////////////////////////
    // RAM Wires - UPDATED TO 14 BITS
    //////////////////////////////////////////////////////////
    logic        ldr_ram_we;
    logic        ldr_ram_bias_sel;
    logic [13:0] ldr_ram_w_addr; // Fixed: 14 bits
    logic [6:0]  ldr_ram_b_addr;
    logic signed [7:0] ldr_ram_w_data;
    logic signed [7:0] ldr_ram_b_data;

    logic        fsm_ram_re;
    logic        fsm_ram_bias_sel_r;
    logic [13:0] fsm_ram_r_w_addr; // Fixed: 14 bits
    logic [6:0]  fsm_ram_r_b_addr;

    logic signed [7:0]  ram_w_data_out;
    logic signed [31:0] ram_b_data_out;

    //////////////////////////////////////////////////////////
    // Layer Control & Flattening Buffers
    //////////////////////////////////////////////////////////
    logic        l1_start_new_neuron;
    logic [3:0]  l1_batch_sel;
    logic        l2_start_new_neuron;
    logic [2:0]  l2_batch_sel;
    logic        ol_start_new_neuron;
    logic [1:0]  ol_batch_sel;

    // Flattening vectors for layer connections
    logic signed [2047:0] l1_bias_flat, l1_out_flat;
    logic signed [51199:0] l1_weights_flat;

    logic signed [1023:0] l2_bias_flat, l2_out_flat;
    logic signed [17919:0] l2_weights_flat;

    logic signed [127:0] ol_bias_flat, ol_neuron_out_flat;
    logic signed [959:0]  ol_weights_flat;

    //////////////////////////////////////////////////////////
    // Bias & Weight Distribution Logic
    //////////////////////////////////////////////////////////
    // Internal unpacked arrays for logic processing
    logic signed [31:0] l1_bias [0:63];
    logic signed [31:0] l2_bias [0:31];
    logic signed [31:0] ol_bias [0:3];
    
    logic signed [7:0]  weight_buffer [0:9];
    logic [3:0]         weight_index;

    always_ff @(posedge clk) begin
        if (fsm_ram_re && fsm_ram_bias_sel_r) begin
            if (fsm_ram_r_b_addr < 64)
                l1_bias[fsm_ram_r_b_addr] <= ram_b_data_out;
            else if (fsm_ram_r_b_addr < 96)
                l2_bias[fsm_ram_r_b_addr-64] <= ram_b_data_out;
            else if (fsm_ram_r_b_addr < 100)
                ol_bias[fsm_ram_r_b_addr-96] <= ram_b_data_out;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) weight_index <= 0;
        else if (fsm_ram_re && !fsm_ram_bias_sel_r) begin
            weight_buffer[weight_index] <= ram_w_data_out;
            weight_index <= (weight_index == 9) ? 4'd0 : weight_index + 4'd1;
        end
    end

    //////////////////////////////////////////////////////////
    // Flattening Generate Blocks
    //////////////////////////////////////////////////////////
    genvar i, j;
    generate
        // Flatten Biases
        for (i=0; i<64; i++) assign l1_bias_flat[i*32 +: 32] = l1_bias[i];
        for (i=0; i<32; i++) assign l2_bias_flat[i*32 +: 32] = l2_bias[i];
        for (i=0; i<4;  i++) assign ol_bias_flat[i*32 +: 32] = ol_bias[i];

        // Flatten weights (Broadcasting weight_buffer)
        for (i=0; i<64; i++) 
            for (j=0; j<10; j++) assign l1_weights_flat[(i*100 + j)*8 +: 8] = weight_buffer[j];
            
        for (i=0; i<32; i++)
            for (j=0; j<10; j++) assign l2_weights_flat[((i*7 + 0)*10 + j)*8 +: 8] = weight_buffer[j];

        for (i=0; i<4; i++)
            for (j=0; j<10; j++) assign ol_weights_flat[((i*4 + 0)*10 + j)*8 +: 8] = weight_buffer[j];
    endgenerate

    //////////////////////////////////////////////////////////
    // Module Instantiations
    //////////////////////////////////////////////////////////

    weight_loader u_loader (
        .clk(clk), .rst_n(rst_n), .load_start(load_start),
        .ram_we(ldr_ram_we), .ram_bias_sel(ldr_ram_bias_sel),
        .ram_w_addr(ldr_ram_w_addr), .ram_b_addr(ldr_ram_b_addr),
        .ram_w_data(ldr_ram_w_data), .ram_b_data(ldr_ram_b_data),
        .load_done(load_done)
    );

    weight_bias_ram u_ram (
        .clk(clk), .rst_n(rst_n),
        .we(ldr_ram_we), .bias_sel(ldr_ram_bias_sel),
        .w_addr(ldr_ram_w_addr), .b_addr(ldr_ram_b_addr),
        .w_data_in(ldr_ram_w_data), .b_data_in(ldr_ram_b_data),
        .re(fsm_ram_re), .bias_sel_r(fsm_ram_bias_sel_r),
        .r_w_addr(fsm_ram_r_w_addr), .r_b_addr(fsm_ram_r_b_addr),
        .w_data_out(ram_w_data_out), .b_data_out(ram_b_data_out)
    );

    fsm_controller u_fsm (
        .clk(clk), .rst_n(rst_n), .start(infer_start),
        .l1_start_new_neuron(l1_start_new_neuron), .l1_batch_sel(l1_batch_sel),
        .l2_start_new_neuron(l2_start_new_neuron), .l2_batch_sel(l2_batch_sel),
        .ol_start_new_neuron(ol_start_new_neuron), .ol_batch_sel(ol_batch_sel),
        .ram_re(fsm_ram_re), .ram_bias_sel_r(fsm_ram_bias_sel_r),
        .ram_r_w_addr(fsm_ram_r_w_addr), .ram_r_b_addr(fsm_ram_r_b_addr),
        .inference_done(inference_done), .busy(busy)
    );

    neuron_layer u_l1 (
        .clk(clk), .rst_n(rst_n), .start(l1_start_new_neuron),
        .bias_flat(l1_bias_flat), .data_in_flat(data_in_flat), .weights_flat(l1_weights_flat),
        .out_flat(l1_out_flat), .out_valid() // Connect if needed
    );

    neuron_layer2 u_l2 (
        .clk(clk), .rst_n(rst_n), .start_new_neuron(l2_start_new_neuron),
        .bias_flat(l2_bias_flat), .data_in_flat(l1_out_flat), .weights_flat(l2_weights_flat),
        .batch_sel(l2_batch_sel), .out_flat(l2_out_flat)
    );

    output_layer u_ol (
        .clk(clk), .rst_n(rst_n), .start_new_neuron(ol_start_new_neuron),
        .bias_flat(ol_bias_flat), .data_in_flat(l2_out_flat), .weights_flat(ol_weights_flat),
        .batch_sel(ol_batch_sel), .neuron_out_flat(ol_neuron_out_flat), .argmax_out(argmax_out)
    );

endmodule