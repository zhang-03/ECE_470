module icache #(
    parameter LINE_NUM = 2,             // cacheline数，暂时设16条cacheline
    parameter WORDS_PER_LINE = 16,       // 每条cacheline 16条指令
    parameter WORD_WIDTH = 32,           // 指令宽度
    parameter FETCH_WIDTH = 4            // 每周期抓取数量，即抓取的命令条数
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [$clog2(LINE_NUM*WORDS_PER_LINE)-1:0] fetch_addr,   // 取指令编号（绝对编号, 从0编号到N*16-1）
    output logic [FETCH_WIDTH-1:0][WORD_WIDTH-1:0] inst_batch        // 批量输出
);

    // cacheline阵列
    logic [WORD_WIDTH-1:0] icache_mem [0:LINE_NUM-1][0:WORDS_PER_LINE-1]; // 二维阵列，LINE_NUM行，每行WORDS_PER_LINE列，每列WORD_WIDTH位宽

    // 抓取逻辑
    logic [$clog2(LINE_NUM)-1:0]          line_idx; // 16行要4bit来表示所有行数
    logic [$clog2(WORDS_PER_LINE)-1:0]    word_off; // 每行16条指令要4bit来表示偏移量


    // 添加组合逻辑变量
    logic [$clog2(WORDS_PER_LINE):0]    curr_off;
    logic [$clog2(LINE_NUM):0]          curr_line;
    logic [$clog2(WORDS_PER_LINE):0]    curr_word;

    // 锁定起始行数和起始指令偏移量
    assign line_idx = fetch_addr / WORDS_PER_LINE;
    assign word_off = fetch_addr % WORDS_PER_LINE;


    always_comb begin
        for (int i = 0; i < FETCH_WIDTH; i++) begin
            // 计算每一条指令实际抓取的行/列
            curr_off = word_off + i;
            curr_line = line_idx + (curr_off / WORDS_PER_LINE);
            curr_word = curr_off % WORDS_PER_LINE;
            //$display("i=%0d, fetch_addr=%0d, curr_line=%0d, curr_word=%0d", i, fetch_addr, curr_line, curr_word);

            if (curr_line < LINE_NUM)
                inst_batch[i] = icache_mem[curr_line][curr_word];
            else
                inst_batch[i] = 32'h00000013; // 越界补NOP: addi x0, x0, 0 (RISC-V NOP指令)
        end
    end

    // 初始化支持二维阵列mem文件加载
    initial begin
        // 假设mem文件已经每16行是一组cacheline，手动加载进二维阵列
        // 若仿真器不支持二维，可先读入一维temp数组，再for循环分配
        logic [WORD_WIDTH-1:0] tmp_mem [0:LINE_NUM*WORDS_PER_LINE-1];
        $readmemh("./memory/test.mem", tmp_mem);

        for (int i = 0; i < LINE_NUM; i++)
            for (int j = 0; j < WORDS_PER_LINE; j++)
                icache_mem[i][j] = tmp_mem[i*WORDS_PER_LINE + j];

        // 可打印部分内容，便于debug
        $display("=== icache_mem ===");
        for (int i = 0; i < LINE_NUM; i = i + 1) begin
            $write("cacheline[%0d]: ", i);
            for (int j = 0; j < WORDS_PER_LINE; j = j + 1)
                $write("%h ", icache_mem[i][j]);
            $write(" \n");
        end
    end

endmodule

