`ifndef RAS_DUT_TB
`define RAS_DUT_TB
`define index_2 3

module RAS_dut_tb;

timeunit 1ns;
timeprecision 1ns;

import branch_predictor::RAS;

bit clk;
bit rst;
always #5 clk = clk === 1'b0;
default clocking tb_clk @(negedge clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, RAS_dut_tb, "+all");
    $display("Compilation Successful");
    rst = 1'b0;
end
logic [6:0] opcode;
logic [4:0] rd, rs1, _rd, _rs1;
logic [31:0] out, dut_out, actual_out, pc, _pc;
logic ret, _ret, actual_ret;
assign opcode = 7'b1100111;

return_address_stack #(`index_2) dut(
    .clk(clk),
    .rst(rst),
    .stall(1'b0),
    .pc(pc),
    .opcode(opcode),
    .rd(rd),
    .rs1(rs1),
    .ras_out(dut_out),
    .isReturn(_ret)
);

initial begin
    reset();
    random_ras_test();
    $finish;
end

task push(logic [31:0] _pc, logic [4:0] _rd, logic [4:0] _rs1);
    pc <= _pc;
    rd <= _rd;
    rs1 <= _rs1;
endtask

task pop(logic [4:0] _rd, logic [4:0] _rs1);
    rd <= _rd;
    rs1 <= _rs1;
endtask

task random_ras_test();
    static RAS ras_model = new(`index_2);
    bit op;
    integer tos;
    for (int i = 0 ; i < 100 ; i++) begin
        _pc <= $urandom;
        op <= $urandom;
        _rd <= 5'b0;
        _rs1 <= 5'b0;
        if(op) begin  //push
            _rd = 5'b00001;
            _rs1 = $urandom;
            push(_pc, _rd, _rs1);
            ras_model.push(opcode, _rd, _rs1, _pc);
        end
        else begin   //pop
            _rd = $urandom;
            _rs1 = 5'b00001;
            pop(_rd, _rs1);
            out = dut_out;
            ret = _ret;
            actual_out = ras_model.pop(opcode, _rd, _rs1);
            actual_ret = ras_model.get_ret();
            tos = ras_model.get_TOS();
            if(ret) begin
                assert(out == actual_out) else begin
                    $display("TOS: %h", tos);
                    $display("No.%d: mismatch in popping return address, got %h, expect %h", i, out, actual_out);
                end
            end
        end
        ##1;
    end

endtask

task reset();
    rst <= 1'b1;
    ##5;
    rst <= 1'b0;
    ##1;
endtask


endmodule

`endif 
