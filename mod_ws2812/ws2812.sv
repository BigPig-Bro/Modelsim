module ws2812 #(
	parameter CLK_FRE = 50
)(
	input 		clk,  //输入 时钟源  

	input 		thres_en,

	output reg ws2812_di //输出到WS2812的接口
);
parameter WS2812_NUM 	= 8  - 1     ; // WS2812的LED数量
parameter WS2812_WIDTH 	= 24 	     ; // WS2812的数据位宽

parameter DELAY_1_HIGH 	= CLK_FRE * 1000000 / 1_000_000_0 * 8 - 1; //800ns≈850ns±150ns    1 高电平时间
parameter DELAY_1_LOW 	= CLK_FRE * 1000000 / 1_000_000_0 * 4 - 1; //≈400ns±150ns 		1 低电平时间
parameter DELAY_0_HIGH 	= CLK_FRE * 1000000 / 1_000_000_0 * 4 - 1; //≈400ns±150ns 		0 高电平时间
parameter DELAY_0_LOW 	= CLK_FRE * 1000000 / 1_000_000_0 * 8 - 1; //800ns≈850ns±150ns    0 低电平时间
parameter DELAY_RESET 	= CLK_FRE * 1000000 / 1_000 - 1; //1ms 复位时间 ＞280us
 
parameter WAIT_DELAY 	= CLK_FRE * 1000000 / 5;//每个刷新周期的间隔 0.2S

parameter RESET 	 		= 0; //状态机声明
parameter DATA_SEND  		= 1;
parameter BIT_SEND_HIGH   	= 2;
parameter BIT_SEND_LOW   	= 3;
parameter WAIT   			= 4;

reg [ 2:0] state       = 0 ; //主状态机控制
reg [ 4:0] bit_send    = 0; //数据数量发送控制
reg [ 7:0] data_send   = 0; //数据位发送控制
reg [31:0] clk_delay   = 0; //延时控制
reg [23:0] WS2812_data = 24'h1; // WS2812的颜色数据 G B R

always@(posedge clk)
	case (state)
		RESET:begin
			ws2812_di <= 0;
			if (clk_delay < DELAY_RESET) 
				clk_delay <= clk_delay + 1;
			else begin
				clk_delay <= 0;
				state <= DATA_SEND;
			end
		end

		DATA_SEND:
			if (data_send == WS2812_NUM && bit_send == WS2812_WIDTH)begin 
				data_send <= 0;
				bit_send  <= 0;
				state <= WAIT;
			end 
			else if (bit_send < WS2812_WIDTH) 
				state    <= BIT_SEND_HIGH;
			else begin// if (bit_send == WS2812_WIDTH)
				data_send <= data_send + 1;
				bit_send  <= 0;
				state    <= BIT_SEND_HIGH;
			end
			
		BIT_SEND_HIGH:begin
			ws2812_di <= 1;
			if (WS2812_data[23 - bit_send]) 
				if (clk_delay < DELAY_1_HIGH)
					clk_delay <= clk_delay + 1;
				else begin
					clk_delay <= 0;
					state    <= BIT_SEND_LOW;
				end
			else 
				if (clk_delay < DELAY_0_HIGH)
					clk_delay <= clk_delay + 1;
				else begin
					clk_delay <= 0;
					state    <= BIT_SEND_LOW;
				end
		end

		BIT_SEND_LOW:begin
			ws2812_di <= 0;
			if (WS2812_data[bit_send]) 
				if (clk_delay < DELAY_1_LOW) 
					clk_delay <= clk_delay + 1;
				else begin
					clk_delay <= 0;
					bit_send <= bit_send + 1;
					state    <= DATA_SEND;
				end
			else 
				if (clk_delay < DELAY_0_LOW) 
					clk_delay <= clk_delay + 1;
				else begin
					clk_delay <= 0;
					bit_send <= bit_send + 1;
					state    <= DATA_SEND;
				end
		end

		WAIT:begin
			if(clk_delay < WAIT_DELAY) clk_delay <= clk_delay + 1;
			else begin
				WS2812_data <= thres_en? 24'H030000 : 24'H000300;//颜色显示

				state <= RESET;
			end
		end
	endcase
endmodule