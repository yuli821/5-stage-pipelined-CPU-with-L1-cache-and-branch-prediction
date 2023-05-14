module branch_target_buffer 
import rv32i_types::*;
#(parameter num_entry = 2, level = 1)
(
    input logic clk,
    input logic rst,
    input logic [31:0] ex_mem_pc,
    input logic [31:0] ex_mem_target,
    input rv32i_opcode ex_mem_op,
    input logic ex_mem_isMiss,
    input logic ex_mem_br_en,
    input logic [31:0] br_pc,
    output logic [31:0] predict_target,
    output logic isMiss
);

logic [31:0] tag [num_entry];
logic [31:0] target [num_entry];
logic load;

logic [level-1:0] access_index;
logic [level-1:0] evict_index;

pseudoLRU #(level) plru(.*, .load(1'b1), .in(access_index), .out(evict_index));

integer i;
always_comb begin
    isMiss = 1'b1;
    predict_target = br_pc + 4;
    access_index = {level{1'b0}};
    load = 1'b0;
    for (i = 0 ; i < num_entry; i++) begin
        if (tag[i] == br_pc) begin
            predict_target = target[i];
            isMiss = 1'b0;
            access_index = i[level-1:0];
            load = 1'b1;
        end
    end
end
integer j;
always_ff @(posedge clk) begin
    if(rst) begin
        for(j = 0 ; j < num_entry ; j++) begin
            tag[j] <= 32'b0;
            target[j] <= 32'b0;
        end
    end
    else begin
        if(ex_mem_isMiss & ex_mem_br_en & ((ex_mem_op == op_br) | (ex_mem_op == op_jal) | (ex_mem_op == op_jalr))) begin
            tag[evict_index] <= ex_mem_pc;
            target[evict_index] <= ex_mem_target;
        end
        else if (!ex_mem_isMiss & ((ex_mem_op == op_jal) | (ex_mem_op == op_jalr))) begin
            for (j = 0 ; j < num_entry; j++) begin
                if (tag[j] == ex_mem_pc) begin
                    target[j] <= ex_mem_target;
                end
            end
        end
    end
end

endmodule
