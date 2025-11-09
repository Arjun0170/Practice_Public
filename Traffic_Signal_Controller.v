`define TRUE  1'b1
`define FALSE  1'b0
`define Y2R_DELAY 3
`define R2G_DELAY  2

module signal_control(highway,country,x,clk,clr);
output reg [1:0] highway,country;
input x,clk,clr;
parameter red = 2'd0, green = 2'd2, yellow = 2'd1;

parameter S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4;
reg [3:0] state, next_state;

always @(posedge clk)
    if (clr)
    state <= S0;
    else
    state <= next_state;
always @(state)
begin 
    highway = green;
    country = red;
    case (state)
    S0:;
    S1: highway = yellow;
    S2: highway = red;
    S3: begin highway = red; country = green; end
    S4: begin highway = red; country = yellow; end
    endcase
end
always @(state or x)
begin
    case (state)
    S0: next_state = x ? S1 : S0;
    S1: begin 
        repeat (`Y2R_DELAY) @(posedge clk);
        next_state = S2;
    end
    S2: begin 
        repeat (`R2G_DELAY) @(posedge clk);
        next_state = S3;
    end
    S3: next_state = x ? S3 : S4;
    S4: begin 
        repeat (`Y2R_DELAY) @(posedge clk);
        next_state = S0;
    end
    default: next_state = S0;
    endcase
end 
endmodule
