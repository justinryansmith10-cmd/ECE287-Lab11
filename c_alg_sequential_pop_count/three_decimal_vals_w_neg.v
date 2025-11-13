module three_decimal_vals_w_neg (
input [7:0]val,
output [6:0]seg7_neg_sign,
output [6:0]seg7_dig0,
output [6:0]seg7_dig1,
output [6:0]seg7_dig2
);

reg [3:0] result_one_digit;
reg [3:0] result_ten_digit;
reg [3:0] result_hundred_digit;
reg result_is_negative;

reg [7:0]twos_comp;

/* convert the binary value into 4 signals */


endmodule