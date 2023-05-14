module ws2812_tb ();

parameter CLK_FRE = 50; //100M
reg clk = 'd0;
reg thres_en = 'd0;
wire ws2812_di;

ws2812#(
    .CLK_FRE   (CLK_FRE        )
)ws2812_m0(
    .clk       (clk            ),

    .thres_en  (thres_en       ), //开关量 1 显示颜色1  0 显示颜色2

    .ws2812_di (ws2812_di      )
);

initial forever #10 clk = ~clk;

initial #5000000 thres_en = 'd1;

initial #10000000 $stop;

endmodule