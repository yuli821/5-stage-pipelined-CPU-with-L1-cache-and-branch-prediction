module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);
enum logic [2:0] {idle, read_wait, output_r, write_wait, output_w} curr_state, next_state;
logic [255:0] buffer_r;
logic [31:0] address;
logic [2:0] counter;
logic finish;
assign address_o = address;
assign line_o = buffer_r;
assign finish = counter[1]&counter[0];

always_comb begin
	next_state = curr_state;
	unique case(curr_state)
		idle:begin
			if((read_i == 1'b1) && (write_i == 1'b0)) next_state = read_wait;
			else if ((read_i == 1'b0) && (write_i == 1'b1)) next_state = write_wait;
		end
		read_wait: if (finish) next_state = output_r;
		output_r: next_state = idle;
		write_wait: if (finish) next_state = output_w;
		output_w: next_state = idle;
		default:;
	endcase
        case(curr_state)
		idle:begin
			read_o = 1'b0;
			write_o = 1'b0;
			resp_o = 1'b0;
		end
		read_wait:begin
			read_o = 1'b1;
			write_o = 1'b0;
			resp_o = 1'b0;
		end
		output_r:begin
			read_o = 1'b0;
			write_o = 1'b0;
			resp_o = 1'b1;
		end
		write_wait:begin
			read_o = 1'b0;
			write_o = 1'b1;
			resp_o = 1'b0;
		end
		output_w:begin
			read_o = 1'b0;
			write_o = 1'b0;
			resp_o = 1'b1;
		end
        endcase
end

always_ff @(posedge clk) begin
	if (~reset_n)
		curr_state <= idle;
	else 
		curr_state <= next_state;
	address <= address_i;
	if (curr_state == read_wait) begin
		//address <= address_i;
		if (counter < 4) begin
			buffer_r[64*counter +: 64] <= burst_i;
			if(resp_i) begin
				counter <= counter + 3'b001;
			end
		end
	end
	else if (curr_state == write_wait) begin
		//address <= address_i;
		if (counter < 4) begin
			if(resp_i)
				counter = counter + 3'b001;
			burst_o = line_i[64*counter +: 64];
			//$display("%0d, %0x, %0x", counter, buffer_w[64*counter +: 64], burst_o);
		end 
	end
	else if (curr_state == idle) begin
		counter <= 3'b000;
	end
end
endmodule : cacheline_adaptor

