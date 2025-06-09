module fetch_unit #(
    parameter FETCH_WIDTH = 4,
    parameter PC_WIDTH = 32        // 够用即可，比如支持4K条指令
)(
    input  logic clk,
    input  logic rst_n,
    // 控制接口
    input  logic flush,            // 流水线flush/回滚 （如果出现misprediction）
    input  logic [PC_WIDTH-1:0] new_pc,   // flush时指定的新PC
    input  logic stall,            // 下游阻塞（decode/乱序窗口满）

    // 分支预测接口
    input  logic branch_taken,         // 是否预测跳转
    input  logic [PC_WIDTH-1:0] branch_target, // 跳转目标

    // icache接口
    output logic [PC_WIDTH-1:0] fetch_addr,       // 取指地址
    input  logic [FETCH_WIDTH-1:0][31:0] inst_batch, // icache抓到的指令

    // IF/ID输出
    output logic [FETCH_WIDTH-1:0][31:0] inst_out,   // 传递给decode的指令
    output logic [PC_WIDTH-1:0] pc_out               // 输出PC（可选打包为IF_ID包）
);
    logic [PC_WIDTH-1:0] PC, next_PC;

    // PC更新逻辑
    always_comb begin
        if (flush)
            next_PC = new_pc;
        else if (!stall) begin
            if (branch_taken)
                next_PC = branch_target;
            else
                next_PC = PC + FETCH_WIDTH; // 顺序推进
        end else
            next_PC = PC;
    end

    // PC寄存器
    always_ff @(posedge clk) begin
        if (!rst_n)
            PC <= 0;
        else
            PC <= next_PC;
    end

    // 发给icache的地址
    assign fetch_addr = PC;

    // IF打包输出
    assign inst_out = inst_batch;
    assign pc_out = PC; // 或做成数组打包

endmodule
