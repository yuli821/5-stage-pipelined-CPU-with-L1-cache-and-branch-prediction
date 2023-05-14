/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache 
import cache_types::*;
#(
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
    input logic mem_read,
    input logic mem_write,
    input logic [3:0] mem_byte_enable_cpu,
    input logic [31:0] mem_address,
    input logic [31:0] mem_wdata_cpu,
    output logic mem_resp,
    output logic [31:0] mem_rdata_cpu,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

logic [255:0] mem_wdata256, mem_rdata256;
logic [31:0] mem_byte_enable256;

logic hit, hit_0, hit_1, dirty, lru_out;
logic load_dirty_0, load_dirty_1, load_tag_0, load_tag_1, load_valid_0, load_valid_1;
logic load_lru;
write_en_mux::write_en_mux_sel_t write_en_mux_sel_0, write_en_mux_sel_1;
data_in_mux::data_in_mux_sel_t data_in_mux_sel;
data_out_mux::data_out_mux_sel_t data_out_mux_sel;
address_mux::addr_mux_sel_t addr_mux_sel;

cache_control control(.*);
cache_datapath  #(s_offset, s_index) datapath(.*);

line_adapter bus (
    .mem_wdata_line(mem_wdata256),
    .mem_rdata_line(mem_rdata256),
    .mem_wdata(mem_wdata_cpu),
    .mem_rdata(mem_rdata_cpu),
    .mem_byte_enable(mem_byte_enable_cpu),
    .mem_byte_enable_line(mem_byte_enable256),
    .address(mem_address)
);

endmodule : cache
