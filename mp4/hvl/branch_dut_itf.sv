
`ifndef BRANCH_DUT_ITF_SV
`define BRANCH_DUT_ITF_SV
interface branch_dut_itf
(
    input bit clk
);

    logic rst;
    logic stall = 1'b0;
    logic [31:0] pc;
    logic [6:0] opcode;
    logic ex_mem_br_en;
    logic [31:0] ex_mem_pc;
    logic [6:0] ex_mem_opcode;
    logic predict_dir;

    logic lc_br_dir;
    logic gl_br_dir;
    logic ex_mem_lc_dir;
    logic ex_mem_gl_dir;
    logic tn_br_dir;

endinterface
`endif
