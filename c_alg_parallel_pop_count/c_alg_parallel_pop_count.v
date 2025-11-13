module c_alg_parallel_pop_count (

	//////////// ADC //////////
	//output		          		ADC_CONVST,
	//output		          		ADC_DIN,
	//input 		          		ADC_DOUT,
	//output		          		ADC_SCLK,

	//////////// Audio //////////
	//input 		          		AUD_ADCDAT,
	//inout 		          		AUD_ADCLRCK,
	//inout 		          		AUD_BCLK,
	//output		          		AUD_DACDAT,
	//inout 		          		AUD_DACLRCK,
	//output		          		AUD_XCK,

	//////////// CLOCK //////////
	//input 		          		CLOCK2_50,
	//input 		          		CLOCK3_50,
	//input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// SDRAM //////////
	//output		    [12:0]		DRAM_ADDR,
	//output		     [1:0]		DRAM_BA,
	//output		          		DRAM_CAS_N,
	//output		          		DRAM_CKE,
	//output		          		DRAM_CLK,
	//output		          		DRAM_CS_N,
	//inout 		    [15:0]		DRAM_DQ,
	//output		          		DRAM_LDQM,
	//output		          		DRAM_RAS_N,
	//output		          		DRAM_UDQM,
	//output		          		DRAM_WE_N,

	//////////// I2C for Audio and Video-In //////////
	//output		          		FPGA_I2C_SCLK,
	//inout 		          		FPGA_I2C_SDAT,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	//output		     [6:0]		HEX4,
	//output		     [6:0]		HEX5,

	//////////// IR //////////
	//input 		          		IRDA_RXD,
	//output		          		IRDA_TXD,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// PS2 //////////
	//inout 		          		PS2_CLK,
	//inout 		          		PS2_CLK2,
	//inout 		          		PS2_DAT,
	//inout 		          		PS2_DAT2,

	//////////// SW //////////
	input 		     [9:0]		SW

	//////////// Video-In //////////
	//input 		          		TD_CLK27,
	//input 		     [7:0]		TD_DATA,
	//input 		          		TD_HS,
	//output		          		TD_RESET_N,
	//input 		          		TD_VS,

	//////////// VGA //////////
	//output		          		VGA_BLANK_N,
	//output		     [7:0]		VGA_B,
	//output		          		VGA_CLK,
	//output		     [7:0]		VGA_G,
	//output		          		VGA_HS,
	//output		     [7:0]		VGA_R,
	//output		          		VGA_SYNC_N,
	//output		          		VGA_VS,

	//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_0,

	//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_1
);

//	Turn on all display
	//assign	HEX0		=	7'h00;
	//assign	HEX1		=	7'h00;
	//assign	HEX2		=	7'h00;
	//assign	HEX3		=	7'h00;
	//assign	HEX4		=	7'h00;
	//assign	HEX5		=	7'h00;
	//assign	GPIO_0		=	36'hzzzzzzzzz;
	//assign	GPIO_1		=	36'hzzzzzzzzz;
	//assign LEDR[9:0] = 10'd0;


wire [6:0]seg7_neg_sign;
wire [6:0]seg7_dig0;
wire [6:0]seg7_dig1;
wire [6:0]seg7_dig2;

assign HEX0 = seg7_dig0;
assign HEX1 = seg7_dig1;
assign HEX2 = seg7_dig2; // constant 0
assign HEX3 = seg7_neg_sign;

assign LEDR[3:0] = {rst, start, start_pop_count, done_pop_count};
assign LEDR[5:4] = display_control;
assign LEDR[9:6] = S;
	
wire [9:0]input_number;
assign input_number = SW[9:0];
wire clk;
assign clk = CLOCK_50;
wire rst;
assign rst = KEY[3];
wire start;
assign start = ~KEY[2];
wire [1:0]display_control; // {00 = sum, 1 =  }
assign display_control = KEY[1:0];

reg [31:0]count_algorithm_steps;
wire done_pop_count;

reg[7:0]to_display;
wire[7:0]output_number;

reg [2:0]S;
reg [2:0]NS;

/* signals to popcount */
reg start_pop_count; // signal to tell algorithm to start

parameter START = 3'd0,
			WAIT_FOR_INPUT_START_START = 3'd1,
			WAIT_FOR_INPUT_START_DONE = 3'd2,
			SEND_PULSE_ALGORITHM_GO = 3'd3,
			WAIT_FOR_ALGORITHM_DONE = 3'd4,
			ERROR = 3'b111;

pop_count_parallel my_pop(clk, rst, input_number, start_pop_count, output_number, done_pop_count);
			
always @(*)
begin
	case (S)
		START:
		begin
			NS = WAIT_FOR_INPUT_START_START;
		end
		WAIT_FOR_INPUT_START_START: 
		begin
			if (start == 1'b1)
				NS = WAIT_FOR_INPUT_START_DONE;
			else
				NS = WAIT_FOR_INPUT_START_START;
		end
		WAIT_FOR_INPUT_START_DONE:
		begin
			if (start == 1'b0)
				NS = SEND_PULSE_ALGORITHM_GO;
			else
				NS = WAIT_FOR_INPUT_START_DONE;
		end
		SEND_PULSE_ALGORITHM_GO:
		begin
			NS = WAIT_FOR_ALGORITHM_DONE;
		end
		WAIT_FOR_ALGORITHM_DONE:
		begin
			if (done_pop_count == 1'b1)
				NS = WAIT_FOR_INPUT_START_START;
			else
				NS = WAIT_FOR_ALGORITHM_DONE;
		end
		default NS = ERROR;
	endcase
end

always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		start_pop_count <= 1'b0;
		count_algorithm_steps <= 32'd0;
	end
	else
		case (S)
			SEND_PULSE_ALGORITHM_GO:
			begin
				start_pop_count <= 1'b1;
				count_algorithm_steps <= 32'd0;
			end
			WAIT_FOR_ALGORITHM_DONE:
			begin
				start_pop_count <= 1'b0;
				count_algorithm_steps <= count_algorithm_steps + 1'b1;
			end
		endcase
end

/* FSM init and NS always */
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		S <= START;
	end
	else
	begin
		S <= NS;
	end
end

/* instantiate display circuitry */
three_decimal_vals_w_neg display(
to_display,
seg7_neg_sign,
seg7_dig0,
seg7_dig1,
seg7_dig2
);

always @(*)
begin
	if (display_control == 2'd0)
		to_display = output_number;
	else if (display_control == 2'd1)
		to_display = count_algorithm_steps[7:0];
	else// if (display_control == 2'd1)
		to_display = 8'd42;
end
	
endmodule
