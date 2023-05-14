module cache_dut_tb;

timeunit 1ns;
timeprecision 1ns;

/****************************** Generate Clock *******************************/
bit clk;
always #5 clk = clk === 1'b0;


/****************************** Dump Signals *******************************/
int timeout = 10000000;
logic [255:0] write_back;
logic [255:0] wb [logic [31:5]];
logic [31:0]  pseudomem [logic[19:0]];
logic [31:0] address;
logic [31:0] wdata;

cache_tb_itf itf(.*);
initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, cache_dut_tb, "+all");
    $display("Compilation Successful");

    reset();
    itf.rst = 1'b1;
    repeat (5) @(posedge clk);
    itf.rst = 1'b0;
    address = 32'b0;
    wdata = 32'b0;
    //$display("init read");
    //readmem_init(32'b0, 8);
    //$display("read different address with same index");
    //readmem_init({24'hdeedee,3'b0,5'b00000},256);
    //$display("read different address with same index twice, should not initiate write_back");
    //readmem_init({24'h666666,3'b0,5'b00000},1024);
    // $display("init write to index0");
    // write_init(32'b0, 8);//data0
    // $display("write different address with same index");
    // write_init({24'hdeedee,3'b0,5'b00000},256);//data1
    // $display("write different address with same index twice, should trigger write_back");
    // write_wb({24'h666666,3'b0,5'b00000},1024);//data0, write abck 8
    // assert(write_back == 256'h8) else begin
    //     $error("Wrong write back data");
    // end
    // $display("normal 2-cycle write the same address,hit");
    // write({24'h666666,3'b0,5'b00000},512);//data0
    // $display("normal 2-cycle write the same address,hit");
    // write({24'hdeedee,3'b0,5'b00000},4);//data1
    // $display("write with offset");
    // write({24'hdeedee,3'b0,5'b00100},1);//data1

    // $display("init write to index1");
    // write_init({24'b0,3'b010,5'b00000},8);//data0
    // $display("write different address with same index");
    // write_init({24'hceecee,3'b010,5'b00000},256);//data1
    // $display("write different address with same index twice, should trigger write_back");
    // write_wb({24'h555555,3'b010,5'b00000},1024);//data0, write abck 8
    // assert(write_back == 256'h8) else begin
    //     $error("Wrong write back data");
    // end
    // $display("normal 2-cycle write the same address,hit");
    // write({24'h555555,3'b010,5'b00000},512);//data0
    // $display("normal 2-cycle write the same address,hit");
    // write({24'hceecee,3'b010,5'b00000},4);//data1
    // $display("write with offset");
    // write({24'hceecee,3'b010,5'b00100},1);//data1
    writeoutput();
    checkoutput();
end

always_comb begin
    assert(~(itf.pmem_read & itf.pmem_write)) else begin
        $error("pmem_read and pmem_write are raised at the same time.");
    end
end

always_ff @(posedge clk) begin
    itf.pmem_resp = 1'b0;
    if(itf.pmem_read) begin
        itf.pmem_resp = 1'b1;
    end
    else if (itf.pmem_write) begin//address from tag
        itf.pmem_resp = 1'b1;
    end
end

always_comb begin
    if(itf.pmem_read) begin
        itf.pmem_rdata = wb[itf.pmem_address[31:5]];
    end
    else if (itf.pmem_write) begin//address from tag
        wb[itf.pmem_address[31:5]] = itf.pmem_wdata;
    end
end

task writeoutput();
        for(int j = 0; j < 1048575; ++j) begin
            address = {j,2'b00};  //write address
            wdata = $urandom;
            @(posedge clk iff ~(itf.mem_read | itf.mem_write));
            itf.mem_write <= 1'b1;
            itf.mem_read <= 1'b0;
            itf.mem_address <= address;
            itf.mem_wdata <= wdata;
            itf.mem_byte_enable <= 4'hf;
            pseudomem[j] <= wdata;
            @(posedge clk iff itf.mem_resp);
            reset();
        end
endtask : writeoutput

task checkoutput();
for(int j = 0; j < 1048575; ++j) begin
    @(posedge clk iff ~(itf.mem_read | itf.mem_write));
    itf.mem_read <= 1'b1;
    itf.mem_write <= 1'b0;
    itf.mem_address <= {j,2'b00};
    @(posedge clk iff itf.mem_resp);
    assert(itf.mem_rdata == pseudomem[j]) else begin
        $error("%d: unmatched data, got %h, expected %h.", j, itf.mem_rdata, pseudomem[j]);
    end
    reset();
end
endtask

task write(input logic[31:0] addr, input logic[31:0] wdata);
    @(posedge clk iff ~(itf.mem_read | itf.mem_write));
    itf.mem_write <= 1'b1;
    itf.mem_read <= 1'b0;
    itf.mem_address <= addr;
    itf.mem_wdata <= wdata;
    itf.mem_byte_enable <= 4'hf;
    @(posedge clk iff itf.mem_resp);
    itf.mem_read <= 1'b1;
    itf.mem_write <= 1'b0;
    itf.mem_address <= addr;
    @(posedge clk iff itf.mem_resp);
    assert(itf.mem_rdata[(32*addr[4:2]) +: 32] == wdata) else begin
        $error("wrong read data after write.");
    end
    reset();
endtask

task write_init(input logic[31:0] addr, input logic[31:0] wdata);
    @(posedge clk iff ~(itf.mem_read | itf.mem_write));
    itf.mem_write <= 1'b1;
    itf.mem_read <= 1'b0;
    itf.mem_address <= addr;
    itf.mem_wdata <= wdata;
    itf.mem_byte_enable <= 4'hf;
    @(posedge clk iff (itf.pmem_read | itf.pmem_write));
    assert(itf.pmem_write == 1'b0) else begin
        $error("wrong write-back, haven't filled the two tags.");
    end
    assert(itf.pmem_address == itf.mem_address) else begin
        $error("wrong address.");
    end
    itf.pmem_rdata <= 256'b0;
    itf.pmem_resp <= 1'b1;
    @(posedge clk);
    itf.pmem_resp <= 1'b0;
    @(posedge clk iff itf.mem_resp);
    itf.mem_read <= 1'b1;
    itf.mem_write <= 1'b0;
    itf.mem_address <= addr;
    @(posedge clk iff itf.mem_resp);
    assert(itf.mem_rdata[(32*addr[4:2]) +: 32] == wdata) else begin
        $error("wrong read data after write.");
    end
    reset();
endtask

task write_wb(input logic[31:0] addr, input logic[31:0] wdata);
    @(posedge clk iff ~(itf.mem_read | itf.mem_write));
    itf.mem_write <= 1'b1;
    itf.mem_read <= 1'b0;
    itf.mem_address <= addr;
    itf.mem_wdata <= wdata;
    itf.mem_byte_enable <= 4'hf;
    @(posedge clk iff (itf.pmem_write));

    assert(itf.pmem_address[7:5] == itf.mem_address[7:5]) else begin
        $error("Access the wrong set.");
    end
    write_back = itf.pmem_wdata;
    repeat (5) @(posedge clk);
    itf.pmem_resp <= 1'b1;
    @(posedge clk);
    itf.pmem_resp <= 1'b0;
    @(posedge clk iff (itf.pmem_read == 1'b1));
    assert(itf.pmem_address == itf.mem_address) else begin
        $error("wrong address.");
    end
    itf.pmem_rdata <= 256'b0;
    itf.pmem_resp <= 1'b1;
    @(posedge clk);
    itf.pmem_resp <= 1'b0;
    @(posedge clk iff itf.mem_resp);
    itf.mem_read <= 1'b1;
    itf.mem_write <= 1'b0;
    itf.mem_address <= addr;
    @(posedge clk iff itf.mem_resp);
    assert(itf.mem_rdata[(32*addr[4:2]) +: 32] == wdata) else begin
        $error("wrong read data after write.");
    end
    reset();
endtask

task readmem_init(input logic[31:0] addr, input logic[31:0] rdata);
    @(posedge clk iff ~(itf.mem_read | itf.mem_write));
    itf.mem_read <= 1'b1;
    itf.mem_write <= 1'b0;
    itf.mem_address <= addr;
    @(posedge clk iff (itf.pmem_read | itf.pmem_write));
    assert(itf.pmem_write == 1'b0) else begin
        $error("wrong write-back, haven't filled the two tags.");
    end
    assert(itf.pmem_address == itf.mem_address) else begin
        $error("wrong address.");
    end
    itf.pmem_rdata <= rdata;
    itf.pmem_resp <= 1'b1;
    @(posedge clk);
    itf.pmem_resp <= 1'b0;
    @(posedge clk iff itf.mem_resp);
    assert(itf.mem_rdata[(32*addr[4:2]) +: 32] == rdata) else begin
        $error("wrong read data.");
    end
    reset();
endtask

task readmem_replace(input logic[31:0] addr,input logic[31:0] rdata);
    @(posedge clk iff ~(itf.mem_read | itf.mem_write));
    itf.mem_read <= 1'b1;
    itf.mem_write <= 1'b0;
    itf.mem_address <= addr;
    @(posedge clk iff (itf.pmem_write));

    assert(itf.pmem_address[7:5] == itf.mem_address[7:5]) else begin
        $error("Access the wrong set.");
    end
    write_back = itf.pmem_wdata;
    repeat (5) @(posedge clk);
    itf.pmem_resp <= 1'b1;
    @(posedge clk);
    itf.pmem_resp <= 1'b0;
    @(posedge clk iff (itf.pmem_read == 1'b1));
    assert(itf.pmem_address == itf.mem_address) else begin
        $error("wrong address.");
    end
    itf.pmem_rdata <= rdata;
    itf.pmem_resp <= 1'b1;
    @(posedge clk);
    itf.pmem_resp <= 1'b0;
    @(posedge clk iff itf.mem_resp);
    assert(itf.mem_rdata[(32*addr[4:2]) +: 32] == rdata) else begin
        $error("wrong read data.");
    end
    reset();

endtask

task reset();
    itf.mem_read <= 1'b0;
    itf.mem_write <= 1'b0;
    //itf.mem_address <= 32'b0;
    itf.mem_wdata <= 32'b0;
endtask

always @(posedge itf.clk) begin
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    timeout <= timeout - 1;
end

/****************************** Generate Reset ******************************/


/*************************** Instantiate DUT HERE ***************************/
cache dut(
    .clk(itf.clk),
    .rst(itf.rst),
    .mem_address(itf.mem_address),
    .mem_rdata(itf.mem_rdata),
    .mem_wdata(itf.mem_wdata),
    .mem_read(itf.mem_read),
    .mem_write(itf.mem_write),
    .mem_byte_enable(itf.mem_byte_enable),
    .mem_resp(itf.mem_resp),

    /* Physical memory signals */
    .pmem_address(itf.pmem_address),
    .pmem_rdata(itf.pmem_rdata),
    .pmem_wdata(itf.pmem_wdata),
    .pmem_read(itf.pmem_read),
    .pmem_write(itf.pmem_write),
    .pmem_resp(itf.pmem_resp)
);



endmodule : cache_dut_tb