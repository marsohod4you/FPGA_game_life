  
module sloader(
	input wire clk,
	input wire [7:0]rx_byte,
	input wire rbyte_ready,
	input wire vsync,
	input wire key0,
	input wire key1,
	input wire torus_last,
	output reg seed,
	output reg seed_ena,
	output wire life_step,
	output wire [15:0]wdata,
	output wire [12:0]waddr,
	output wire wr,
	output wire [7:0]debug
	);

parameter TORUS_WIDTH  = 32;
parameter TORUS_HEIGHT = 16;

//find edge of hsync impulse
reg [2:0]vsyncf;
wire vsynce; assign vsynce = (vsyncf[2:1]==2'b01);

always @(posedge clk)
	vsyncf <= { vsyncf[1:0],vsync };

//process board button, against metastability and jitter
reg [2:0]key0f_;
wire key0f; assign key0f = key0f_[2];

reg [2:0]key1f_;
wire key1f; assign key1f = key1f_[2];

always @(posedge clk)
	if(vsynce)
	begin
	 key0f_<= { key0f_[1:0],key0 };
	 key1f_<= { key1f_[1:0],key1 };
	end

reg [3:0]rbyte_readyf_;
wire rbyte_readyf; assign rbyte_readyf = (rbyte_readyf_[1:0]==2'b01);
always @(posedge clk)
	rbyte_readyf_ <= { rbyte_readyf_[2:0], rbyte_ready };

//find 1 second impulse
reg [7:0]vsync_cnt;
wire second_imp; assign second_imp = (vsync_cnt==20);
always @(posedge clk)
	if(vsynce)
	begin
		if(second_imp)
			vsync_cnt <= 0;
		else
			vsync_cnt <= vsync_cnt + 1'b1;
	end

reg life_step_;
always @(posedge clk)
	life_step_ <= key0f & vsynce & second_imp;

assign life_step = life_step_ & key1f;

reg [7:0]rx_bytef;
always @(posedge clk)
begin
	if(rbyte_readyf)
		rx_bytef <= rx_byte;
end

reg [15:0]cell_counter;
reg [1:0]state;

always @(posedge clk)
begin
	if(~key0f)
	begin
		seed <= (rx_bytef==8'h2A);
		seed_ena <= (rbyte_readyf_[3:2]==2'b01) & (rx_bytef==8'h2A || rx_bytef==8'h2D);
		cell_counter <= 0;
		state <= 0;
	end
	else
	begin
	seed <= torus_last;
	case( state )
			0: begin
						cell_counter <= 0;
						seed_ena <= life_step_;
						state <= life_step_;
				end
			1:	begin
						seed_ena <= 1;
						state <= 2;
						cell_counter <= 0;
				end
			2:	begin
					if(cell_counter==TORUS_WIDTH*TORUS_HEIGHT-1)
					begin
						seed_ena <= 0;
						cell_counter <= 0;
						state <= 0;
					end
					else
					begin
						seed_ena <= 1;
						state <= 2;
						cell_counter <= cell_counter + 1'b1;
					end
				end
		endcase
	end
end

assign wr = (state==2);
assign wdata = torus_last ? 16'h4f2a : 16'h1f30;

parameter WBITS = $clog2(TORUS_WIDTH);
parameter HBITS = $clog2(TORUS_HEIGHT);

wire [3:0]wb; assign wb = WBITS;
wire [3:0]hb; assign hb = HBITS;
assign debug = { hb, wb };

//assign waddr = {2'b00,cell_counter[8:5],2'b00,cell_counter[4:0]};
wire [6:0]addr_l; assign addr_l = cell_counter[WBITS-1:0]+4;
wire [5:0]addr_h; assign addr_h = cell_counter[HBITS-1+WBITS:WBITS];
assign waddr = { addr_h, addr_l };

//assign waddr = {2'b00,cell_counter[8:5],2'b00,cell_counter[4:0]};
//assign waddr = {1'b0,cell_counter[10:6],1'b01,cell_counter[5:0]};

endmodule
