module instr_decoder
import rv32i_types::*;
(
    input [31:0] instr,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output rv32i_opcode opcode,
    output [2:0] funct3,
    output [6:0] funct7,

    output logic [31:0] i_imm,
    output logic [31:0] s_imm,
    output logic [31:0] b_imm,
    output logic [31:0] u_imm,
    output logic [31:0] j_imm
);

assign funct3 = instr[14:12];
assign funct7 = instr[31:25];
assign opcode = rv32i_opcode'(instr[6:0]);
assign s_imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
assign i_imm = {{21{instr[31]}}, instr[30:20]};
assign b_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
assign u_imm = {instr[31:12], 12'h000};
assign j_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
assign rs1 = instr[19:15];
assign rs2 = instr[24:20];
assign rd = instr[11:7];

endmodule : instr_decoder