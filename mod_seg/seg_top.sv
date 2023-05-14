module seg_top#(
	parameter CLK_FRE = 50_000_000
)(
	input clk,//普通时钟信号
	input [23:0] data_in,//BCD

	output 			 seg_led,
	output reg [2:0] seg_sel = 'd0,//段选和位选信号
	output reg [7:0] seg_dig 
);
		
	assign seg_led = 1'b0;
//======================= 扫描降频 =======================================
reg [9:0] timer = 'd0;//时间计数

always@(posedge clk)//扫描模块
		timer = timer + 32'd1;

//======================= 信号编码 =======================================
reg [3:0] seg_dig_lndex;//段选查表索引
always@*//显示模块
	case(seg_sel)
		3'd7:
			seg_dig_lndex = data_in[23:20];
		
		3'd6:
			seg_dig_lndex = data_in[19:16];
		
		3'd5:
			seg_dig_lndex = data_in[15:12];
		
		3'd4:
			seg_dig_lndex = data_in[11:8];
		
		3'd3:
			seg_dig_lndex = 4'hf;//不显示
		
		3'd2:
			seg_dig_lndex = 4'hf;//不显示
		
		3'd1:
			seg_dig_lndex = data_in[7:4];
		
		3'd0:
			seg_dig_lndex = data_in[3:0];
	endcase

//======================= 信号输出 =======================================
always@*
    case(seg_dig_lndex)//以下为共阴数码管的编码
		0:seg_dig[6:0]= 7'b011_1111;
		1:seg_dig[6:0]= 7'b000_0110;
		2:seg_dig[6:0]= 7'b101_1011;
		3:seg_dig[6:0]= 7'b100_1111;
		4:seg_dig[6:0]= 7'b110_0110;
		5:seg_dig[6:0]= 7'b110_1101;
		6:seg_dig[6:0]= 7'b111_1101;
		7:seg_dig[6:0]= 7'b000_0111;
		8:seg_dig[6:0]= 7'b111_1111;
		9:seg_dig[6:0]= 7'b110_1111;
		default:seg_dig[6:0]=7'b000_0000;
	endcase

always@*
	seg_dig[7] = seg_sel == 'd6;


always@(posedge timer[9]) //循环位选
	seg_sel <= seg_sel + 3'd1;

endmodule
