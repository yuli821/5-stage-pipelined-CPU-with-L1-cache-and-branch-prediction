module control_rom
import rv32i_types::*;
(
    input rv32i_opcode opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output rv32i_control_word ctrl
);

always_comb
begin
    /* Default assignments */
    ctrl.opcode = opcode;
    ctrl.funct3 = funct3;
    ctrl.immmux_sel = immmux::u_imm;
    ctrl.load_regfile = 1'b0;
    ctrl.aluop = alu_ops'(funct3);
    ctrl.cmpop = cmp_ops'(funct3);
    //ctrl.pcmux_sel = pcmux::pc_plus4;
    ctrl.alumux1_sel = alumux::rs1_out;
    ctrl.alumux2_sel = alumux::rs2_out;
    ctrl.cmpmux_sel = cmpmux::rs2_out;
    ctrl.exdatamux_sel = exdatamux::alu_out;
    ctrl.regfilemux_sel = regfilemux::ex_data_out;
    ctrl.writedatamux_sel = writedatamux::word;
    ctrl.mem_read = 1'b0;
    ctrl.mem_write = 1'b0;

    /* Assign control signals based on opcode */
    case(opcode)
        op_auipc: begin
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.load_regfile = 1'b1;
            ctrl.immmux_sel = immmux::u_imm;
            ctrl.regfilemux_sel = regfilemux::ex_data_out;
            ctrl.exdatamux_sel = exdatamux::alu_out;
        end
        op_lui: begin
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::ex_data_out; 
            ctrl.immmux_sel = immmux::u_imm;
            ctrl.exdatamux_sel = exdatamux::u_imm;
        end
        op_br: begin
            ctrl.cmpop = cmp_ops'(funct3);
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.aluop = alu_add;
            ctrl.immmux_sel = immmux::b_imm;
            ctrl.cmpmux_sel = cmpmux::rs2_out;
        end
        op_load: begin
            ctrl.aluop = alu_add;
            ctrl.mem_read = 1'b1;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.exdatamux_sel = exdatamux::alu_out;
            ctrl.load_regfile = 1'b1;
            ctrl.immmux_sel = immmux::i_imm;
            unique case(funct3)
                lb:  ctrl.regfilemux_sel = regfilemux::lb;
                lh:  ctrl.regfilemux_sel = regfilemux::lh;
                lbu: ctrl.regfilemux_sel = regfilemux::lbu;
                lhu: ctrl.regfilemux_sel = regfilemux::lhu;
                lw:  ctrl.regfilemux_sel = regfilemux::lw;
                default: ctrl.regfilemux_sel = regfilemux::ex_data_out;
            endcase
        end
        op_store: begin
            ctrl.mem_write = 1'b1;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.aluop = alu_add;
            ctrl.exdatamux_sel = exdatamux::alu_out;
            ctrl.immmux_sel = immmux::s_imm;
            case(funct3)
                sb: ctrl.writedatamux_sel = writedatamux::byte_;
                sh: ctrl.writedatamux_sel = writedatamux::half;
                sw: ctrl.writedatamux_sel = writedatamux::word;
                default: ctrl.writedatamux_sel = writedatamux::byte_;
            endcase
        end
        op_imm: begin
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::ex_data_out;
            ctrl.immmux_sel = immmux::i_imm;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::imm;
            if(funct3 == slt) begin
                ctrl.cmpmux_sel = cmpmux::i_imm;
                ctrl.cmpop = lt;
                ctrl.exdatamux_sel = exdatamux::br_en;
            end
            else if (funct3 == sltu) begin
                ctrl.cmpmux_sel = cmpmux::i_imm;
                ctrl.cmpop = ltu;
                ctrl.exdatamux_sel = exdatamux::br_en;
            end
            else if (funct3 == sr) begin
                ctrl.exdatamux_sel = exdatamux::alu_out;
                if(funct7[5]) ctrl.aluop = alu_sra;
                else          ctrl.aluop = alu_srl;
            end
            else begin
                ctrl.exdatamux_sel = exdatamux::alu_out;
                ctrl.aluop = alu_ops'(funct3);
            end
        end
        op_reg: begin
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::ex_data_out;
            ctrl.alumux1_sel  = alumux::rs1_out;
            ctrl.alumux2_sel  = alumux::rs2_out;
            if(funct3 == slt)begin
                ctrl.cmpmux_sel = cmpmux::rs2_out;
                ctrl.cmpop = lt;
                ctrl.exdatamux_sel = exdatamux::br_en;
            end
            else if (funct3 == sltu)begin
                ctrl.cmpmux_sel = cmpmux::rs2_out;
                ctrl.cmpop = ltu;
                ctrl.exdatamux_sel = exdatamux::br_en;
            end
            else if (funct3 == sr)begin
                ctrl.exdatamux_sel = exdatamux::alu_out;
                if(funct7[5]) ctrl.aluop = alu_sra;
                else          ctrl.aluop = alu_srl;
            end
            else if (funct3 == add) begin
                ctrl.exdatamux_sel = exdatamux::alu_out;
                if(funct7[5]) ctrl.aluop = alu_sub;
                else          ctrl.aluop = alu_add;
            end
            else begin
                ctrl.exdatamux_sel = exdatamux::alu_out;
                ctrl.aluop = alu_ops'(funct3);
            end
        end
        op_jal: begin
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::ex_data_out;
            ctrl.exdatamux_sel = exdatamux::pc_plus4;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.aluop = alu_add;
            ctrl.immmux_sel = immmux::j_imm;
        end
        op_jalr: begin
            ctrl.load_regfile = 1'b1;
            ctrl.regfilemux_sel = regfilemux::ex_data_out;
            ctrl.exdatamux_sel = exdatamux::pc_plus4;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.aluop = alu_add;
            ctrl.immmux_sel = immmux::i_imm;
        end
        op_csr: begin
            ctrl.load_regfile = 1'b1;
            ctrl.aluop = alu_add;
            ctrl.mem_read = 1'b1;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::imm;
            ctrl.exdatamux_sel = exdatamux::alu_out;
            ctrl.immmux_sel = immmux::i_imm;
            ctrl.regfilemux_sel = regfilemux::lw;
        end

        default: begin
            ctrl = 0;   /* Unknown opcode, set control word to zero */
        end
    endcase
end
endmodule : control_rom