/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input logic clk,
    input logic rst, 
    input logic mem_write, mem_read,
    input logic valid0_out, valid1_out, dirty0_out, dirty1_out, hit0, hit1, lru_out, pmem_resp,
    input logic [31:0] mem_byte_enable256,
    output logic valid0_ld, valid1_ld, dirty0_ld, dirty1_ld, tag0_ld, tag1_ld, lru_ld,
    output logic dirty0_in, dirty1_in, lru_in, valid0_in, valid1_in,
    output logic [31:0] data0_write_en, data1_write_en,
    output logic paddrmux_sel, data0in_mux_sel, data1in_mux_sel, rdatamux_sel,
    output logic mem_resp, pmem_read, pmem_write
);

// always_comb begin
//     if(pmem_read & pmem_write) $display("what???");
// end

enum logic [2:0] {
    defaults, cache_lookup, write_mem, read_mem//, repeat_action
}next_state, state;

function void set_defaults();
    valid0_ld = 1'b0;
    valid1_ld = 1'b0;
    dirty0_ld = 1'b0;
    dirty1_ld = 1'b0;
    tag0_ld   = 1'b0;
    tag1_ld   = 1'b0;
    lru_ld    = 1'b0;
    lru_in    = lru_out;
    dirty0_in = dirty0_out;
    dirty1_in = dirty1_out;
    valid0_in = valid0_out;
    valid1_in = valid1_out;
    data0_write_en = 32'b0;
    data1_write_en = 32'b0;
    paddrmux_sel    = 1'b0;
    data0in_mux_sel = 1'b0;
    data1in_mux_sel = 1'b0;
    rdatamux_sel    = 1'b0;
    mem_resp   = 1'b0;
    pmem_read  = 1'b0;
    pmem_write = 1'b0;
endfunction

always_comb
begin : state_actions
    set_defaults();
    unique case(state)
        defaults: ;
        cache_lookup:
            begin
                if(hit0 & valid0_out) begin
                    mem_resp = 1'b1;
                    lru_ld = 1'b1;
                    lru_in = 1'b1;
                    if(mem_write) begin
                        dirty0_ld = 1'b1;
                        dirty0_in = 1'b1;
                        data0_write_en = mem_byte_enable256;
                        data0in_mux_sel = 1'b0;
                    end
                    else
                        rdatamux_sel = 1'b0;
                end
                else if(hit1 & valid1_out) begin
                    mem_resp = 1'b1;
                    lru_ld = 1'b1;
                    lru_in = 1'b0;
                    if(mem_write) begin
                        dirty1_ld = 1'b1;
                        dirty1_in = 1'b1;
                        data1_write_en = mem_byte_enable256;
                        data1in_mux_sel = 1'b0;
                    end
                    else
                        rdatamux_sel = 1'b1;
                end
            end
        write_mem:
            begin
                pmem_write = 1'b1;
                paddrmux_sel = 1'b0;
            end
        read_mem:
            begin
                pmem_read = 1'b1;
                paddrmux_sel = 1'b1;
                if (pmem_resp == 1'b1)
                begin
                    if (lru_out)  begin
                        data1in_mux_sel = 1'b1;
                        data1_write_en = 32'hffffffff;
                        tag1_ld = 1'b1;
                        valid1_ld = 1'b1;
                        valid1_in = 1'b1;
                        dirty1_ld = 1'b1;
                        dirty1_in = 1'b0;
                    end
                    else          begin
                        data0in_mux_sel = 1'b1;
                        data0_write_en = 32'hffffffff;
                        tag0_ld = 1'b1;
                        valid0_ld = 1'b1;
                        valid0_in = 1'b1;
                        dirty0_ld = 1'b1;
                        dirty0_in = 1'b0;
                    end
                end
            end
        default: ;
    endcase
end

always_comb
begin : next_state_logic
    unique case(state)
        default: next_state = defaults;
        defaults: 
            begin
                if(mem_write | mem_read)  next_state = cache_lookup;
                else                      next_state = defaults;
            end
        cache_lookup:
            begin
                if ((hit0 & valid0_out) || (hit1 & valid1_out)) next_state = defaults;
                else if ((lru_out == 1'b1 && dirty1_out == 1'b0)||(lru_out == 1'b0 && dirty0_out == 1'b0))
                next_state = read_mem;

                else next_state = write_mem;
                //else if ((hit0 & ~valid0_out) || (hit1 & ~valid1_out)) next_state = read_mem;//posible initial case, when access an adress with leaading 24 zeroes
                // else begin
                //     if(lru_out & dirty1_out) next_state = write_mem;
                //     else if (lru_out & ~dirty1_out) next_state = read_mem;
                //     else if (~lru_out & dirty0_out) next_state = write_mem;
                //     else                            next_state = read_mem;
                //end
            end
        write_mem:
            begin
                if(pmem_resp) next_state = read_mem;
                else          next_state = write_mem;
            end
        read_mem:
            begin
                if(pmem_resp) next_state = defaults;
                else          next_state = read_mem;
            end
        //repeat_action: next_state = defaults;
    endcase
end

always_ff @(posedge clk)
begin : next_state_assignment
    if (rst) state <= defaults;
    else     state <= next_state;
end

endmodule : cache_control
