`timescale 1ns/1ps

module icache_testbench;
    initial $dumpvars(0, icache_testbench);
    parameter LINE_NUM = 2;
    parameter WORDS_PER_LINE = 16;
    parameter WORD_WIDTH = 32;
    parameter FETCH_WIDTH = 4;

    logic clk;
    logic rst_n;
    logic [$clog2(LINE_NUM*WORDS_PER_LINE)-1:0] fetch_addr;
    logic [FETCH_WIDTH-1:0][WORD_WIDTH-1:0] inst_batch;

    // 实例化 icache
    icache #(
        .LINE_NUM(LINE_NUM),
        .WORDS_PER_LINE(WORDS_PER_LINE),
        .WORD_WIDTH(WORD_WIDTH),
        .FETCH_WIDTH(FETCH_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .fetch_addr(fetch_addr),
        .inst_batch(inst_batch)
    );

    // 时钟与复位
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        rst_n = 0;
        #15 rst_n = 1;
    end

    // 测试主流程
    initial begin
        #30;
        $display("==== [1] fetch (within line) ====");
        fetch_addr = 0; #1; // 第一行开头
        print_batch(fetch_addr, inst_batch);

        fetch_addr = 4; #1; // 第一行中部
        print_batch(fetch_addr, inst_batch);

        $display("\n==== [2] fetch (across lines) ====");
        fetch_addr = 14; #1; // 第一行倒数第2条，跨行
        print_batch(fetch_addr, inst_batch);

        fetch_addr = 15; #1; // 第一行最后一条，跨行
        print_batch(fetch_addr, inst_batch);

        $display("\n==== [3] fetch (insufficient 4 instructions) ====");
        fetch_addr = LINE_NUM*WORDS_PER_LINE - 3; #1; // 最后3条，只有1条越界
        print_batch(fetch_addr, inst_batch);

        fetch_addr = LINE_NUM*WORDS_PER_LINE - 1; #1; // 最后一条，剩下全NOP
        print_batch(fetch_addr, inst_batch);

        $display("\n==== testbench done ====");
        #10 $finish;
    end

    // 打印批量抓取结果的任务
    task print_batch(input [$clog2(LINE_NUM*WORDS_PER_LINE)-1:0] addr,
                     input [FETCH_WIDTH-1:0][WORD_WIDTH-1:0] batch);
        $display("fetch_addr = %0d:", addr);
        for (int i = 0; i < FETCH_WIDTH; i++)
            $display("inst_batch[%0d] = %h", i, batch[i]);
    endtask

endmodule
