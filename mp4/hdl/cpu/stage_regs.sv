module if_id_reg
import rv32i_types::*;
(
    input clk,
    input rst,
    input load,
    input if_id_reg_t in,
    output if_id_reg_t out
);

if_id_reg_t data;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
    end
    else if (load)
    begin
        data <= in;
    end
    else
    begin
        data <= data;
    end
end

always_comb
begin
    out = data;
end

endmodule : if_id_reg



module id_ex_reg
import rv32i_types::*;
(
    input clk,
    input rst,
    input load,
    input id_ex_reg_t in,
    output id_ex_reg_t out
);

id_ex_reg_t data;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
    end
    else if (load)
    begin
        data <= in;
    end
    else
    begin
        data <= data;
    end
end

always_comb
begin
    out = data;
end

endmodule : id_ex_reg



module ex_mem_reg
import rv32i_types::*;
(
    input clk,
    input rst,
    input load,
    input ex_mem_reg_t in,
    output ex_mem_reg_t out
);

ex_mem_reg_t data;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
    end
    else if (load)
    begin
        data <= in;
    end
    else
    begin
        data <= data;
    end
end

always_comb
begin
    out = data;
end

endmodule : ex_mem_reg



module mem_wb_reg
import rv32i_types::*;
(
    input clk,
    input rst,
    input load,
    input mem_wb_reg_t in,
    output mem_wb_reg_t out
);

mem_wb_reg_t data;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
    end
    else if (load)
    begin
        data <= in;
    end
    else
    begin
        data <= data;
    end
end

always_comb
begin
    out = data;
end

endmodule : mem_wb_reg