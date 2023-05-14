/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache #(
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

    /* CPU memory signals */
    input   logic [31:0]    mem_address,
    output  logic [31:0]    mem_rdata,
    input   logic [31:0]    mem_wdata,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic [3:0]     mem_byte_enable,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

logic [255:0] mem_rdata256, mem_wdata256;
logic [31:0]  mem_byte_enable256;
logic valid0_out, valid1_out, dirty0_out, dirty1_out, hit0, hit1, lru_out;
logic valid0_ld, valid1_ld, dirty0_ld, dirty1_ld, tag0_ld, tag1_ld, lru_ld;
logic dirty0_in, dirty1_in, lru_in, valid0_in, valid1_in;
logic [31:0] data0_write_en, data1_write_en;
logic paddrmux_sel, data0in_mux_sel, data1in_mux_sel, rdatamux_sel;

cache_control control
(
    .*
);

cache_datapath datapath
(
    .*,
    .pmem_addr(pmem_address)
);

bus_adapter bus_adapter
(
    .*,
    .address(mem_address)
);

endmodule : cache
