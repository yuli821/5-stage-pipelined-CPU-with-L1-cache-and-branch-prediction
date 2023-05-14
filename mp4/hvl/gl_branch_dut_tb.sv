`ifndef GLOBAL_BR_PREDICTOR
`define GLOBAL_BR_PREDICTOR
`define idx 9
`include "branch_dut_itf.sv"
module gl_branch_dut_tb;

timeunit 1ns;
timeprecision 1ns;

import branch_predictor::gl_branch;

bit clk;
always #5 clk = clk === 1'b0;
default clocking tb_clk @(negedge clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, gl_branch_dut_tb, "+all");
    $display("Compilation Successful");
end

branch_dut_itf b_itf(.*);

global_br_predictor #(`idx) dut(
    .clk(b_itf.clk),
    .rst(b_itf.rst),
    .stall(b_itf.stall),
    .pc(b_itf.pc),
    .opcode(b_itf.opcode),
    .ex_mem_br_en(b_itf.ex_mem_br_en),
    .ex_mem_pc(b_itf.ex_mem_pc),
    .ex_mem_opcode(b_itf.ex_mem_opcode),
    .gl_predict_dir(b_itf.predict_dir)
);

initial begin
    reset();
    random_gl_test();
    $finish;
end

function predict_gl (int pc);
    b_itf.pc = pc;
    b_itf.opcode = 7'b1100011;
    return b_itf.predict_dir;
endfunction

task update_gl (int ex_mem_pc, bit ex_mem_br_en);
    b_itf.ex_mem_pc <= ex_mem_pc;
    b_itf.ex_mem_br_en <= ex_mem_br_en;
    b_itf.ex_mem_opcode <= 7'b1100011;
    ##1;
endtask

task random_gl_test();
    static gl_branch gl_model = new(`idx);
    int pc, ex_mem_pc;
    bit ex_mem_br_en, predict_dir,actual_dir;
    bit [1:0] state;
    bit [6:0] opcode;
    $display("Starting the global predictor random test");

    for(int i = 0 ; i < 2000 ; i++) begin
        opcode <= 7'b1100011;
        pc <= $urandom;
        ex_mem_pc <= $urandom;
        ex_mem_br_en <= $random;
        update_gl(ex_mem_pc, ex_mem_br_en);
        gl_model.update_array(ex_mem_pc[`idx+1:2], ex_mem_br_en);
        state <= gl_model.get_pred_dir(pc[`idx+1:2], opcode);
        predict_dir = predict_gl(pc);
        actual_dir = (state > 2'b01) ? 1'b1 : 1'b0;
        assert(actual_dir == predict_dir)else begin
            $error("No.%d: Mismatch in random_test : got %h, expect %h, pc: %h, ex_mem_pc: %h, state: %h", i, predict_dir, actual_dir, pc, ex_mem_pc, state);
        end;
    end
endtask

task reset();
    b_itf.rst <= 1'b1;
    ##5;
    b_itf.rst <= 1'b0;
    ##1;
endtask

endmodule : gl_branch_dut_tb

`endif
