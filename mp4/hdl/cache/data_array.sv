module data_array 
#(
    parameter s_index = 3,
    parameter num_sets = 2**s_index
)
(
  input clk,
  input rst,
  input logic [31:0] write_en,
  input logic [s_index-1:0] rindex,
  input logic [s_index-1:0] windex,
  input logic [255:0] datain,
  output logic [255:0] dataout
);

logic [255:0] data [num_sets];

always_comb begin
  for (int i = 0; i < 32; i++) begin
      dataout[8*i +: 8] = (write_en[i] & (rindex == windex)) ? datain[8*i +: 8] : data[rindex][8*i +: 8];
  end
end

always_ff @(posedge clk) begin
    if (rst) for (int i = 0; i < num_sets; ++i) begin
      data[i] <= '0;
    end
    else begin
    for (int i = 0; i < 32; i++) begin
		  data[windex][8*i +: 8] <= write_en[i] ? datain[8*i +: 8] : data[windex][8*i +: 8];
    end
    end
end

endmodule : data_array
