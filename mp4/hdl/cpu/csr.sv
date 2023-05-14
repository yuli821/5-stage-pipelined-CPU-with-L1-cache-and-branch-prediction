module csr
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    output logic [31:0] val
);

logic [31:0] counter;

register csr(.*, .load(1'b1), .in(counter), .out(val));

always_ff @(posedge clk) begin
    if(rst) counter <= 0;
    else    counter <= counter + 1;
end

endmodule
