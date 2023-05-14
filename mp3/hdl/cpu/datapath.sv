module datapath
import rv32i_types::*;
(
    input clk,
    input rst,
    input load_mdr,load_ir,load_mar,load_pc,load_regfile,load_data_out,
    input pcmux::pcmux_sel_t pcmux_sel,
    input alumux::alumux1_sel_t alumux1_sel,
    input alumux::alumux2_sel_t alumux2_sel,
    input regfilemux::regfilemux_sel_t regfilemux_sel,
    input marmux::marmux_sel_t marmux_sel,
    input cmpmux::cmpmux_sel_t cmpmux_sel,
    input alu_ops aluop,
    input branch_funct3_t cmpop,
    input rv32i_word mem_rdata,
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
    /* You will need to connect more signals to your datapath module*/
    output logic br_en,
    output rv32i_opcode opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output rv32i_word mem_address,
    output [1:0] select
);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out;
rv32i_word mdrreg_out;
/*****************************************************************************/
logic [31:0] ir_in,pc_out,mar_in,regfilemux_out,rs1_out,rs2_out,alu_in1,alu_in2,alu_out,cmpmux_out;
logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;
logic [31:0] temp_addr,write_data;
logic [4:0] reg_s1, reg_s2, rd;
assign rs1 = reg_s1;
assign rs2 = reg_s2;
assign ir_in = mdrreg_out;
assign mem_address = {temp_addr[31:2],2'b0};
assign select = temp_addr[1:0];
assign mem_wdata = write_data << (8*select);

/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
    .*,
    .clk (clk),
    .rst (rst),
    .load (load_ir),
    .in (ir_in),
    .rs1 (reg_s1),
    .rs2 (reg_s2),
    .rd(rd)
);

register MDR(
    .clk  (clk),
    .rst (rst),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);

register MAR(
    .*,
    .load (load_mar),
    .in (mar_in),
    .out (temp_addr)
);

register MEM_DATA_OUT(
    .*,
    .load (load_data_out),
    .in (rs2_out),
    .out (write_data)
);

pc_register PC(
    .*,
    .load (load_pc),
    .in (pcmux_out),
    .out (pc_out)
);

regfile regfile(
    .*,
    .load (load_regfile),
    .in (regfilemux_out),
    .src_a (reg_s1),
    .src_b (reg_s2),
    .dest (rd),
    .reg_a (rs1_out),
    .reg_b (rs2_out)
);

/*****************************************************************************/

/******************************* ALU and CMP *********************************/

alu ALU(
    .aluop (aluop),
    .a (alu_in1),
    .b (alu_in2),
    .f (alu_out)
);

always_comb begin : CMP
    unique case (cmpop)
        beq: br_en = (rs1_out == cmpmux_out) ? 1'b1 : 1'b0;
        bne: br_en = (rs1_out != cmpmux_out) ? 1'b1 : 1'b0;
        blt: br_en = ($signed(rs1_out) < $signed(cmpmux_out)) ? 1'b1 : 1'b0;
        bge: br_en = ($signed(rs1_out) >= $signed(cmpmux_out)) ? 1'b1 : 1'b0;
        bltu: br_en = (rs1_out < cmpmux_out) ? 1'b1 : 1'b0;
        bgeu: br_en = (rs1_out >= cmpmux_out) ? 1'b1 : 1'b0;
        default :br_en = 1'b0;
    endcase
end
    
/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog. 
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out: pcmux_out = alu_out;
        pcmux::alu_mod2: pcmux_out = {alu_out[31:1],1'b0};
        default :pcmux_out = pc_out+4;
        // etc.
    endcase
    unique case (alumux1_sel)
        alumux::rs1_out: alu_in1 = rs1_out;
        alumux::pc_out: alu_in1 = pc_out;
    endcase
    unique case (alumux2_sel)
        alumux::i_imm: alu_in2 = i_imm;
        alumux::u_imm: alu_in2 = u_imm;
        alumux::b_imm: alu_in2 = b_imm;
        alumux::s_imm: alu_in2 = s_imm;
        alumux::j_imm: alu_in2 = j_imm;
        alumux::rs2_out: alu_in2 = rs2_out;
        default: alu_in2 = i_imm;
    endcase
    unique case (regfilemux_sel)
        default: regfilemux_out = alu_out;
        regfilemux::alu_out: regfilemux_out = alu_out;
        regfilemux::br_en: regfilemux_out = {{31{1'b0}},br_en};
        regfilemux::u_imm: regfilemux_out = u_imm;
        regfilemux::lw: regfilemux_out = mdrreg_out;
        regfilemux::pc_plus4: regfilemux_out = pc_out + 4;
        regfilemux::lb: begin
            unique case(select)
                2'b00:  regfilemux_out = {{24{mdrreg_out[7]}},mdrreg_out[7:0]};
                2'b01:  regfilemux_out = {{24{mdrreg_out[15]}},mdrreg_out[15:8]};
                2'b10:  regfilemux_out = {{24{mdrreg_out[23]}},mdrreg_out[23:16]};
                2'b11:  regfilemux_out = {{24{mdrreg_out[31]}},mdrreg_out[31:24]};
            endcase
        end
        regfilemux::lbu: begin
            unique case(select)
                2'b00:  regfilemux_out = {24'd0,mdrreg_out[7:0]};
                2'b01:  regfilemux_out = {24'd0,mdrreg_out[15:8]};
                2'b10:  regfilemux_out = {24'd0,mdrreg_out[23:16]};
                2'b11:  regfilemux_out = {24'd0,mdrreg_out[31:24]};
            endcase
        end
        regfilemux::lh: begin
            unique case(select)
                2'b00:  regfilemux_out = {{16{mdrreg_out[15]}},mdrreg_out[15:0]};
                2'b01:  regfilemux_out = {{16{mdrreg_out[15]}},mdrreg_out[15:0]};
                2'b10:  regfilemux_out = {{16{mdrreg_out[31]}},mdrreg_out[31:16]};
                2'b11:  regfilemux_out = 32'd0;
            endcase
        end
        regfilemux::lhu: begin
            unique case(select)
                2'b00:  regfilemux_out = {16'd0,mdrreg_out[15:0]};
                2'b01:  regfilemux_out = {16'd0,mdrreg_out[15:0]};
                2'b10:  regfilemux_out = {16'd0,mdrreg_out[31:16]};
                2'b11:  regfilemux_out = 32'd0;
            endcase
        end
    endcase
    unique case (marmux_sel)
        marmux::pc_out: mar_in = pc_out;
        marmux::alu_out: mar_in = alu_out;
    endcase
    unique case (cmpmux_sel)
        cmpmux::rs2_out: cmpmux_out = rs2_out;
        cmpmux::i_imm: cmpmux_out = i_imm;
    endcase
end
/*****************************************************************************/
endmodule : datapath
