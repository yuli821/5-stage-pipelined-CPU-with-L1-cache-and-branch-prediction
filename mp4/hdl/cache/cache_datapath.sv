/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath 
import cache_types::*;
import rv32i_types::*;
#(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk, rst,
    
    // From CPU/bus
    input [31:0] mem_address, mem_byte_enable256,
    input mem_write,
    input [255:0] mem_wdata256,

    // From memory/cacheline adapter
    input [255:0] pmem_rdata,

    // From control
    input logic load_dirty_0, load_dirty_1, load_tag_0, load_tag_1, load_valid_0, load_valid_1,
    input logic load_lru,
    input write_en_mux::write_en_mux_sel_t write_en_mux_sel_0, write_en_mux_sel_1,
    input data_in_mux::data_in_mux_sel_t data_in_mux_sel,
    input data_out_mux::data_out_mux_sel_t data_out_mux_sel, 
    input address_mux::addr_mux_sel_t addr_mux_sel,

    // To CPU/bus
    output [255:0] mem_rdata256,

    // To memory/cacheline adapter
    output [255:0] pmem_wdata,
    output rv32i_word pmem_address,

    // To control
    output logic dirty, hit, hit_1, hit_0, lru_out
        
);

    localparam tag_low = 32 - s_tag;
    localparam index_low = s_offset;
    localparam index_high = index_low + s_index - 1;

    logic dirty_0, dirty_1, valid_0, valid_1;
    logic [s_tag-1:0] tag_0, tag_1;
    logic [255:0] data_out, data_out_0, data_out_1;
    logic [255:0] data_array_in;
    logic [31:0] data_write_en_0, data_write_en_1;

    assign pmem_wdata = data_out;
    assign mem_rdata256 = data_out;

    always_comb begin
        hit_0 = (tag_0 == mem_address[31:tag_low]) & valid_0;
        hit_1 = (tag_1 == mem_address[31:tag_low]) & valid_1;
        hit = hit_0 | hit_1;
        dirty = (!lru_out & dirty_0) | (lru_out & dirty_1);
    end
    array #(.s_index(s_index), .width(1))
    dirty_array_0(
        .clk(clk),
        .rst(rst),
        .load(load_dirty_0),
        .rindex(mem_address[index_high:index_low]),
        .windex(mem_address[index_high:index_low]),
        .datain(mem_write),
        .dataout(dirty_0)
    );

    array #(.s_index(s_index), .width(1))
    dirty_array_1(
        .clk(clk),
        .rst(rst),
        .load(load_dirty_1),
        .rindex(mem_address[index_high:index_low]),
        .windex(mem_address[index_high:index_low]),
        .datain(mem_write),
        .dataout(dirty_1)
    );

    array #(.s_index(s_index), .width(1))
    valid_array_0(
        .clk(clk),
        .rst(rst),
        .load(load_valid_0),
        .rindex(mem_address[index_high:index_low]),
        .windex(mem_address[index_high:index_low]),
        .datain(1'b1),
        .dataout(valid_0)
    );

    array #(.s_index(s_index), .width(1))
    valid_array_1(
        .clk(clk),
        .rst(rst),
        .load(load_valid_1),
        .rindex(mem_address[index_high:index_low]),
        .windex(mem_address[index_high:index_low]),
        .datain(1'b1),
        .dataout(valid_1)
    );

    array #(.s_index(s_index), .width(s_tag))
    tag_array_0(
        .clk(clk),
        .rst(rst),
        .load(load_tag_0),
        .rindex(mem_address[index_high:index_low]),
        .windex(mem_address[index_high:index_low]),
        .datain(mem_address[31:tag_low]),
        .dataout(tag_0)
    );

    array #(.s_index(s_index), .width(s_tag))
    tag_array_1(
        .clk(clk),
        .rst(rst),
        .load(load_tag_1),
        .rindex(mem_address[index_high:index_low]),
        .windex(mem_address[index_high:index_low]),
        .datain(mem_address[31:tag_low]),
        .dataout(tag_1)
    );

    data_array #(s_index) data_array_0
    (
        .clk(clk),
        .rst(rst),
        .write_en(data_write_en_0),
        .rindex(mem_address[index_high:index_low]),
        .windex(mem_address[index_high:index_low]),
        .datain(data_array_in),
        .dataout(data_out_0)
    );

    data_array #(s_index) data_array_1
    (
        .clk(clk),
        .rst(rst),
        .write_en(data_write_en_1),
        .rindex(mem_address[index_high:index_low]),
        .windex(mem_address[index_high:index_low]),
        .datain(data_array_in),
        .dataout(data_out_1)
    );

    array #(.s_index(s_index), .width(1))
    lru_array(
        .clk(clk),
        .rst(rst),
        .load(load_lru),
        .rindex(mem_address[index_high:index_low]),
        .windex(mem_address[index_high:index_low]),
        .datain(hit_0),
        .dataout(lru_out)
    );

always_comb begin
    unique case (data_out_mux_sel)
        data_out_mux::data_out_0: data_out = data_out_0;
        data_out_mux::data_out_1: data_out = data_out_1;
    endcase

    unique case (data_in_mux_sel)
        data_in_mux::wdata: data_array_in = mem_wdata256;
        data_in_mux::rdata: data_array_in = pmem_rdata;
    endcase

    unique case (write_en_mux_sel_0)
        write_en_mux::write_none: data_write_en_0 = 32'd0;
        write_en_mux::byte_en: data_write_en_0 = mem_byte_enable256;
        write_en_mux::write_all: data_write_en_0 = {32{1'b1}};
    endcase

    unique case (write_en_mux_sel_1)
        write_en_mux::write_none: data_write_en_1 = 32'd0;
        write_en_mux::byte_en: data_write_en_1 = mem_byte_enable256;
        write_en_mux::write_all: data_write_en_1= {32{1'b1}};
    endcase

    unique case (addr_mux_sel) 
        address_mux::cache: pmem_address = {lru_out ? tag_1 : tag_0, mem_address[index_high:index_low], 5'd0};
        address_mux::memory: pmem_address = mem_address;
    endcase
end

endmodule : cache_datapath
