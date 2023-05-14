`ifndef PSEUDOLRU_DUT_TB
`define PSEUDOLRU_DUT_TB
`define idx_1 3

module pseudoLRU_dut_tb;

timeunit 1ns;
timeprecision 1ns;

import branch_predictor::plru;

bit clk;
bit rst;
always #5 clk = clk === 1'b0;
default clocking tb_clk @(negedge clk); endclocking

logic[`idx_1-1:0] access_index;
logic[`idx_1-1:0] out;
int actual_out;


initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, pseudoLRU_dut_tb, "+all");
    $display("Compilation Successful");
    rst = 1'b0;
    access_index = {`idx_1{1'b0}};
end

pseudoLRU #(`idx_1) dut(
    .clk(clk),
    .rst(rst),
    .load(1'b1),
    .in(access_index),
    .out(out)
);

initial begin
    reset();
    test_lru();
    $finish;
end

task test_lru();
    static plru plru_model = new(`idx_1);
    for(int i = 0 ; i < 1000 ; i++) begin
        actual_out = plru_model.out();
        assert(actual_out[`idx_1-1:0] == out) else begin
            $display("No.%d: mismatch in output, got %h, expect %h", i, out, actual_out[`idx_1-1:0]);
        end
        access_index = $random;
        plru_model.update({{(32-`idx_1){1'b0}},access_index});
        ##1;
    end

endtask

task reset();
    rst <= 1'b1;
    access_index <= {`idx_1{1'b0}};
    ##5;
    rst <= 1'b0;
    ##1;
endtask

endmodule

`endif
