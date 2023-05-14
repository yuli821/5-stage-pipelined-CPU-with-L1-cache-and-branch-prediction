module arbiter (
    input clk,
    input rst,

    /* Instruction memory signals */
    input   logic [31:0]    imem_address,
    output  logic [255:0]   imem_rdata,
    input   logic [255:0]   imem_wdata,
    input   logic           imem_read,
    input   logic           imem_write,
    output  logic           imem_resp,

    /* Data memory signals */
    input   logic [31:0]    dmem_address,
    output  logic [255:0]   dmem_rdata, 
    input   logic [255:0]   dmem_wdata,
    input   logic           dmem_read,
    input   logic           dmem_write,
    output  logic           dmem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata, 
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

/* State Enumeration */
enum int unsigned
{   rest,
	imem,
    dmem
} state, next_state;

/* State Control Signals */
always_comb begin : state_actions

	/* Defaults */
    pmem_address = dmem_address;
    pmem_wdata = dmem_wdata;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    
    dmem_resp = 1'b0;
    dmem_rdata = pmem_rdata;
    
    imem_resp = 1'b0;
    imem_rdata = pmem_rdata;
 

	case(state)
        rest: 
        begin
            if (dmem_read ^ dmem_write) begin
                pmem_read = dmem_read;
                pmem_write = dmem_write;
                dmem_resp = pmem_resp;
            end else if (imem_read ^ imem_write) begin
                pmem_read = imem_read;
                pmem_write = imem_write;
                imem_resp = pmem_resp;
                pmem_address = imem_address;
                pmem_wdata = imem_wdata;
            end
        end
        imem: begin
            pmem_read = imem_read;
            pmem_write = imem_write;
            imem_resp = pmem_resp;
            pmem_address = imem_address;
            pmem_wdata = imem_wdata;
        end
        dmem: begin
            pmem_read = dmem_read;
            pmem_write = dmem_write;
            dmem_resp = pmem_resp;
        end
	endcase
end

/* Next State Logic */
always_comb begin : next_state_logic

	/* Default state transition */
	next_state = state;

	case(state) 
        rest: begin
            if ((dmem_read ^ dmem_write) & !pmem_resp)
                next_state = dmem;
            else if ((imem_read ^ imem_write) & !pmem_resp)
                next_state = imem;
        end
        imem, dmem: begin
            if (pmem_resp)
                next_state = rest;
        end
	endcase
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
  if (rst) state <= rest;
  else state <= next_state;
end

endmodule : arbiter