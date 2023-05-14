/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control
import cache_types::*;
(
    input clk, rst,

    // From datapath
    input hit, hit_0, hit_1, dirty, lru_out,

    // From memory/cacheline adapter
    input pmem_resp,

    // From CPU/bus
    input mem_write, mem_read,

    // To CPU/bus
    output logic mem_resp,

    // To memory/cacheline 
    output logic pmem_read, pmem_write,

    // To datapath
    output logic load_dirty_0, load_dirty_1, load_tag_0, load_tag_1, load_valid_0, load_valid_1,
    output logic load_lru,
    output write_en_mux::write_en_mux_sel_t write_en_mux_sel_0, write_en_mux_sel_1,
    output data_in_mux::data_in_mux_sel_t data_in_mux_sel,
    output data_out_mux::data_out_mux_sel_t data_out_mux_sel, 
    output address_mux::addr_mux_sel_t addr_mux_sel
);

enum int unsigned {
    /* List of states */
    check_cache, update_cache, write_mem, read_mem
} state, next_state;

function void set_defaults();
    load_tag_0 = 1'b0;
    load_valid_0 = 1'b0;
    load_dirty_0 = 1'b0;
    load_tag_1 = 1'b0;
    load_valid_1 = 1'b0;
    load_dirty_1 = 1'b0;
    load_lru = 1'b0;
    write_en_mux_sel_0 = write_en_mux::write_none;
    write_en_mux_sel_1 = write_en_mux::write_none;
    addr_mux_sel = address_mux::cache;
    data_out_mux_sel = data_out_mux::data_out_0;
    data_in_mux_sel = data_in_mux::wdata;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    mem_resp = 1'b0;
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();

    /* Actions for each state */
    unique case (state)
        check_cache: begin
            if ((mem_write ^ mem_read) && hit) begin
                mem_resp = 1'b1;
                load_lru = 1'b1;
                data_out_mux_sel = data_out_mux::data_out_mux_sel_t'(hit_1);
                if (mem_write) begin
                    load_dirty_0 = hit_0;
                    load_dirty_1 = hit_1;
                    if (hit_0) 
                        write_en_mux_sel_0 = write_en_mux::byte_en;
                    if (hit_1)
                        write_en_mux_sel_1 = write_en_mux::byte_en;
                end
            end
        end
        write_mem: begin
            pmem_write = 1'b1;
            data_out_mux_sel = data_out_mux::data_out_mux_sel_t'(lru_out);
            load_dirty_0 = !lru_out;
            load_dirty_1 = lru_out;
        end
        read_mem: begin
            pmem_read = 1'b1;
            addr_mux_sel = address_mux::memory;
            load_tag_0 = !lru_out;
            load_tag_1 = lru_out;
            load_valid_0 = !lru_out;
            load_valid_1 = lru_out;
            data_in_mux_sel = data_in_mux::rdata;
            if(!lru_out)
                write_en_mux_sel_0 = write_en_mux::write_all;
            else
                write_en_mux_sel_1 = write_en_mux::write_all;
        end
    endcase

end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
    // default
    next_state = state;

    unique case (state)
        check_cache: 
            if ((mem_read ^ mem_write) && !hit)
            begin
                if (dirty)
                    next_state = write_mem;
                else 
                    next_state = read_mem;
            end
        write_mem: 
            if (pmem_resp)
                next_state = read_mem;
        read_mem:
            if (pmem_resp)
                next_state = check_cache;
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if (rst) 
    begin
        state <= check_cache;
    end
    else 
    begin
        state <= next_state;
    end
end

/**************************** Performance Counters *****************************/

// Total number of cache misses
int num_misses;
// Total number of memory access attempts
int num_access;
always_ff @(posedge clk)
begin: performance_counter
    if (rst)
    begin
        num_misses <= 0;
        num_access <= 0;
    end
    else
    begin
        if (state == check_cache && (next_state == read_mem || next_state == write_mem)) 
            num_misses <= num_misses + 1;
        if ((mem_read | mem_write) & mem_resp)
            num_access <= num_access + 1;
    end
end

endmodule : cache_control
