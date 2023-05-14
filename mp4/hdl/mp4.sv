
module mp4
import rv32i_types::*;
(
    input clk,
    input rst,

    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

logic instr_mem_resp, data_mem_resp, data_read, data_write, instr_read;
rv32i_word instr_mem_rdata, data_mem_rdata, instr_mem_address, data_mem_address, data_mem_wdata;
logic [3:0] data_mbe;

logic imem_read, dmem_read, dmem_write, imem_write, imem_resp, dmem_resp;
logic [255:0] imem_rdata, dmem_rdata, imem_wdata, dmem_wdata;
logic [31:0] imem_address, dmem_address;

logic read_i, write_i, resp_o;
logic [255:0] line_o, line_i;
logic [31:0] address_i;

cpu cpu (.*);

cache #(.s_index(4)) icache (
    .clk(clk),
    .rst(rst),

    .mem_address(instr_mem_address),
    .mem_rdata_cpu(instr_mem_rdata),
    .mem_wdata_cpu(32'd0),
    .mem_read(instr_read),
    .mem_write(1'b0),
    .mem_byte_enable_cpu(4'd0),
    .mem_resp(instr_mem_resp),

    .pmem_address(imem_address),
    .pmem_rdata(imem_rdata),
    .pmem_wdata(imem_wdata),
    .pmem_read(imem_read),
    .pmem_write(imem_write),
    .pmem_resp(imem_resp)
);

cache #(.s_index(2)) dcache (
    .clk(clk),
    .rst(rst),

    .mem_address(data_mem_address),
    .mem_rdata_cpu(data_mem_rdata),
    .mem_wdata_cpu(data_mem_wdata),
    .mem_read(data_read),
    .mem_write(data_write),
    .mem_byte_enable_cpu(data_mbe),
    .mem_resp(data_mem_resp),

    .pmem_address(dmem_address),
    .pmem_rdata(dmem_rdata),
    .pmem_wdata(dmem_wdata),
    .pmem_read(dmem_read),
    .pmem_write(dmem_write),
    .pmem_resp(dmem_resp)
);

arbiter arbiter (
    .clk(clk),
    .rst(rst),

    .dmem_address(dmem_address),
    .dmem_rdata(dmem_rdata),
    .dmem_wdata(dmem_wdata),
    .dmem_read(dmem_read),
    .dmem_write(dmem_write),
    .dmem_resp(dmem_resp),

    .imem_address(imem_address),
    .imem_rdata(imem_rdata),
    .imem_wdata(imem_wdata),
    .imem_read(imem_read),
    .imem_write(imem_write),
    .imem_resp(imem_resp),

    .pmem_address(address_i),
    .pmem_rdata(line_o),
    .pmem_wdata(line_i),
    .pmem_read(read_i),
    .pmem_write(write_i),
    .pmem_resp(resp_o)
);

cacheline_adaptor cacheline_adapter(
    .clk(clk),
    .reset_n(~rst),
    
    .line_i(line_i),
    .line_o(line_o),
    .address_i(address_i),
    .read_i(read_i),
    .write_i(write_i),
    .resp_o(resp_o),

    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);


endmodule : mp4