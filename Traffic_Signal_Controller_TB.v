module stimulus;
wire [1:0] hsig,csig;
reg caroncountry,clk,clr;
signal_control DUT(hsig,csig,caroncountry,clk,clr);
initial 
$monitor("At time %t, highway=%b country=%b caroncountry=%b",$time,hsig,csig,caroncountry);
initial begin
clk = 1'b0;
forever #5 clk = ~clk;
end
initial begin
clr = 1'b1;
repeat(5) @(negedge clk);
clr = 1'b0;
end

initial begin 
    caroncountry = 1'b0;
    repeat (20) @(negedge clk);
    caroncountry = 1'b1;
    repeat (10) @(negedge clk);
    caroncountry = 1'b0;
    repeat (20) @(negedge clk);
    caroncountry = 1'b1;
    repeat (10) @(negedge clk);
    caroncountry = 1'b0;
    repeat (20) @(negedge clk);
    caroncountry = 1'b1;
    repeat (10) @(negedge clk);
    caroncountry = 1'b0;
    repeat (10) @(negedge clk);
    $stop;
end
endmodule
