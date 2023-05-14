package rv32i_types;
// Mux types are in their own packages to prevent identifier collisions
// e.g. pcmux::pc_plus4 and regfilemux::pc_plus4 are seperate identifiers
// for seperate enumerated types
import pcmux::*;
import cmpmux::*;
import alumux::*;
import regfilemux::*;
import immmux::*;
import exdatamux::*;
import writedatamux::*;
import forwardmux::*;

typedef logic [31:0] rv32i_word;
typedef logic [4:0] rv32i_reg;
typedef logic [3:0] rv32i_mem_wmask;

typedef enum bit [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011  //control and status register (I type)
} rv32i_opcode;

typedef enum bit [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;

typedef enum bit [2:0] {
    eq  = 3'b000,
    ne  = 3'b001,
    lt  = 3'b100,
    ge  = 3'b101,
    ltu = 3'b110,
    geu = 3'b111
} cmp_ops;

typedef enum bit [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
} store_funct3_t;

typedef enum bit [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef enum bit [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
} alu_ops;

typedef struct packed {
    rv32i_opcode opcode;
    alu_ops aluop;		
    cmp_ops cmpop;
    logic load_regfile; 
    logic mem_read;
    logic mem_write;
    logic [2:0] funct3;     
    exdatamux_sel_t exdatamux_sel; 
    regfilemux_sel_t regfilemux_sel; 
    immmux_sel_t immmux_sel;
    alumux1_sel_t alumux1_sel;    
    alumux2_sel_t alumux2_sel;    
    cmpmux_sel_t cmpmux_sel; 
    writedatamux_sel_t writedatamux_sel;
} rv32i_control_word;

typedef struct packed {
    logic [31:0] pc;
	logic [31:0] instr;
    logic ismiss;
    logic predict_direction;
    // logic predict_lc_dir;
    // logic predict_gl_dir;
} if_id_reg_t;

typedef struct packed {
    rv32i_control_word ctrl;
    logic [31:0] pc;
	logic [31:0] rs1_out;
	logic [31:0] rs2_out;
	logic [31:0] immediate;
	logic [4:0] rd;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic ismiss;
    logic predict_direction;
    // logic predict_lc_dir;
    // logic predict_gl_dir;

    //for rvfi monitor
    logic [31:0] instr;
} id_ex_reg_t;

typedef struct packed {
	rv32i_control_word ctrl;
    logic [31:0] pc;
	logic [31:0] ex_data_out;
    logic [31:0] alu_out;
    logic [31:0] rs2_out;
    logic br_en;
    logic [4:0] rd;
    logic ismiss;
    logic predict_direction;
    // logic predict_lc_dir;
    // logic predict_gl_dir;

    //for rvfi monitor
    logic [31:0] instr;
    logic [4:0] sr1;
    logic [4:0] sr2;
    logic [31:0] rs1_out;
} ex_mem_reg_t;

typedef struct packed{
	rv32i_control_word ctrl;
    logic [31:0] pc;
    logic [31:0] mem_rdata;
	logic [31:0] ex_data_out;
    logic [4:0] rd;

    //for rvfi monitor
    logic [31:0] instr;
    logic [4:0] sr1;
    logic [4:0] sr2;
    logic [31:0] rs1_out;
    logic [31:0] rs2_out;
    logic [3:0] d_mbe;
    logic [31:0] mem_wdata;
    logic br_en;
    logic [31:0] pc_val_b;
} mem_wb_reg_t;

typedef struct packed {
    logic pc;
    logic if_id;
    logic id_ex;
    logic ex_mem;
    logic mem_wb;
} pipeline_reg_load_t;

typedef struct packed {
    pipeline_reg_load_t load;
    pipeline_reg_load_t rst;
} pipeline_reg_ctrl_t;

typedef enum bit [1:0] {
    strongly_taken = 2'b11,
    weakly_taken = 2'b10,
    weakly_not_taken = 2'b01,
    strongly_not_taken = 2'b00
} br_pred;

typedef enum bit [1:0] {
    use_lc_predictor_1 = 2'b00,
    use_lc_predictor_2 = 2'b01,
    use_gl_predictor_1 = 2'b10,
    use_gl_predictor_2 = 2'b11
} tn_predictor;

endpackage : rv32i_types
