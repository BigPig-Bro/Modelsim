module median_filter(
    //时钟
    input       clk             ,  //50MHz
    input       rst_n           ,
    
    //处理前图像数据
    input       per_frame_vsync  ,   //处理前图像数据场信号
    input       per_frame_href   ,   //处理前图像数据行信号 
    input [7:0] per_img_y        ,   //灰度数据             
    
    //处理后的图像数据
    output       pos_frame_vsync,   //处理后的图像数据场信号   
    output       pos_frame_href ,   //处理后的图像数据行信号  
    output [7:0] pos_img_y          //处理后的灰度数据           
);

//wire define
wire        matrix_frame_vsync;
wire        matrix_frame_href;
wire [7:0]  matrix_p11; //3X3 阵列输出
wire [7:0]  matrix_p12; 
wire [7:0]  matrix_p13;
wire [7:0]  matrix_p21; 
wire [7:0]  matrix_p22; 
wire [7:0]  matrix_p23;
wire [7:0]  matrix_p31; 
wire [7:0]  matrix_p32; 
wire [7:0]  matrix_p33;
wire [7:0]  mid_value;

//*****************************************************
//**                    main code
//*****************************************************


matrix_generate_3x3 #(
	.DATA_WIDTH         (8                  ),
	.DATA_DEPTH         (640                )
)u_matrix_generate_3x3(
    .clk                (clk                ), 
    .rst_n              (rst_n              ),
    
    
    .per_frame_vsync    (per_frame_vsync    ),
    .per_frame_href     (per_frame_href     ), 
    .per_img_y          (per_img_y          ),
    
    
    .matrix_frame_vsync (matrix_frame_vsync ),
    .matrix_frame_href  (matrix_frame_href  ),
    .matrix_p11         (matrix_p11         ),    
    .matrix_p12         (matrix_p12         ),    
    .matrix_p13         (matrix_p13         ),
    .matrix_p21         (matrix_p21         ),    
    .matrix_p22         (matrix_p22         ),    
    .matrix_p23         (matrix_p23         ),
    .matrix_p31         (matrix_p31         ),    
    .matrix_p32         (matrix_p32         ),    
    .matrix_p33         (matrix_p33         )
);

//3x3阵列的中值滤波，需要3个时钟
median_filter_3x3 u_median_filter_3x3(
    .clk                (clk),
    .rst_n              (rst_n),
    
    .median_frame_vsync (matrix_frame_vsync),
    .median_frame_href  (matrix_frame_href),
    
    //第一行
    .data11           (matrix_p11), 
    .data12           (matrix_p12), 
    .data13           (matrix_p13),
    //第二行              
    .data21           (matrix_p21), 
    .data22           (matrix_p22), 
    .data23           (matrix_p23),
    //第三行              
    .data31           (matrix_p31), 
    .data32           (matrix_p32), 
    .data33           (matrix_p33),
    
    .pos_median_vsync (pos_frame_vsync  ),
    .pos_median_href  (pos_frame_href   ),
    .target_data      (pos_img_y        )
);

endmodule 