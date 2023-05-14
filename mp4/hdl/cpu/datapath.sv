module datapath
import rv32i_types::*;
(
    input clk,
    input rst,

    input 				instr_mem_resp,
    input rv32i_word 	instr_mem_rdata,
	input 				data_mem_resp,
    input rv32i_word 	data_mem_rdata, 
    output logic 		instr_read,
	output rv32i_word 	instr_mem_address,
    output logic 		data_read,
    output logic 		data_write,
    output logic [3:0] 	data_mbe,
    output rv32i_word 	data_mem_address,
    output rv32i_word 	data_mem_wdata
);

rv32i_opcode decoded_opcode;
logic [2:0] decoded_funct3;
logic [6:0] decoded_funct7;
logic load_pc;
pcmux::pcmux_sel_t pcmux_sel;
rv32i_word pcmux_out;
rv32i_word pc_out;
logic [4:0] rs1;
logic [4:0] rs2;
rv32i_word i_imm;
rv32i_word u_imm;
rv32i_word b_imm;
rv32i_word s_imm;
rv32i_word j_imm;
rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word rd_data_in;
rv32i_word cmp_mux_out;
rv32i_word alu_out;
logic br_en;

if_id_reg_t if_id_in;
if_id_reg_t if_id_out;
id_ex_reg_t id_ex_in;
id_ex_reg_t id_ex_out;
ex_mem_reg_t ex_mem_in;
ex_mem_reg_t ex_mem_out;
mem_wb_reg_t mem_wb_in;
mem_wb_reg_t mem_wb_out;
rv32i_control_word initial_ctrl;

logic pipeline_stall;
forwardmux::forwardmux_sel_t forwardmux1_sel, forwardmux2_sel;
rv32i_word rs1_out_forward, rs2_out_forward;
pipeline_reg_ctrl_t hazard_reg_ctrl, pipeline_reg_ctrl;

logic ex_mem_bren;
logic predict_lc_br_direction;
logic predict_gl_br_direction;
logic predict_tn_br_direction;
logic isMiss; //ret_sig;
logic [31:0] predict_target;
//logic [31:0] ras_out;
logic [31:0] BTB_out;
logic branch_rst;
int misprediction, total;


if_id_reg if_id_reg (
    .clk  (clk),
    .rst (pipeline_reg_ctrl.rst.if_id),
    .load (pipeline_reg_ctrl.load.if_id),
    .in   (if_id_in),
    .out  (if_id_out)
);

id_ex_reg id_ex_reg (
    .clk  (clk),
    .rst (pipeline_reg_ctrl.rst.id_ex),
    .load (pipeline_reg_ctrl.load.id_ex), 
    .in   (id_ex_in),
    .out  (id_ex_out)
);

ex_mem_reg ex_mem_reg (
    .clk  (clk),
    .rst (pipeline_reg_ctrl.rst.ex_mem),
    .load (pipeline_reg_ctrl.load.ex_mem), 
    .in   (ex_mem_in),
    .out  (ex_mem_out)
);

mem_wb_reg mem_wb_reg (
    .clk  (clk),
    .rst (pipeline_reg_ctrl.rst.mem_wb),
    .load (pipeline_reg_ctrl.load.mem_wb), 
    .in   (mem_wb_in),
    .out  (mem_wb_out)
);

logic [31:0] counter;
csr csr(
    .*,
    .val(counter)
);

always_ff @(posedge clk) begin : CYCLE
    if (mem_wb_out.ctrl.opcode == op_csr)  $display("Current cycle: 0x%x", counter);
end

/*****************************************************************************/
// IF Stage
/*****************************************************************************/

pc_register PC (
    .clk  (clk),
    .rst (pipeline_reg_ctrl.rst.pc),
    .load (pipeline_reg_ctrl.load.pc),
    .in   (pcmux_out),
    .out  (pc_out)
);

local_br_predictor #(5) lbr (
    .*,
    .stall(pipeline_stall),
    .pc(pc_out),
    .opcode(instr_mem_rdata[6:0]),
    .ex_mem_br_en(ex_mem_bren),
    .ex_mem_pc(ex_mem_out.pc),
    .ex_mem_opcode(ex_mem_out.ctrl.opcode),
    .predict_dir(predict_lc_br_direction)
);

// global_br_predictor #(5) gbr (
//     .*,
//     .stall(pipeline_stall),
//     .pc(pc_out),
//     .opcode(instr_mem_rdata[6:0]),
//     .ex_mem_br_en(ex_mem_bren),
//     .ex_mem_pc(ex_mem_out.pc),
//     .ex_mem_opcode(ex_mem_out.ctrl.opcode),
//     .gl_predict_dir(predict_gl_br_direction)
// );

branch_target_buffer #(8,3) BTB(
    .*,
    .ex_mem_pc(ex_mem_out.pc),
    .ex_mem_target(ex_mem_out.alu_out),
    .ex_mem_op(ex_mem_out.ctrl.opcode),
    .ex_mem_isMiss(ex_mem_out.ismiss),
    .ex_mem_br_en(ex_mem_bren),
    .br_pc(pc_out),
    .predict_target(BTB_out),
    .isMiss(isMiss)
);

// tournament_predictor TP(
//     .*,
//     .stall(pipeline_stall),
//     .lc_br_dir(predict_lc_br_direction),
//     .gl_br_dir(predict_gl_br_direction),
//     .ex_mem_lc_dir(ex_mem_out.predict_lc_dir),
//     .ex_mem_gl_dir(ex_mem_out.predict_gl_dir),
//     .ex_mem_br_en(ex_mem_bren),
//     .ex_mem_opcode(ex_mem_out.ctrl.opcode),
//     .tn_br_dir(predict_tn_br_direction)
// );

// return_address_stack #(3) RAS(
//     .*,
//     .pc(pc_out),
//     .opcode(instr_mem_rdata[6:0]),
//     .stall(pipeline_stall),
//     .rd(instr_mem_rdata[11:7]),
//     .rs1(instr_mem_rdata[19:15]),
//     .ras_out(ras_out),
//     .isReturn(ret_sig)
// );
//assign predict_target = (ret_sig) ? ras_out : BTB_out; //modify to turn off the RAS
assign predict_target = BTB_out;
assign instr_mem_address = pc_out;
assign instr_read = 1'b1; // Maybe change after CP1

always_comb begin : IF_MUXES

    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = ex_mem_out.pc + 4;
        pcmux::alu_out: pcmux_out = ex_mem_out.alu_out;
        pcmux::aluout_mod2: pcmux_out = {ex_mem_out.alu_out[31:1], 1'b0};
        pcmux::predict_pc: pcmux_out = predict_lc_br_direction ? predict_target : pc_out + 4;//update when switching predictor
        default: pcmux_out = predict_target;
    endcase
end


assign if_id_in.pc = pc_out;
assign if_id_in.instr = instr_mem_rdata;
assign if_id_in.ismiss = isMiss;
assign if_id_in.predict_direction = predict_lc_br_direction;//update when switching predictor
// assign if_id_in.predict_lc_dir = predict_lc_br_direction;
// assign if_id_in.predict_gl_dir = predict_gl_br_direction;


/*****************************************************************************/
// ID Stage
/*****************************************************************************/

instr_decoder instr_decoder (
    .instr (if_id_out.instr),
    .rs1 (rs1),
    .rs2 (rs2),
    .rd (id_ex_in.rd),
    .opcode (decoded_opcode),
    .funct3 (decoded_funct3),
    .funct7 (decoded_funct7),
    .i_imm(i_imm),
    .s_imm(s_imm),
    .b_imm(b_imm),
    .u_imm(u_imm),
    .j_imm(j_imm)
);

regfile regfile (
    .clk (clk),
    .rst (rst),
    .load (mem_wb_out.ctrl.load_regfile),
    .in (rd_data_in),
    .src_a (rs1),
    .src_b (rs2),
    .dest (mem_wb_out.rd),
    .reg_a(id_ex_in.rs1_out),
    .reg_b(id_ex_in.rs2_out)
);

control_rom control_rom (
    .opcode (decoded_opcode),
    .funct3 (decoded_funct3),
    .funct7 (decoded_funct7),
    .ctrl (initial_ctrl)
);

always_comb begin

    unique case (initial_ctrl.immmux_sel)
        immmux::i_imm: id_ex_in.immediate = i_imm;
        immmux::s_imm: id_ex_in.immediate = s_imm;
        immmux::b_imm: id_ex_in.immediate = b_imm;
        immmux::u_imm: id_ex_in.immediate = u_imm;
        immmux::j_imm: id_ex_in.immediate = j_imm;
        default: id_ex_in.immediate = i_imm;
    endcase

end

assign id_ex_in.ctrl = initial_ctrl;
assign id_ex_in.pc = if_id_out.pc;
assign id_ex_in.rs1 = rs1;
assign id_ex_in.rs2 = rs2;
assign id_ex_in.ismiss = if_id_out.ismiss;
assign id_ex_in.predict_direction = if_id_out.predict_direction;
// assign id_ex_in.predict_lc_dir = if_id_out.predict_lc_dir;
// assign id_ex_in.predict_gl_dir = if_id_out.predict_gl_dir;


// Hazard Detection
assign pipeline_stall = !instr_mem_resp || (!data_mem_resp && (ex_mem_out.ctrl.mem_write || ex_mem_out.ctrl.mem_read));

hazard_detection hazard_detection(
    //.mem_opcode(ex_mem_out.ctrl.opcode),
    .ex_opcode(id_ex_out.ctrl.opcode),
    .id_opcode(initial_ctrl.opcode),
    .ex_rd(id_ex_out.rd),
    .id_sr1(rs1),
    .id_sr2(rs2),
    .branch_rst(branch_rst),
    //.mem_br_en(ex_mem_out.br_en),
    .out(hazard_reg_ctrl)
);

always_comb begin
    pipeline_reg_ctrl.load = {5{~pipeline_stall}} & hazard_reg_ctrl.load; // Bitwise OR
    pipeline_reg_ctrl.rst = ({5{~pipeline_stall}} & hazard_reg_ctrl.rst) | {5{rst}};
end
assign id_ex_in.instr = if_id_out.instr; //for rvfi monitor

/*****************************************************************************/
// EX Stage
/*****************************************************************************/

alu ALU (
    .aluop (id_ex_out.ctrl.aluop),
    .a (alumux1_out),
    .b (alumux2_out),
    .f (alu_out)
);

cmp CMP (
    .cmpop (id_ex_out.ctrl.cmpop),
    .a (rs1_out_forward),
    .b (cmp_mux_out),
    .f (br_en)
);

forwarding forwarding_unit (
    .ex_rs1(id_ex_out.rs1),
    .ex_rs2(id_ex_out.rs2),
    .mem_rd(ex_mem_out.rd),
    .mem_load_regfile(ex_mem_out.ctrl.load_regfile),
    .wb_rd(mem_wb_out.rd),
    .wb_load_regfile(mem_wb_out.ctrl.load_regfile),
    .forward1(forwardmux1_sel),
    .forward2(forwardmux2_sel)
);

always_comb begin : FORWARD1
    case (forwardmux1_sel)
        forwardmux::rs_out: rs1_out_forward = id_ex_out.rs1_out;
        forwardmux::ex_mem_out: rs1_out_forward = ex_mem_out.ex_data_out;
        forwardmux::mem_wb_out: rs1_out_forward = rd_data_in; // From mem_wb
        default: rs1_out_forward = id_ex_out.rs1_out;
    endcase
end

always_comb begin : FORWARD2
    case (forwardmux2_sel)
        forwardmux::rs_out: rs2_out_forward = id_ex_out.rs2_out;
        forwardmux::ex_mem_out: rs2_out_forward = ex_mem_out.ex_data_out;
        forwardmux::mem_wb_out: rs2_out_forward = rd_data_in;
        default: rs2_out_forward = id_ex_out.rs2_out;
    endcase
end

always_comb begin
    unique case (id_ex_out.ctrl.alumux1_sel)
        alumux::rs1_out: alumux1_out = rs1_out_forward;
        alumux::pc_out: alumux1_out = id_ex_out.pc;
    endcase
end

always_comb begin
    unique case (id_ex_out.ctrl.alumux2_sel)
        alumux::rs2_out: alumux2_out = rs2_out_forward;
        alumux::imm: alumux2_out = id_ex_out.immediate;
    endcase
end

always_comb begin
    unique case (id_ex_out.ctrl.cmpmux_sel)
        cmpmux::rs2_out: cmp_mux_out = rs2_out_forward;
        cmpmux::i_imm: cmp_mux_out = id_ex_out.immediate;
    endcase
end

always_comb begin
    unique case (id_ex_out.ctrl.exdatamux_sel)
        exdatamux::alu_out: ex_mem_in.ex_data_out = alu_out;
        exdatamux::br_en: ex_mem_in.ex_data_out = rv32i_word'(br_en); // Zero-extended
        exdatamux::u_imm: ex_mem_in.ex_data_out = id_ex_out.immediate;
        exdatamux::pc_plus4: ex_mem_in.ex_data_out = id_ex_out.pc + 4;
    endcase
end

assign ex_mem_in.ctrl = id_ex_out.ctrl;
assign ex_mem_in.pc = id_ex_out.pc;
assign ex_mem_in.rd = id_ex_out.rd;
assign ex_mem_in.rs2_out = rs2_out_forward;
assign ex_mem_in.alu_out = alu_out;
assign ex_mem_in.br_en = br_en;
assign ex_mem_in.instr = id_ex_out.instr;//for rvfi monitor
assign ex_mem_in.sr1 = id_ex_out.rs1;
assign ex_mem_in.sr2 = id_ex_out.rs2;
assign ex_mem_in.rs1_out = rs1_out_forward;
assign ex_mem_in.ismiss = id_ex_out.ismiss;
assign ex_mem_in.predict_direction = id_ex_out.predict_direction;
// assign ex_mem_in.predict_lc_dir = id_ex_out.predict_lc_dir;
// assign ex_mem_in.predict_gl_dir = id_ex_out.predict_gl_dir;


/*****************************************************************************/
// MEM Stage
/*****************************************************************************/

assign data_mem_address = {ex_mem_out.ex_data_out[31:2], 2'b0};
assign data_read = ex_mem_out.ctrl.mem_read;
assign data_write = ex_mem_out.ctrl.mem_write;


always_comb begin : WRITE_DATA_MUX

    unique case (ex_mem_out.ctrl.writedatamux_sel)
        writedatamux::byte_: data_mem_wdata = {ex_mem_out.rs2_out[7:0], ex_mem_out.rs2_out[7:0], ex_mem_out.rs2_out[7:0], ex_mem_out.rs2_out[7:0]};
        writedatamux::half: data_mem_wdata = {ex_mem_out.rs2_out[15:0], ex_mem_out.rs2_out[15:0]};
        writedatamux::word: data_mem_wdata = ex_mem_out.rs2_out;
        default: data_mem_wdata = ex_mem_out.rs2_out;
    endcase
end

always_comb begin : MEM_BYTE_EN_MUX

    case (ex_mem_out.ctrl.funct3)
        3'b000: data_mbe = (4'b0001 << ex_mem_out.ex_data_out[1:0]);
        3'b001: data_mbe = (4'b0011 << ex_mem_out.ex_data_out[1:0]);
        3'b010: data_mbe = 4'b1111;
        default: data_mbe = 4'b1111;
    endcase

end

always_comb begin
    if ((((ex_mem_out.ctrl.opcode == op_br) & ex_mem_out.br_en)) | 
    ((ex_mem_out.ctrl.opcode == op_jal))) begin
        ex_mem_bren = 1'b1;
    end
    else if ((ex_mem_out.ctrl.opcode == op_jalr)) begin
        ex_mem_bren = 1'b1;
    end
    else begin
        ex_mem_bren = 1'b0;
    end
end

always_comb begin : PCMUX_SEL
    if(ex_mem_out.ismiss & ex_mem_bren) begin
        branch_rst = 1'b1;
        pcmux_sel = pcmux::alu_out;
    end
    else if (!ex_mem_out.ismiss & !ex_mem_bren & ex_mem_out.predict_direction) begin
        branch_rst = 1'b1;
        pcmux_sel = pcmux::pc_plus4;
    end
    else if (!ex_mem_out.ismiss & !ex_mem_out.predict_direction & ex_mem_bren) begin
        branch_rst = 1'b1;
        pcmux_sel = pcmux::alu_out;
    end
    else if (((ex_mem_out.ctrl.opcode == op_jalr) || (ex_mem_out.ctrl.opcode == op_jal )) & (id_ex_out.pc != ex_mem_out.alu_out)) begin
        branch_rst = 1'b1;
        pcmux_sel = pcmux::alu_out;
    end
    else begin
        branch_rst = 1'b0;
        pcmux_sel = pcmux::predict_pc;
    end
end

always_ff @(posedge clk) begin
    if(rst) begin
        total <= 0;
        misprediction <= 0;
    end
    else begin
        if(((ex_mem_out.ctrl.opcode == op_br) || (ex_mem_out.ctrl.opcode == op_jal) || (ex_mem_out.ctrl.opcode == op_jalr)) && (ex_mem_bren != ex_mem_out.predict_direction) && !pipeline_stall) begin
            misprediction <= misprediction + 1;
        end
        if(((ex_mem_out.ctrl.opcode == op_br) || (ex_mem_out.ctrl.opcode == op_jal) || (ex_mem_out.ctrl.opcode == op_jalr)) && !pipeline_stall) begin
            total <= total + 1;
        end
    end
end

assign mem_wb_in.ctrl = ex_mem_out.ctrl;
assign mem_wb_in.pc = ex_mem_out.pc;
assign mem_wb_in.rd = ex_mem_out.rd;
assign mem_wb_in.ex_data_out = ex_mem_out.ex_data_out;
assign mem_wb_in.mem_rdata = data_mem_rdata;
assign mem_wb_in.instr = ex_mem_out.instr;  //for rvfi monitor
assign mem_wb_in.sr1 = ex_mem_out.sr1;
assign mem_wb_in.sr2 = ex_mem_out.sr2;
assign mem_wb_in.rs1_out = ex_mem_out.rs1_out;
assign mem_wb_in.rs2_out = ex_mem_out.rs2_out;
assign mem_wb_in.d_mbe = data_mbe;
assign mem_wb_in.mem_wdata = data_mem_wdata;
assign mem_wb_in.br_en = ex_mem_out.br_en;
assign mem_wb_in.pc_val_b = ex_mem_out.alu_out;

/*****************************************************************************/
// WB Stage
/*****************************************************************************/

rd_data_decoder rd_data_decoder(
    .read_data(mem_wb_out.mem_rdata),
    .addr(mem_wb_out.ex_data_out[1:0]),
    .ex_data_out(mem_wb_out.ex_data_out),
    .regfilemux_sel(mem_wb_out.ctrl.regfilemux_sel),
    .rd_data_in(rd_data_in)
);

endmodule: datapath
