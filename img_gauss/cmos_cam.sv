module cmos_cam(
    input                    clk,
    input 					 rst_n,

    output reg          cmos_href,
    output reg          cmos_vsync,
	output reg [31:0]   cmos_index
); 

//800x480
parameter H_ACTIVE = 16'd800; 
parameter H_FP = 16'd40;      
parameter H_SYNC = 16'd128;   
parameter H_BP = 16'd88;      
parameter V_ACTIVE = 16'd480; 
parameter V_FP  = 16'd1;     
parameter V_SYNC  = 16'd3;    
parameter V_BP  = 16'd21;    
parameter HS_POL = 'b0;
parameter VS_POL = 'b0;

localparam V_TOTAL = V_SYNC + V_BP + V_ACTIVE + V_FP;
localparam H_TOTAL = H_SYNC + H_BP + H_ACTIVE + H_FP;	
//---------------------------------------------
//水平计数器
reg	[10:0]	hcnt;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		hcnt <= 11'd0;
	else 
		hcnt <= (hcnt < H_TOTAL - 1'b1) ? hcnt + 1'b1 : 11'd0;
end

//---------------------------------------------
//竖直计数器
reg	[10:0]	vcnt;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		vcnt <= 11'd0;		
	else begin
		if(hcnt == H_TOTAL - 1'b1)
			vcnt <= (vcnt < V_TOTAL - 1'b1) ? vcnt + 1'b1 : 11'd0;
		else
			vcnt <= vcnt;
    end
end

//---------------------------------------------
//场同步
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cmos_vsync <= VS_POL;			//H: Vaild, L: inVaild
	else begin
		if(vcnt <= V_SYNC - 1'b1)
			cmos_vsync <= VS_POL; 	//H: Vaild, L: inVaild
		else
			cmos_vsync <= ~VS_POL; 	//H: Vaild, L: inVaild
    end
end

//---------------------------------------------
//行有效
wire	cmos_href_ahead =  ( vcnt >= V_SYNC + V_BP  && vcnt < V_SYNC + V_BP + V_ACTIVE
                            && hcnt >= H_SYNC + H_BP  && hcnt < H_SYNC + H_BP + H_ACTIVE ) 
						    ? 1'b1 : 1'b0;
      
reg			cmos_href_r;      
always@(posedge clk or negedge rst_n) 
	if(!rst_n)
		cmos_href_r <= 0;
	else 
		if(cmos_href_ahead)
			cmos_href_r <= 1;
		else
			cmos_href_r <= 0;

always@(posedge clk or negedge rst_n) 
	if(!rst_n)
		cmos_href <= 0;
	else
        cmos_href <= cmos_href_r;

//-------------------------------------
//从数组中以视频格式输出像素数据
wire [10:0] x_pos;
wire [10:0] y_pos;

assign x_pos = cmos_href_ahead ? (hcnt - (H_SYNC + H_BP )) : 0;
assign y_pos = cmos_href_ahead ? (vcnt - (V_SYNC + V_BP )) : 0;

always@(posedge clk or negedge rst_n)begin
   if(!rst_n) begin
       cmos_index   <=  0;
   end
   else begin
       cmos_index   <=  y_pos * H_ACTIVE * 3  + x_pos * 3 + 54; 
   end
end

endmodule