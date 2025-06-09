module id_stage #(
    parameter FETCH_WIDTH = 4
)(
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic [FETCH_WIDTH-1:0][31:0] inst_in,   // 批量指令
    input  logic [31:0]                  pc_in,     // 起始PC

    output decode_t [FETCH_WIDTH-1:0]    dec_out,   // 批量解码结果
    output logic   [FETCH_WIDTH-1:0]     dec_valid  // 每条是否有效
);

    // 简单解码，只演示R/I型
    always_comb begin
        for (int i = 0; i < FETCH_WIDTH; i++) begin
            dec_valid[i]   = (inst_in[i] != 32'b0);
            dec_out[i].opcode = inst_in[i][6:0];
            dec_out[i].rd     = inst_in[i][11:7];
            dec_out[i].rs1    = inst_in[i][19:15];
            dec_out[i].rs2    = inst_in[i][24:20];
            // 这里只简单演示I型立即数解码，其它类型请自行完善
            dec_out[i].imm    = {{20{inst_in[i][31]}}, inst_in[i][31:20]};
            dec_out[i].pc     = pc_in + 4*i;  // 每条指令顺序加4
        end
    end

endmodule
