module hazard_detection
import rv32i_types::*;
(
    input rv32i_opcode ex_opcode, id_opcode,
    input [4:0] ex_rd, id_sr1, id_sr2,
    //input logic mem_br_en,
    input logic branch_rst,
    output pipeline_reg_ctrl_t out
);

logic sr1_used, sr2_used;

always_comb begin
    // Default
    out.load = ~0;
    out.rst = 0;

    /* Control hazard */
    if (branch_rst)
    begin
        out.rst.if_id = 1'b1;
        out.rst.id_ex = 1'b1;
        out.rst.ex_mem = 1'b1;
    end
    else begin
        /* Data hazard*/
        // Check if ID instruction uses SR1 and/or SR2
        sr1_used = (id_opcode != op_auipc) && (id_opcode != op_lui) && (id_opcode != op_jal);
        sr2_used = (id_opcode != op_load) && (id_opcode != op_imm) && sr1_used;

        if ((ex_opcode == op_load)
        & (ex_rd != 0)
        & ( ( (ex_rd == id_sr1) & (sr1_used) )
            | ( (ex_rd == id_sr2 & (sr2_used) ))))
        begin
            out.load.pc = 1'b0;
            out.load.if_id = 1'b0;
            out.rst.id_ex = 1'b1;
        end 
    end

end

endmodule
