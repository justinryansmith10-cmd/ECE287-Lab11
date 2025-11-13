module pop_count_sequential(
	input clk, 
	input rst, 
	input [9:0]input_number,
	input start,
	output reg [7:0]count,
	output reg done
);

reg [3:0] i; // counter
reg [3:0] S;
reg [3:0] NS;
	parameter WIDTH = 10;

	parameter LOAD  = 4'd2,
			  SHIFT = 4'd3,
			  INC   = 4'd4,
			  DONE  = 4'd5;

	reg [9:0] shift_reg;

	// synchronous state register and sequential updates
	always @(posedge clk or posedge rst) begin
		if (rst) begin
			S <= START;
			i <= 4'd0;
			count <= 8'd0;
			shift_reg <= {WIDTH{1'b0}};
			done <= 1'b0;
		end else begin
			S <= NS;
			case (S)
				LOAD: begin
					// load inputs on LOAD state
					shift_reg <= input_number;
					count <= 8'd0;
					i <= 4'd0;
					done <= 1'b0;
				end
				SHIFT: begin
					// perform right shift
					shift_reg <= shift_reg >> 1;
					i <= i + 1'b1;
				end
				INC: begin
					// increment count when LSB was 1
					count <= count + 1'b1;
				end
				DONE: begin
					done <= 1'b1;
				end
				default: begin
					// keep registers
				end
			endcase
		end
	end

	// next-state logic (combinational)
	always @(*) begin
		NS = S;
		case (S)
			START: begin
				if (start)
					NS = LOAD;
				else
					NS = START;
			end
			LOAD: begin
				NS = CHECK;
			end
			CHECK: begin
				if (i == WIDTH)
					NS = DONE;
				else begin
					// if LSB is 1, count on INC state, otherwise shift directly
					if (shift_reg[0])
						NS = INC;
					else
						NS = SHIFT;
				end
			end
			INC: begin
				// after increment, move to SHIFT
				NS = SHIFT;
				// increment handled in SHIFT state (sequentially)
			end
			SHIFT: begin
				// after shifting, increment loop counter (sequentially on next clock); go back to CHECK
				NS = CHECK;
			end
			DONE: begin
				if (!start)
					NS = START;
				else
					NS = DONE;
			end
			default: NS = START;
		endcase
	end

	// increment loop counter as part of SHIFT state (inside the main sequential block)

endmodule
