module return_address_stack 
import rv32i_types::*;
#(parameter depth_idx = 1)
(
    input logic clk,
    input logic rst,
    input logic stall,
    input logic [31:0] pc,
    input logic [6:0] opcode,
    input logic [4:0] rd,
    input logic [4:0] rs1,
    output logic [31:0] ras_out,
    output logic isReturn
);

logic [31:0] stack [1 << depth_idx];
int TOS;
logic push, pop;
logic [31:0] out;

assign push = ((opcode == op_jalr) && (rd != rs1) && (rd == 5'b00001)) ? 1'b1 : 1'b0;
assign pop = ((opcode == op_jalr) && (rd != rs1) && (rs1 == 5'b00001)) ? 1'b1 : 1'b0;
assign ras_out = (TOS == 0) ? out : stack[TOS-1];
//assign isReturn = pop;
assign isReturn = 1'b0;
assign out = stack[0];

integer i;
always_ff @(posedge clk) begin
    if(rst) begin
        TOS <= 0;
        for(i = 0 ; i < (1 << depth_idx) ; i++) begin
            stack[i] <= 32'b0;
        end
    end
    else begin
        if(!stall) begin
            if(push) begin
                if(TOS < ((1<<depth_idx) - 1)) begin
                    stack[TOS] <= pc + 4;
                    TOS <= TOS + 1;
                end
            end
            else if(pop) begin
                if(TOS > 0) begin
                    TOS <= TOS - 1;
                end
                else begin
                    TOS <= 0;
                end
            end
        end
    end
end
endmodule
