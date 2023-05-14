module rd_data_decoder
import rv32i_types::*;
(
    input rv32i_word read_data,
    input [1:0] addr,
    input regfilemux::regfilemux_sel_t regfilemux_sel,
    input rv32i_word ex_data_out,
    output rv32i_word rd_data_in
);

logic [31:0] lw;
logic [31:0] lh;
logic [31:0] lhu;
logic [31:0] lb;
logic [31:0] lbu;

assign lw = read_data;
assign lh = 32'(signed'(addr[1] ? read_data[31:16] : read_data[15:0]));
assign lhu = 32'(unsigned'(addr[1] ? read_data[31:16] : read_data[15:0]));
assign lb = 32'(signed'(addr[0] ? lh[15:8] : lh[7:0]));
assign lbu = 32'(unsigned'(addr[0] ? lh[15:8] : lh[7:0]));

always_comb begin : RD_DATA_IN_MUX

    unique case (regfilemux_sel)
        regfilemux::lw: rd_data_in = lw;
        regfilemux::lh: rd_data_in = lh;
        regfilemux::lhu: rd_data_in = lhu;
        regfilemux::lb: rd_data_in = lb;
        regfilemux::lbu: rd_data_in = lbu;
        regfilemux::ex_data_out: rd_data_in = ex_data_out;
        default: rd_data_in = ex_data_out;
    endcase
 
end

endmodule : rd_data_decoder