
module xcell(
	input wire clk,
	input wire seed_ena,
	input wire life_step,
	input wire in_up_left,
	input wire in_up,
	input wire in_up_right,
	input wire in_left,
	input wire in_right,
	input wire in_down_left,
	input wire in_down,
	input wire in_down_right,
	output reg cell_life
);

wire [3:0]neighbor_number;
assign neighbor_number =
								in_up_left +
								in_up +
								in_up_right +
								in_left +
								in_right +
								in_down_left +
								in_down +
								in_down_right;
	
always @(posedge clk)
	if(seed_ena)
		cell_life <= in_left; 	//do load initial life into cell
	else
	if(life_step)					//recalculate new generation of life
	begin
		if( neighbor_number == 3 )
			cell_life <= 1'b1; //born
		else
		if( neighbor_number < 2 || neighbor_number > 3 )
			cell_life <= 1'b0; //die
	end

endmodule
