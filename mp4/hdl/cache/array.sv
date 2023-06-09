
module array #(
    parameter s_index = 3,
    parameter width = 1
)
(
  clk,
  rst,
  load,
  rindex,
  windex,
  datain,
  dataout
);

localparam num_sets = 2**s_index;

input clk;
input rst;
input load;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [width-1:0] datain;
output logic [width-1:0] dataout;

logic [width-1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */;

// always_comb begin
//   dataout = (load  & (rindex == windex)) ? datain : data[rindex];
// end
assign dataout = data[rindex]; // For synthesis

always_ff @(posedge clk)
begin
    if (rst) begin
      for (int i = 0; i < num_sets; ++i) data[i] <= '0;
    end
    else if(load) begin
        data[windex] <= datain;
    end
end

endmodule : array
