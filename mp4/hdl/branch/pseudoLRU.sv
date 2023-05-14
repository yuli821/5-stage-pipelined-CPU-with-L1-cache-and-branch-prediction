module pseudoLRU #(parameter level = 1)
(
    input logic clk,
    input logic rst,
    input logic load,
    input logic [level-1:0] in,
    output logic [level-1:0] out
);

logic data;
logic dir;
assign dir = in[level-1];
logic [level-2:0] _out [2];

always_ff @(posedge clk) begin
    if(rst) data <= 1'b0;
    else    data <= load ? dir:data;
end

genvar i;
generate
    if (level > 1) begin
        for (i = 0 ; i < 2 ; i++) begin
            pseudoLRU #(level-1) child (.*, .load(({31'b0, dir} == i) & load ? 1'b1:1'b0), .in(in[level-2:0]), .out(_out[i]));
        end
        assign out = {~data, _out[~data]};
    end
    else begin
        assign out = ~data;
    end
endgenerate

endmodule
