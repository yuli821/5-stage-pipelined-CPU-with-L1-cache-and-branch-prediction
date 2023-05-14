import rv32i_types::*;
module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);
/*
logic [2:0] plru_input;
logic [2:0] plru_output;
always_ff @(posedge itf.clk) begin
    if(itf.rst) plru_input = 3'b0;
    else plru_input = $random;
end*/

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// Dump signals
initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, mp4_tb, "+all");
end
/****************************** End do not touch *****************************/



/***************************** Spike Log Printer *****************************/
// Can be enabled for debugging
spike_log_printer printer(.itf(itf), .rvfi(rvfi));
/*************************** End Spike Log Printer ***************************/


/************************ Signals necessary for monitor **********************/
// This section not required until CP2
logic [4:0] rs1, rs2;
always_comb begin
    rs1 = 5'b0;
    rs2 = 5'b0;
    case(dut.cpu.datapath.mem_wb_out.ctrl.opcode)
        op_jalr, op_load, op_imm: rs1 = dut.cpu.datapath.mem_wb_out.sr1;
        op_br, op_store, op_reg: begin
            rs1 = dut.cpu.datapath.mem_wb_out.sr1;
            rs2 = dut.cpu.datapath.mem_wb_out.sr2;
        end
    endcase
end

//assign rvfi.commit = 0; // Set high when a valid instruction is modifying regfile or PC

assign rvfi.halt = ((rvfi.pc_rdata == rvfi.pc_wdata) && rvfi.commit); // Set high when target PC == Current PC for a branch
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

always_comb begin
    if(dut.cpu.datapath.mem_wb_out.ctrl.opcode != 7'b0 && dut.cpu.datapath.pipeline_reg_ctrl.load.mem_wb) rvfi.commit = 1'b1;//need to take account of stall in cp2
    else                                        rvfi.commit = 1'b0;
//Instruction and trap:
    rvfi.inst = dut.cpu.datapath.mem_wb_out.instr;
    rvfi.trap = 1'b0;

//Regfile:
    rvfi.rs1_addr = rs1;//if rs is not used in this instruction, should be x0?
    rvfi.rs2_addr = rs2;
    rvfi.rs1_rdata = rvfi.rs1_addr ? dut.cpu.datapath.mem_wb_out.rs1_out : 5'b0;
    rvfi.rs2_rdata = rvfi.rs2_addr ? dut.cpu.datapath.mem_wb_out.rs2_out : 5'b0;
    rvfi.load_regfile = dut.cpu.datapath.mem_wb_out.ctrl.load_regfile;
    rvfi.rd_addr = dut.cpu.datapath.mem_wb_out.ctrl.load_regfile ? dut.cpu.datapath.mem_wb_out.rd : 5'b0;
    rvfi.rd_wdata = rvfi.rd_addr ? dut.cpu.datapath.rd_data_in : 0;

//PC:
    rvfi.pc_rdata = dut.cpu.datapath.mem_wb_out.pc;
    rvfi.pc_wdata = ((dut.cpu.datapath.mem_wb_out.br_en && (dut.cpu.datapath.mem_wb_out.ctrl.opcode == op_br) || dut.cpu.datapath.mem_wb_out.ctrl.opcode == op_jal || dut.cpu.datapath.mem_wb_out.ctrl.opcode == op_jalr) ? dut.cpu.datapath.mem_wb_out.pc_val_b : rvfi.pc_rdata+4);

//Memory:
    rvfi.mem_addr = (dut.cpu.datapath.mem_wb_out.ctrl.mem_read | dut.cpu.datapath.mem_wb_out.ctrl.mem_write ? {dut.cpu.datapath.mem_wb_out.ex_data_out[31:2],2'b00} : 0);
    rvfi.mem_rmask = (dut.cpu.datapath.mem_wb_out.ctrl.mem_read ? dut.cpu.datapath.mem_wb_out.d_mbe : 4'b0000);
    rvfi.mem_wmask = (dut.cpu.datapath.mem_wb_out.ctrl.mem_write ? dut.cpu.datapath.mem_wb_out.d_mbe : 4'b0000);
    rvfi.mem_rdata = (dut.cpu.datapath.mem_wb_out.ctrl.mem_read ? dut.cpu.datapath.mem_wb_out.mem_rdata : 0);
    rvfi.mem_wdata = (dut.cpu.datapath.mem_wb_out.ctrl.mem_write ? dut.cpu.datapath.mem_wb_out.mem_wdata : 0);
end
//Please refer to rvfi_itf.sv for more information.


/**************************** End RVFIMON signals ****************************/



/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2

//The following signals need to be set:

always_comb begin
//icache signals:
    itf.inst_read = dut.cpu.instr_read;
    itf.inst_addr = dut.cpu.instr_mem_address;
    itf.inst_resp = dut.cpu.instr_mem_resp;
    itf.inst_rdata = dut.cpu.instr_mem_rdata;

//dcache signals:
    itf.data_read = dut.cpu.data_read;
    itf.data_write = dut.cpu.data_write;
    itf.data_mbe = dut.cpu.data_mbe;
    itf.data_addr = dut.cpu.data_mem_address;
    itf.data_wdata = dut.cpu.data_mem_wdata;
    itf.data_resp = dut.cpu.data_mem_resp;
    itf.data_rdata = dut.cpu.data_mem_rdata;

//Please refer to tb_itf.sv for more information.
end

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level for CP2:
Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/
/*
pseudoLRU #(3) lru (
    .clk(itf.clk),
    .rst(itf.rst),
    .load(1'b1),
    .in(plru_input),
    .out(plru_output)
);*/

mp4 dut(
    .clk(itf.clk),
    .rst(itf.rst),
    
     // Remove after CP1
    // .instr_mem_resp(itf.inst_resp),
    // .instr_mem_rdata(itf.inst_rdata),
	// .data_mem_resp(itf.data_resp),
    // .data_mem_rdata(itf.data_rdata),
    // .instr_read(itf.inst_read),
	// .instr_mem_address(itf.inst_addr),
    // .data_read(itf.data_read),
    // .data_write(itf.data_write),
    // .data_mbe(itf.data_mbe),
    // .data_mem_address(itf.data_addr),
    // .data_mem_wdata(itf.data_wdata)


    //Use for CP2 onwards
    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),
    .pmem_wdata(itf.mem_wdata),
    .pmem_rdata(itf.mem_rdata),
    .pmem_address(itf.mem_addr),
    .pmem_resp(itf.mem_resp)
);
/***************************** End Instantiation *****************************/

endmodule
