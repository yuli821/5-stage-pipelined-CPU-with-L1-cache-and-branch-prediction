module global_br_predictor
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
    input rv32i_opcode ex_mem_opcode,
    output logic gl_predict_dir
);

logic [idx_bits-1:0] global_pred_reg [1 << idx_bits];
logic [1:0] history_table [1 << idx_bits]; 
logic [1:0] actual_state, current_state, predict_state;

logic [idx_bits-1:0] index, ex_mem_index;
assign index = global_pred_reg[pc[idx_bits+1:2]] ^ pc[idx_bits+1:2];
assign ex_mem_index = global_pred_reg[ex_mem_pc[idx_bits+1:2]] ^ ex_mem_pc[idx_bits+1:2];

assign predict_state = ((opcode == op_jal) || (opcode == op_jalr)) ? strongly_taken : history_table[index];
assign gl_predict_dir = (predict_state > weakly_not_taken) ? 1'b1 : 1'b0;
assign current_state = history_table[ex_mem_index];

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

integer i;
always @(posedge clk) begin
    if(rst) begin
        for(i = 0 ; i < (1<<idx_bits) ; i++) begin
            global_pred_reg[i] <= {idx_bits{1'b0}};
            history_table[i] <= strongly_not_taken;
        end
    end
    else begin
        if (!stall & (ex_mem_opcode == op_br)) begin
            history_table[ex_mem_index] <= actual_state;
            global_pred_reg[ex_mem_pc[idx_bits+1:2]] <= {global_pred_reg[ex_mem_pc[idx_bits+1:2]][idx_bits-2:0], ex_mem_br_en};
        end
    end
end


endmodule
