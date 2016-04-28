
module top 
		(
		input wire CLK100MHZ,
		output wire [7:0]LED,

`ifdef HDMI
		//HDMI output
		output wire [7:0]TMDS,
`else
		//VGA output
		output wire VGA_HSYNC,
		output wire VGA_VSYNC,
		output wire [4:0]VGA_BLUE,
		output wire [5:0]VGA_GREEN,
		output wire [4:0]VGA_RED,
`endif

		input  wire FTDI_BD0, //RX
		output wire FTDI_BD1, //TX
		input  wire FTDI_BD2, //CTS
		output wire FTDI_BD3, //RTS

		input wire KEY0,
		input wire KEY1
	   );

wire w_reset;
wire w_video_clk;
wire w_video_clk5;

assign FTDI_BD1 = 1'b1;
assign FTDI_BD3 = 1'b1;

//instance of clock generator

`ifdef __ICARUS__ 

//simplified reset and clock generation for simulator
reg [3:0]rst_delay = 0;
always @(posedge CLK100MHZ)
	rst_delay <= { rst_delay[2:0], 1'b1 };

assign w_reset = ~rst_delay[3];
reg video_clk, video_clk5;
always
	#6.7 video_clk = ~video_clk;
always
	#1.34 video_clk5 = ~video_clk5;
assign w_video_clk = video_clk;
assign w_video_clk5= video_clk5;

`else

//use Quartus PLLs for real clock and reset synthesis
wire w_locked;
assign w_reset = ~w_locked;
mypll m_mypll(
	.inclk0(CLK100MHZ),
	.c0(w_video_clk),
	.c1(w_video_clk5),
	.locked(w_locked)
	);

`endif

//video signals
wire w_hsync;
wire w_vsync;
wire w_active;
wire [4:0]w_r;
wire [5:0]w_g;
wire [4:0]w_b;

wire [7:0]w_recv_byte;
wire w_recv_byte_ready;
serial m_serial(
	.reset( w_reset ),
	.clk74( w_video_clk ),
	.rx( FTDI_BD0 ),
	.rx_byte( w_recv_byte ),
	.rbyte_ready( w_recv_byte_ready )
	);

wire scr_wr;
wire [15:0]scr_wr_data;
wire [12:0]scr_wr_addr;
wire w_torus_last;
wire w_life_step;
wire w_seed;
wire w_seed_ena;

sloader
`ifdef BIG_TORUS
	#( .TORUS_WIDTH(64), .TORUS_HEIGHT(32) )
`else
	#( .TORUS_WIDTH(32), .TORUS_HEIGHT(16) )
`endif
  m_sloader(
	.clk(w_video_clk),
	.rx_byte( w_recv_byte ),
	.rbyte_ready( w_recv_byte_ready ),
	.vsync( w_vsync ),
	.key0( KEY0 ),
	.key1( KEY1 ),
	.torus_last( w_torus_last ),
	.seed( w_seed ),
	.seed_ena( w_seed_ena ),
	.life_step( w_life_step ),
	.wdata(scr_wr_data),
	.waddr(scr_wr_addr),
	.wr(scr_wr),
	.debug( LED )
	);
	
torus
`ifdef BIG_TORUS
	#( .TORUS_WIDTH(64), .TORUS_HEIGHT(32) )
`else
	#( .TORUS_WIDTH(32), .TORUS_HEIGHT(16) )
`endif
  m_torus(
	.clk( w_video_clk ),
	.seed( w_seed ),
	.seed_ena( w_seed_ena ),
	.life_step( w_life_step ),
	.torusv(),
	.torus_last( w_torus_last )
);

txtd 
	#( 
		.horz_front_porch( 110 ),
		.horz_sync( 40 ),
		.horz_back_porch( 220 ),
		.horz_addr_time( 1280 ),
		.vert_front_porch( 5 ),
		.vert_sync( 5 ),
		.vert_back_porch( 20 ),
		.vert_addr_time( 720 )
	)
	m_txtd(
	.pixel_clock( w_video_clk ),
	.wrdata( scr_wr_data ),
	.wradr( scr_wr_addr ),
	.wren( scr_wr ),

	.hsync(w_hsync),
	.vsync(w_vsync),

	.r( w_r ),
	.g( w_g ),
	.b( w_b ),
	.visible( w_active )
	);


`ifdef HDMI
wire w_tmds_bh;
wire w_tmds_bl;
wire w_tmds_gh;
wire w_tmds_gl;
wire w_tmds_rh;
wire w_tmds_rl;
hdmi u_hdmi(
	.pixclk( w_video_clk ),
	.clk_TMDS2( w_video_clk5 ),
	.hsync( w_hsync ),
	.vsync( w_vsync ),
	.active( w_active ),
	.red(  { w_r, 4'b0000 } ),
	.green({ w_g, 3'b000  } ),
	.blue( { w_b, 4'b0000 } ),
	.TMDS_bh( w_tmds_bh ),
	.TMDS_bl( w_tmds_bl ),
	.TMDS_gh( w_tmds_gh ),
	.TMDS_gl( w_tmds_gl ),
	.TMDS_rh( w_tmds_rh ),
	.TMDS_rl( w_tmds_rl )
);

`ifdef __ICARUS__
	ddio u_ddio1( .d1( w_video_clk), .d0( w_video_clk), .clk(w_video_clk5), .out( TMDS[1] ) );
	ddio u_ddio0( .d1(~w_video_clk), .d0(~w_video_clk), .clk(w_video_clk5), .out( TMDS[0] ) );
	ddio u_ddio3( .d1( w_tmds_bh),   .d0( w_tmds_bl),   .clk(w_video_clk5), .out( TMDS[3] ) );
	ddio u_ddio2( .d1(~w_tmds_bh),   .d0(~w_tmds_bl),   .clk(w_video_clk5), .out( TMDS[2] ) );
	ddio u_ddio5( .d1( w_tmds_gh),   .d0( w_tmds_gl),   .clk(w_video_clk5), .out( TMDS[5] ) );
	ddio u_ddio4( .d1(~w_tmds_gh),   .d0(~w_tmds_gl),   .clk(w_video_clk5), .out( TMDS[4] ) );
	ddio u_ddio7( .d1( w_tmds_rh),   .d0( w_tmds_rl),   .clk(w_video_clk5), .out( TMDS[7] ) );
	ddio u_ddio6( .d1(~w_tmds_rh),   .d0(~w_tmds_rl),   .clk(w_video_clk5), .out( TMDS[6] ) );
`else
	altddio_out1 u_ddio1( .datain_h( w_video_clk), .datain_l( w_video_clk), .outclock(w_video_clk5), .dataout( TMDS[1] ) );
	altddio_out1 u_ddio0( .datain_h(~w_video_clk), .datain_l(~w_video_clk), .outclock(w_video_clk5), .dataout( TMDS[0] ) );
	altddio_out1 u_ddio3( .datain_h( w_tmds_bh),   .datain_l( w_tmds_bl),   .outclock(w_video_clk5), .dataout( TMDS[3] ) );
	altddio_out1 u_ddio2( .datain_h(~w_tmds_bh),   .datain_l(~w_tmds_bl),   .outclock(w_video_clk5), .dataout( TMDS[2] ) );
	altddio_out1 u_ddio5( .datain_h( w_tmds_gh),   .datain_l( w_tmds_gl),   .outclock(w_video_clk5), .dataout( TMDS[5] ) );
	altddio_out1 u_ddio4( .datain_h(~w_tmds_gh),   .datain_l(~w_tmds_gl),   .outclock(w_video_clk5), .dataout( TMDS[4] ) );
	altddio_out1 u_ddio7( .datain_h( w_tmds_rh),   .datain_l( w_tmds_rl),   .outclock(w_video_clk5), .dataout( TMDS[7] ) );
	altddio_out1 u_ddio6( .datain_h(~w_tmds_rh),   .datain_l(~w_tmds_rl),   .outclock(w_video_clk5), .dataout( TMDS[6] ) );
`endif

`else
	//VGA signals
	assign VGA_BLUE = w_b;
	assign VGA_GREEN= w_g;
	assign VGA_RED  = w_r;
	assign VGA_HSYNC = w_hsync;
	assign VGA_VSYNC = w_vsync;
`endif


endmodule
