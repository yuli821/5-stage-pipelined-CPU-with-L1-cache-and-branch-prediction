module forwarding
import rv32i_types::*;
(
    input [4:0] ex_rs1,
    input [4:0] ex_rs2,
    input [4:0] mem_rd,
    input mem_load_regfile,
    input [4:0] wb_rd,
    input wb_load_regfile,
    output forwardmux::forwardmux_sel_t forward1,
    output forwardmux::forwardmux_sel_t forward2
);

always_comb begin
    forward1 = forwardmux::rs_out;
    if (ex_rs1 != 5'd0) begin
        if (mem_load_regfile & (mem_rd == ex_rs1))
            forward1 = forwardmux::ex_mem_out;
        else if (wb_load_regfile & (wb_rd == ex_rs1))
            forward1 = forwardmux::mem_wb_out;
    end
end

always_comb begin
    forward2 = forwardmux::rs_out;
    if (ex_rs2 != 5'd0) begin
        if (mem_load_regfile & (mem_rd == ex_rs2))
            forward2 = forwardmux::ex_mem_out;
        else if (wb_load_regfile & (wb_rd == ex_rs2))
            forward2 = forwardmux::mem_wb_out;
    end
end

endmodule
