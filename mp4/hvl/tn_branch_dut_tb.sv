`ifndef TOURNAMENT_BR_PREDICTOR
`define TOURNAMENT_BR_PREDICTOR
`include "branch_dut_itf.sv"
module tn_branch_dut_tb;

timeunit 1ns;
timeprecision 1ns;

import branch_predictor::tn_branch;

bit clk;
always #5 clk = clk === 1'b0;
default clocking tb_clk @(negedge clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, tn_branch_dut_tb, "+all");
    $display("Compilation Successful");
end

branch_dut_itf b_itf(.*);

tournament_predictor dut(
    .clk(b_itf.clk),
    .rst(b_itf.rst),
    .stall(b_itf.stall),
    .lc_br_dir(b_itf.lc_br_dir),
    .gl_br_dir(b_itf.gl_br_dir),
    .ex_mem_lc_dir(b_itf.ex_mem_lc_dir),
    .ex_mem_gl_dir(b_itf.ex_mem_gl_dir),
    .ex_mem_br_en(b_itf.ex_mem_br_en),
    .ex_mem_opcode(b_itf.ex_mem_opcode),
    .tn_br_dir(b_itf.tn_br_dir)
);

initial begin
    reset();
    random_tn_test();
    $finish;
end

task update(bit ex_mem_lc_dir, bit ex_mem_gl_dir, bit ex_mem_br_en, bit [6:0] ex_mem_opcode);
    b_itf.ex_mem_lc_dir <= ex_mem_lc_dir;
    b_itf.ex_mem_gl_dir <= ex_mem_gl_dir;
    b_itf.ex_mem_br_en <= ex_mem_br_en;
    b_itf.ex_mem_opcode <= ex_mem_opcode;
    ##1;
endtask

function bit predict(bit lc_dir, bit gl_dir);
    b_itf.lc_br_dir <= lc_dir;
    b_itf.gl_br_dir <= gl_dir;
    return b_itf.tn_br_dir;
endfunction

integer seed = 1;
task random_tn_test();
    static tn_branch tn_model = new();
    bit lc_dir, gl_dir, ex_mem_lc_dir, ex_mem_gl_dir, ex_mem_br_en, actual_dir, predict_dir;
    static bit [6:0] ex_mem_opcode = 7'b1100011;
    $display("Starting tournament predictor random test");
    for(int i = 0 ; i < 2000 ; i++) begin
        lc_dir <= $random(seed);
        gl_dir <= $random(seed);
        ex_mem_lc_dir <= $random(seed);
        ex_mem_gl_dir <= $random(seed);
        ex_mem_br_en <= $random(seed);
        update(ex_mem_lc_dir, ex_mem_gl_dir, ex_mem_br_en, ex_mem_opcode);
        tn_model.update_state(ex_mem_lc_dir, ex_mem_gl_dir, ex_mem_br_en);
        predict_dir = predict(lc_dir, gl_dir);
        actual_dir <= tn_model.get_dir(lc_dir, gl_dir);
        assert(predict_dir == actual_dir)else begin
            $error("No.%d: Mismatch in random_test : got %h, expect %h, lc_dir: %h, gl_dir: %h", i, predict_dir, actual_dir, lc_dir, gl_dir);
        end
    end
endtask

task reset();
    b_itf.rst <= 1'b1;
    ##5;
    b_itf.rst <= 1'b0;
    ##1;
endtask

endmodule
`endif
