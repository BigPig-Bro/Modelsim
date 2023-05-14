module seg_top_tb ();

reg clk;
wire seg_led;
wire [2:0] seg_sel;
wire [7:0] seg_dig;

seg_top seg_top_m0(
    .clk        (clk         ),

    .data_in    (24'h001234    ),

    .seg_led    (seg_led     ),
    .seg_sel    (seg_sel     ),
    .seg_dig    (seg_dig     )
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial #10000 $stop;

endmodule