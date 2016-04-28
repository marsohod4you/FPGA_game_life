
module torus(
	input wire clk,
	input wire seed,
	input wire seed_ena,
	input wire life_step,
	output wire [TORUS_WIDTH*TORUS_HEIGHT-1:0]torusv,
	output wire torus_last
);

parameter TORUS_WIDTH  = 32;
parameter TORUS_HEIGHT = 16;

localparam WMASK = (TORUS_WIDTH-1);
localparam HMASK = (TORUS_HEIGHT-1);

genvar x;
genvar y;

generate
	for(y=0; y<TORUS_HEIGHT; y=y+1)
	begin: crow
		for(x=0; x<TORUS_WIDTH; x=x+1)
		begin: ccol
			wire value;
			wire seed_source;
			assign seed_source = (y==0) && (x==0) ? seed :
										(y!=0) && (x==0) ? crow[ y-1 ].ccol[ TORUS_WIDTH-1 ].value :
											                crow[ y ].ccol[ x-1 ].value ;
			xcell my_xcell(
				.clk( clk ),
				.seed_ena  (seed_ena),
				.life_step (life_step),
				.in_up_left( 	 crow[ (y-1)&HMASK ].ccol[ (x-1)&WMASK ].value ),
				.in_up( 			 crow[ (y-1)&HMASK ].ccol[ (x-0)&WMASK ].value ),
				.in_up_right(   crow[ (y-1)&HMASK ].ccol[ (x+1)&WMASK ].value ),
				.in_left(  		 seed_ena ? seed_source : crow[ (y-0)&HMASK ].ccol[ (x-1)&WMASK ].value ),
				.in_right(  	 crow[ (y-0)&HMASK ].ccol[ (x+1)&WMASK ].value ),
				.in_down_left(  crow[ (y+1)&HMASK ].ccol[ (x-1)&WMASK ].value ),
				.in_down(  		 crow[ (y+1)&HMASK ].ccol[ (x-0)&WMASK ].value ),
				.in_down_right( crow[ (y+1)&HMASK ].ccol[ (x+1)&WMASK ].value ),
				.cell_life( value )
			);
			
			assign torusv[y*TORUS_WIDTH+x] = crow[ y ].ccol[ x ].value;
		end
	end
endgenerate

assign torus_last = torusv[TORUS_HEIGHT*TORUS_WIDTH-1];

endmodule

