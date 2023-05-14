module local_br_predictor
import rv32i_types::*;
#(parameter idx_bits = 1)
(
    input logic clk,
    input logic rst,
    input logic stall,
    input logic [31:0] pc,
    input logic [6:0] opcode,
    input logic ex_mem_br_en,
    input logic [31:0] ex_mem_pc,
    input [6:0] ex_mem_opcode,
    output logic predict_dir
);

logic [1:0] history_table [1 << idx_bits];    //local branch prediction table, 512 entries
logic [1:0] predict_state, actual_state, current_state;
integer i;
assign predict_state = ((opcode == op_jal) || (opcode == op_jalr)) ? strongly_taken : history_table[pc[idx_bits+1:2]];
assign predict_dir = (predict_state > weakly_not_taken) ? 1'b1 : 1'b0;
assign current_state = history_table[ex_mem_pc[idx_bits+1:2]];

always_comb begin
    actual_state = current_state;
    case(current_state)
        strongly_not_taken: begin
            if(ex_mem_br_en)  actual_state = weakly_not_taken;
        end
        strongly_taken: begin
            if(!ex_mem_br_en) actual_state = weakly_taken;
        end
        weakly_not_taken: begin
            if(ex_mem_br_en)  actual_state = weakly_taken;
            else           actual_state = strongly_not_taken;
        end
        weakly_taken: begin
            if(ex_mem_br_en)  actual_state = strongly_taken;
            else           actual_state = weakly_not_taken;
        end
    endcase
end

always_ff @(posedge clk) begin
    if(rst) begin
        for (i = 0 ; i < (1<<idx_bits) ; i++) begin
            history_table[i] <= strongly_not_taken;
        end
    end
    else begin
        if (!stall & (ex_mem_opcode == op_br)) begin
            history_table[ex_mem_pc[idx_bits+1:2]] <= actual_state;
        end
    end
end

endmodule
