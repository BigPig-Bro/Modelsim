`timescale 1ns / 1ns
module bmp_sim_tb();
/********************************************************************************/
/*********************    文件读写及驱动时钟       *******************************/
/********************************************************************************/
integer iBmpFileId;                 //输入BMP图片
integer oBmpFileId;                 //输出BMP图片 
integer oIndex = 0;                 //输出BMP数据索引  
integer iCode;       				//0表示读取成功，-1表示读取失败    
integer iBmpWidth;                  //输入BMP 宽度
integer iBmpHight;                  //输入BMP 高度
integer iBmpSize;                   //输入BMP 字节数
integer iDataStartIndex;            //输入BMP 像素数据偏移量
    
reg [ 7:0] rBmpData [2000000:0];    //用于寄存输入BMP图片中的字节数据（包括54字节的文件头）
reg [ 7:0] res_data [2000000:0];    //纯图像数据
reg [ 7:0] oBmpData [2000000:0];   	//用于寄存视频图像处理之后 的BMP图片 数据  
reg [31:0] rBmpWord;                //输出BMP图片时用于寄存数据（以word为单位，即4byte）

reg clk = 0;
reg rst_n = 0;
integer i;

reg  [3:0]		frame_cnt = 'd0; //帧计数
parameter   	FRAME_READ = 1; //读取帧编号
//---------------------------------------------
initial begin
	//打开输入BMP图片
	iBmpFileId      = $fopen("D:/Users/HUIP/Desktop/img_median/test.bmp","rb");	
	if(iBmpFileId)	$display("open input file success");
	else			$display("open input file fail");

	//将输入BMP图片加载到数组中 
	iCode = $fread(rBmpData,iBmpFileId);

	//根据BMP图片文件头的格式，分别计算出图片的 宽度 /高度 /像素数据偏移量 /图片字节数
	iBmpWidth       = {rBmpData[21],rBmpData[20],rBmpData[19],rBmpData[18]};
	iBmpHight       = {rBmpData[25],rBmpData[24],rBmpData[23],rBmpData[22]};
	iBmpSize        = {rBmpData[ 5],rBmpData[ 4],rBmpData[ 3],rBmpData[ 2]};
	iDataStartIndex = {rBmpData[13],rBmpData[12],rBmpData[11],rBmpData[10]};
	
	//关闭输入BMP图片
	$fclose(iBmpFileId);
end

always@(posedge clk) begin
	//延迟，等待第一帧处理结束
	if(frame_cnt == FRAME_READ + 1) begin  	
		//打开输出BMP图片
		oBmpFileId = $fopen("D:/Users/HUIP/Desktop/img_median/median.bmp","wb+");	
		if(oBmpFileId)	$display("open output file success");
		else			$display("open output file fail");

		//输出第一张
		for (oIndex = 0; oIndex < iBmpSize; oIndex = oIndex + 1) begin
			if(oIndex < 54)
				oBmpData[oIndex] = rBmpData[oIndex];
			else
				oBmpData[oIndex] = res_data[oIndex-54];
		end
		//将数组中的数据写到输出BMP图片中    
		for (oIndex = 0; oIndex < iBmpSize; oIndex = oIndex + 4) begin
			rBmpWord = {oBmpData[oIndex+3],oBmpData[oIndex+2],oBmpData[oIndex+1],oBmpData[oIndex]};
			$fwrite(oBmpFileId,"%u",rBmpWord);
		end
		//关闭输入BMP图片
		$fclose(oBmpFileId);

		$stop;
	end
end

//初始化时钟和复位信号
initial #110 rst_n   = 1;
always  #10  clk = ~clk;

/********************************************************************************/
/************************      模拟摄像头时序       *****************************/
/********************************************************************************/
wire		cmos_vsync ;
reg			cmos_href;
reg	[15:0]	cmos_data;
wire[31:0] 	cmos_index;	

cmos_cam cmos_cam_m0(
	.clk 				(clk 				),
    .rst_n              (rst_n				),

	.cmos_href			(cmos_href			),
	.cmos_vsync			(cmos_vsync			),
	.cmos_index 		(cmos_index			)
);

always@(posedge clk or negedge rst_n)  
	cmos_data    <=  {rBmpData[cmos_index][7:3], rBmpData[cmos_index + 1][7:2], rBmpData[cmos_index + 2][7:3]};

/********************************************************************************/
/************************       用户逻辑时序        *****************************/
/********************************************************************************/
wire        		median_vsync			;
wire        		median_href			;
wire        [7:0]	median_data    		;

median_filter u_median_filter(
    //global clock
    .clk                (clk				),
    .rst_n              (rst_n				),
    
    //Image data prepred to be processd
    .per_frame_vsync  	(cmos_vsync			), 
    .per_frame_href   	(cmos_href 			), 
    .per_img_y        	({cmos_data[4:0],3'd0}), //灰度图片输入，3个字节同值，取一个即可
    
    //Image data has been processd
    .pos_frame_vsync   	(median_vsync		), 
    .pos_frame_href    	(median_href		), 
    .pos_img_y         	(median_data    	) 
);

/********************************************************************************/
/************************       用户数据保存        *****************************/
/********************************************************************************/
wire        		out_vs    		;   
wire        		out_de     		;   
wire        [7:0]	out_img_R     	;   
wire        [7:0]	out_img_G     	;   
wire        [7:0]	out_img_B     	;  


//选择输出的图像数据
assign out_vs 		= 	median_vsync	;   
assign out_de  		= 	median_href 	;   
assign out_img_R    = 	median_data		;   
assign out_img_G    = 	median_data		;   
assign out_img_B    = 	median_data		; 

//寄存图像处理之后的像素数据
reg [31:0]  out_cnt;
always@(posedge out_vs)
    frame_cnt    <=  frame_cnt +  'd1;

always@(posedge clk or negedge rst_n)
   if(!rst_n) 
        out_cnt <=  32'd0;
   else if(frame_cnt == FRAME_READ) 
        if(out_de) begin
            out_cnt <=  out_cnt + 3;
            res_data[out_cnt+0] <= out_img_R;
            res_data[out_cnt+1] <= out_img_G;
            res_data[out_cnt+2] <= out_img_B;
        end
endmodule 