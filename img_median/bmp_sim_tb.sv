`timescale 1ns / 1ns
module bmp_sim_tb();
 
integer iBmpFileId;                 //输入BMP图片

integer oBmpFileId;                 //输出BMP图片 

integer oIndex = 0;                 //输出BMP数据索引
integer pixel_index = 0;            //输出像素数据索引 
        
integer iCode;       				//0
        
integer iBmpWidth;                  //输入BMP 宽度
integer iBmpHight;                  //输入BMP 高度
integer iBmpSize;                   //输入BMP 字节数
integer iDataStartIndex;            //输入BMP 像素数据偏移量
    
reg [ 7:0] rBmpData [0:2000000];    //用于寄存输入BMP图片中的字节数据（包括54字节的文件头）

reg [ 7:0] res_data [0:2000000];      //640x480x3 纯图像数据
reg [ 7:0] oBmpData [0:2000000];   	//用于寄存视频图像处理之后 的BMP图片 数据  

reg [31:0] rBmpWord;                //输出BMP图片时用于寄存数据（以word为单位，即4byte）

reg [ 7:0] pixel_data;              //输出视频流时的像素数据

reg clk;
reg rst_n;

integer i;
//---------------------------------------------
initial begin
	//打开输入BMP图片
	iBmpFileId      = $fopen("D:/Users/HUIP/Desktop/sim_median/test.bmp","rb");	
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

//---------------------------------------------		
	//延迟14ms，等待第一帧处理结束
	#14000000    	
//---------------------------------------------	
	//打开输出BMP图片
	oBmpFileId = $fopen("D:/Users/HUIP/Desktop/sim_median/median.bmp","wb+");	
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
//initial end
//--------------------------------------------- 
end

//---------------------------------------------		
//初始化时钟和复位信号
initial begin
    clk     = 1;
    rst_n   = 0;
    #110
    rst_n   = 1;
end 

//产生50MHz时钟
always #10 clk = ~clk;
 
//---------------------------------------------		
//在时钟驱动下，从数组中读出像素数据，用于在Modelsim中查看BMP中的数据 
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        pixel_data  <=  8'd0;
        pixel_index <=  0;
    end
    else begin
        pixel_data  <=  rBmpData[pixel_index];
        pixel_index <=  pixel_index+1;
    end
end
 
//---------------------------------------------
//产生摄像头时序 
wire		cmos_vsync ;
reg			cmos_href;
wire        cmos_clken;
reg	[23:0]	cmos_data;	
		 
reg         cmos_clken_r;

reg [31:0]  cmos_index;

parameter [10:0] IMG_HDISP = 11'd640;
parameter [10:0] IMG_VDISP = 11'd480;

localparam H_SYNC = 11'd10;		
localparam H_BACK = 11'd10;		
localparam H_DISP = IMG_HDISP;	
localparam H_FRONT = 11'd10;		
localparam H_TOTAL = H_SYNC + H_BACK + H_DISP + H_FRONT;	

localparam V_SYNC = 11'd10;		
localparam V_BACK = 11'd10;		
localparam V_DISP = IMG_VDISP;	
localparam V_FRONT = 11'd10;		
localparam V_TOTAL = V_SYNC + V_BACK + V_DISP + V_FRONT;

//---------------------------------------------
//模拟 驱动模块输出的时钟使能
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cmos_clken_r <= 0;
	else
        cmos_clken_r <= ~cmos_clken_r;
end

//---------------------------------------------
//水平计数器
reg	[10:0]	hcnt;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		hcnt <= 11'd0;
	else if(cmos_clken_r) 
		hcnt <= (hcnt < H_TOTAL - 1'b1) ? hcnt + 1'b1 : 11'd0;
end

//---------------------------------------------
//竖直计数器
reg	[10:0]	vcnt;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		vcnt <= 11'd0;		
	else if(cmos_clken_r) begin
		if(hcnt == H_TOTAL - 1'b1)
			vcnt <= (vcnt < V_TOTAL - 1'b1) ? vcnt + 1'b1 : 11'd0;
		else
			vcnt <= vcnt;
    end
end

//---------------------------------------------
//场同步
reg	cmos_vsync_r;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cmos_vsync_r <= 1'b0;			//H: Vaild, L: inVaild
	else begin
		if(vcnt <= V_SYNC - 1'b1)
			cmos_vsync_r <= 1'b0; 	//H: Vaild, L: inVaild
		else
			cmos_vsync_r <= 1'b1; 	//H: Vaild, L: inVaild
    end
end
assign	cmos_vsync	= cmos_vsync_r;

//---------------------------------------------
//行有效
wire	frame_valid_ahead =  ( vcnt >= V_SYNC + V_BACK  && vcnt < V_SYNC + V_BACK + V_DISP
                            && hcnt >= H_SYNC + H_BACK  && hcnt < H_SYNC + H_BACK + H_DISP ) 
						? 1'b1 : 1'b0;
      
reg			cmos_href_r;      
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cmos_href_r <= 0;
	else begin
		if(frame_valid_ahead)
			cmos_href_r <= 1;
		else
			cmos_href_r <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cmos_href <= 0;
	else
        cmos_href <= cmos_href_r;
end

assign cmos_clken = cmos_href & cmos_clken_r;

//-------------------------------------
//从数组中以视频格式输出像素数据
wire [10:0] x_pos;
wire [10:0] y_pos;

assign x_pos = frame_valid_ahead ? (hcnt - (H_SYNC + H_BACK )) : 0;
assign y_pos = frame_valid_ahead ? (vcnt - (V_SYNC + V_BACK )) : 0;

always@(posedge clk or negedge rst_n)begin
   if(!rst_n) begin
       cmos_index   <=  0;
       cmos_data    <=  24'd0;
   end
   else begin
       cmos_index   <=  y_pos * 1920  + x_pos*3 + 54;         //  3*(y*640 + x) + 54
       cmos_data    <=  {rBmpData[cmos_index], rBmpData[cmos_index+1] , rBmpData[cmos_index+2]};
   end
end

//-------------------------------------
//median filter
wire        		median_vsync		;
wire        		median_href			;
wire        		median_clken   		;
wire        [7:0]	median_data    		;

median_filter u_median_filter(
    //global clock
    .clk                (clk				),
    .rst_n              (rst_n				),
    
    //Image data prepred to be processd
    .per_frame_vsync  	(cmos_vsync			), 
    .per_frame_href   	(cmos_href 			), 
    .per_frame_clken  	(cmos_clken			), 
    .per_img_y        	(cmos_data[7:0] 	), //灰度图片输入，3个字节同值，取一个即可
    
    //Image data has been processd
    .pos_frame_vsync   	(median_vsync		), 
    .pos_frame_href    	(median_href		), 
    .pos_frame_clken   	(median_clken   	), 
    .pos_img_y         	(median_data    	) 
);

//-------------------------------------
wire        		out_vsync    ;   
wire        		out_href     ;   
wire        		out_clken    ;    
wire        [7:0]	out_img_R     ;   
wire        [7:0]	out_img_G     ;   
wire        [7:0]	out_img_B     ;  

//选择输出的图像数据
assign out_vsync 	= 	median_vsync	;   
assign out_href  	= 	median_href 	;   
assign out_clken 	= 	median_clken	;  
assign out_img_R    = 	median_data 	;   
assign out_img_G    = 	median_data		;   
assign out_img_B    = 	median_data		; 

//寄存图像处理之后的像素数据
reg [31:0]  out_cnt;
reg         out_vsync_r;    //寄存输出的场同步 
reg         out_en;     //寄存处理图像的使能信号，仅维持一帧的时间

always@(posedge clk or negedge rst_n)
   if(!rst_n) 
        out_vsync_r   <=  1'b0;
   else 
        out_vsync_r   <=  out_vsync;

always@(posedge clk or negedge rst_n)
   if(!rst_n) 
        out_en    <=  1'b1;
   else if(out_vsync_r & (!out_vsync))  //第一帧结束之后，使能拉低
        out_en    <=  1'b0;

always@(posedge clk or negedge rst_n)begin
   if(!rst_n) begin
        out_cnt <=  32'd0;
   end
   else if(out_en) begin
        if(out_href & out_clken) begin
            out_cnt <=  out_cnt + 3;
            res_data[out_cnt+0] <= out_img_R;
            res_data[out_cnt+1] <= out_img_G;
            res_data[out_cnt+2] <= out_img_B;
        end
   end
end
endmodule 