module tournament_predictor 
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input logic stall,
    input logic lc_br_dir,
    input logic gl_br_dir,
    input logic ex_mem_lc_dir,
    input logic ex_mem_gl_dir,
    input logic ex_mem_br_en,
    input [6:0] ex_mem_opcode,
    output logic tn_br_dir
);

logic [1:0] current_state, next_state;
logic lc_correct, gl_correct;
assign lc_correct = !(ex_mem_lc_dir ^ ex_mem_br_en);
assign gl_correct = !(ex_mem_gl_dir ^ ex_mem_br_en);

always_comb begin
    case(current_state)
        use_lc_predictor_1: tn_br_dir = lc_br_dir;
        use_lc_predictor_2: tn_br_dir = lc_br_dir;
        use_gl_predictor_1: tn_br_dir = gl_br_dir;
        use_gl_predictor_2: tn_br_dir = gl_br_dir;
    endcase
end

always_comb begin
    next_state = current_state;
    case(current_state)
        use_lc_predictor_1: begin
            if(lc_correct & ~gl_correct)
                next_state = use_lc_predictor_2;
            else if (~lc_correct & gl_correct) 
                next_state = use_gl_predictor_1;
        end
        use_lc_predictor_2: begin
            if(~lc_correct & gl_correct)
                next_state = use_lc_predictor_1;
        end
        use_gl_predictor_1: begin
            if(~lc_correct & gl_correct)
                next_state = use_gl_predictor_2;
            else if(lc_correct & ~gl_correct)
                next_state = use_lc_predictor_1;
        end
        use_gl_predictor_2: begin
            if(lc_correct & ~gl_correct)
                next_state = use_gl_predictor_1;
        end
    endcase
end

always_ff @(posedge clk) begin
    if(rst) begin
        current_state <= use_lc_predictor_2;
    end
    else begin
        if (!stall & (ex_mem_opcode == op_br)) begin
            current_state <= next_state;
        end
    end
end
endmodule
