`timescale 1ns / 1ns
module uart_top_tb();

parameter CLK_FRE   = 50;
parameter UART_RATE = 9600;

reg clk = 'd0;
reg [23:0] dht11_data = 24'h123456;

wire thres_en;
wire uart_tx;
reg  uart_rx = 'd1;

uart_top#(
    .CLK_FRE    (CLK_FRE        ),
    .UART_RATE  (UART_RATE      )
)uart_top_m0(
    .clk        (clk            ),

    .dht11_data (dht11_data     ),
    .thres_en   (thres_en       ),

    .uart_rx    (uart_rx        ),
    .uart_tx    (uart_tx        )
);

always #10 clk = ~clk;

initial #1000000 $stop;

endmodule 