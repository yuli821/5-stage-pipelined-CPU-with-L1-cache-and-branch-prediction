package pcmux;
typedef enum bit [1:0] {
    pc_plus4  = 2'b00,
    alu_out  = 2'b01,
    aluout_mod2 = 2'b10,
    predict_pc = 2'b11
} pcmux_sel_t;
endpackage

package cmpmux;
typedef enum bit {
    rs2_out = 1'b0,
    i_imm = 1'b1
} cmpmux_sel_t;
endpackage

package alumux;
typedef enum bit {
    rs1_out = 1'b0,
    pc_out = 1'b1
} alumux1_sel_t;

typedef enum bit {
    rs2_out = 1'b0,
    imm = 1'b1
} alumux2_sel_t;
endpackage

package regfilemux;
typedef enum bit [2:0] {
    lb           = 3'b000
    ,lh          = 3'b001
    ,lw          = 3'b010  
    ,lbu         = 3'b011
    ,lhu         = 3'b100  
    ,ex_data_out = 3'b101
} regfilemux_sel_t;
endpackage

package immmux;
typedef enum bit [2:0] {
    i_imm = 3'b000,
    u_imm = 3'b001,
    b_imm = 3'b010,
    s_imm = 3'b011,
    j_imm = 3'b100
} immmux_sel_t;
endpackage

package exdatamux;
typedef enum bit[1:0] {
    alu_out  = 2'b00,
    br_en    = 2'b01,
    u_imm    = 2'b10,
    pc_plus4 = 2'b11
} exdatamux_sel_t;
endpackage

package writedatamux;
typedef enum bit[1:0] {
    byte_ = 2'b00,
    half = 2'b01,
    word = 2'b10
} writedatamux_sel_t;
endpackage

package forwardmux;
typedef enum bit [1:0] {
    rs_out  = 2'b00,
    ex_mem_out  = 2'b01,
    mem_wb_out  = 2'b10
} forwardmux_sel_t;
endpackage
