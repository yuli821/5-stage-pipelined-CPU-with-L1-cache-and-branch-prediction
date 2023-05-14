/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst, 
    input [31:0]   mem_address,
    input [255:0]  mem_wdata256, pmem_rdata,
    input mem_read,
    input valid0_ld, valid1_ld, dirty0_ld, dirty1_ld, tag0_ld, tag1_ld, lru_ld,
    input dirty0_in, dirty1_in, lru_in, valid0_in, valid1_in,
    input [31:0] data0_write_en, data1_write_en,
    input paddrmux_sel, data0in_mux_sel, data1in_mux_sel, rdatamux_sel,
    output [255:0] mem_rdata256, pmem_wdata,
    output [31:0]  pmem_addr,
    output valid0_out, valid1_out, dirty0_out, dirty1_out, hit0, hit1, lru_out
);

logic [23:0] tag0_out, tag1_out, tag_in;
logic [255:0] data0_out, data1_out;
logic [2:0] index;
logic [255:0] rdatamux_out, data0_in, data1_in, pwdatamux_out;
logic [31:0]  tagaddrmux_out, paddrmux_out;
assign hit0 = (tag0_out == mem_address[31:8]) ? 1'b1:1'b0;
assign hit1 = (tag1_out == mem_address[31:8]) ? 1'b1:1'b0;
assign index = mem_address[7:5];
assign tag_in = mem_address[31:8];
assign mem_rdata256 = rdatamux_out;
assign pmem_wdata = pwdatamux_out;
assign pmem_addr = paddrmux_out;

array lru
(
    .*,
    .read(1'b1),
    .load(lru_ld),
    .rindex(index),
    .windex(index),
    .datain(lru_in),
    .dataout(lru_out)
);
array valid0
(
    .*,
    .read(1'b1),
    .load(valid0_ld),
    .rindex(index),
    .windex(index),
    .datain(valid0_in),
    .dataout(valid0_out)
);
array valid1
(
    .*,
    .read(1'b1),
    .load(valid1_ld),
    .rindex(index),
    .windex(index),
    .datain(valid1_in),
    .dataout(valid1_out)
);
array dirty0
(
    .*,
    .read(1'b1),
    .load(dirty0_ld),
    .rindex(index),
    .windex(index),
    .datain(dirty0_in),
    .dataout(dirty0_out)
);
array dirty1
(
    .*,
    .read(1'b1),
    .load(dirty1_ld),
    .rindex(index),
    .windex(index),
    .datain(dirty1_in),
    .dataout(dirty1_out)
);
array #(3,24) tag0
(
    .*,
    .read(1'b1),
    .load(tag0_ld),
    .rindex(index),
    .windex(index),
    .datain(tag_in),
    .dataout(tag0_out)
);
array #(3,24) tag1
(
    .*,
    .read(1'b1),
    .load(tag1_ld),
    .rindex(index),
    .windex(index),
    .datain(tag_in),
    .dataout(tag1_out)
);
data_array data0
(
    .*,
    .read(1'b1),
    .write_en(data0_write_en),
    .rindex(index),
    .windex(index),
    .datain(data0_in),
    .dataout(data0_out)
);
data_array data1
(
    .*,
    .read(1'b1),
    .write_en(data1_write_en),
    .rindex(index),
    .windex(index),
    .datain(data1_in),
    .dataout(data1_out)
);


always_comb begin:muxes
    unique case(rdatamux_sel)
        1'b0: rdatamux_out = data0_out;
        1'b1: rdatamux_out = data1_out;
        default:;
    endcase

    unique case(data0in_mux_sel)
        1'b0: data0_in = mem_wdata256;
        1'b1: data0_in = pmem_rdata;
        default:;
    endcase

    unique case(data1in_mux_sel)
        1'b0: data1_in = mem_wdata256;
        1'b1: data1_in = pmem_rdata;
        default:;
    endcase

    unique case(lru_out)
        1'b0: tagaddrmux_out = {tag0_out, index, 5'b00000};
        1'b1: tagaddrmux_out = {tag1_out, index, 5'b00000};
        default:;
    endcase

    unique case(lru_out)
        1'b0: pwdatamux_out = data0_out;
        1'b1: pwdatamux_out = data1_out;
        default:;
    endcase

    unique case(paddrmux_sel)
        1'b0: paddrmux_out = tagaddrmux_out;
        1'b1: paddrmux_out = {mem_address[31:5],5'b00000};
        default:;
    endcase
end

endmodule : cache_datapath
