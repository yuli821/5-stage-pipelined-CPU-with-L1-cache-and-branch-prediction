package data_in_mux;
typedef enum bit {
    wdata = 1'b0,
    rdata = 1'b1
} data_in_mux_sel_t;
endpackage

package write_en_mux;
typedef enum bit [1:0] {
    write_none = 2'b00,
    byte_en = 2'b01,
    write_all = 2'b10
} write_en_mux_sel_t;
endpackage

package data_out_mux;
typedef enum bit {
    data_out_0 = 1'b0,
    data_out_1 = 1'b1
} data_out_mux_sel_t;
endpackage

package address_mux;
typedef enum bit {
    cache = 1'b0,
    memory = 1'b1
} addr_mux_sel_t;
endpackage

package cache_types;
import data_in_mux::*;
import write_en_mux::*;
import data_out_mux::*;
import address_mux::*;
endpackage
