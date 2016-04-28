  
module serial(
	input wire reset,
	input wire clk74,
	input wire rx,
	output reg [7:0]rx_byte,
	output reg rbyte_ready
	);

parameter RCONST = 642; //115200

reg [1:0]shr;
always @(posedge clk74)
	shr <= {shr[0],rx};
wire rxf; assign rxf = shr[1];

reg [15:0]cnt;

always @(posedge clk74 or posedge reset)
begin
	if(reset)
		cnt <= 0;
	else
	begin
		if(cnt == RCONST || num_bits==10)
			cnt <= 0;
		else
			cnt <= cnt + 1'b1;
	end
end

reg [3:0]num_bits;
reg [7:0]shift_reg;

always @(posedge clk74 or posedge reset)
begin
	if(reset)
	begin
		num_bits <= 0;
		shift_reg <= 0;
	end
	else
	begin
		if(num_bits==10 && rxf==1'b0)
			num_bits <= 0;
		else
		
		if( cnt == RCONST/2 )
		begin
			shift_reg <= {rxf,shift_reg[7:1]};
			num_bits <= num_bits + 1'b1;
		end
	end
end

wire eorecv; assign eorecv = (num_bits==9 && cnt == RCONST/2);
always @(posedge clk74 or posedge reset)
	if(reset)
	begin
		rx_byte <= 0;
	end
	else
	begin	
	if(eorecv)
		rx_byte <= shift_reg[7:0];
	end

reg [1:0]flag;
always @(posedge clk74 or posedge reset)
	if(reset)
		flag <= 2'b00;
	else
		flag <= {flag[0],eorecv};

always @*
	rbyte_ready = (flag==2'b01);
	
endmodule
