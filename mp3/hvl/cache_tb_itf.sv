
`ifndef CACHE_TB_ITF_SV
`define CACHE_TB_ITF_SV
interface cache_tb_itf
(
    input bit clk
);
    logic [31:0]    mem_address, mem_rdata, mem_wdata;
    logic           mem_read,mem_write;
    logic [3:0]     mem_byte_enable;
    logic           mem_resp;

    /* Physical memory signals */
    logic [31:0]    pmem_address;
    logic [255:0]   pmem_rdata;
    logic [255:0]   pmem_wdata;
    logic           pmem_read,pmem_write,pmem_resp;

    logic rst = 1'b0;
    
    modport dut(
        input clk, rst, mem_resp, mem_rdata, pmem_address, pmem_wdata, pmem_read, pmem_write, 
        output mem_read, mem_write, mem_address, mem_wdata, pmem_rdata, pmem_resp
    );

endinterface
`endif
