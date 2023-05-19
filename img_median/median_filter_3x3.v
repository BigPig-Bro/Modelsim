module median_filter_3x3(
    input       clk,
    input       rst_n,
    input       median_frame_vsync,
    input       median_frame_href,
   
    input [7:0]  data11, 
    input [7:0]  data12, 
    input [7:0]  data13,
    input [7:0]  data21, 
    input [7:0]  data22, 
    input [7:0]  data23,
    input [7:0]  data31, 
    input [7:0]  data32, 
    input [7:0]  data33,
   
    output [7:0] target_data,
    output       pos_median_vsync,
    output       pos_median_href
);


//=====================  第一级流水线 ================================

wire [7:0] max1, mid1, min1;
wire [7:0] max2, mid2, min2;
wire [7:0] max3, mid3, min3;
// sort of 3x3 line1
sort_3 inst_sort_3_11(
    .clk   (clk),
    .rst_n (rst_n),
    .data1 (data11),
    .data2 (data12),
    .data3 (data13),
    .max   (max1),
    .mid   (mid1),
    .min   (min1)
);

// sort of 3x3 line2
sort_3 inst_sort_3_12(
    .clk   (clk),
    .rst_n (rst_n),
    .data1 (data21),
    .data2 (data22),
    .data3 (data23),
    .max   (max2),
    .mid   (mid2),
    .min   (min2)
);

// sort of 3x3 line3
sort_3 inst_sort_3_13(
    .clk   (clk),
    .rst_n (rst_n),
    .data1 (data31),
    .data2 (data32),
    .data3 (data33),
    .max   (max3),
    .mid   (mid3),
    .min   (min3)
);
//==================== 第二级流水线  =================================
wire [7:0] min_of_max,mid_of_mid, max_of_min;
// min of max1 max2 max3
sort_3 inst_sort_3_21(
    .clk   (clk),
    .rst_n (rst_n),
    .data1 (max1),
    .data2 (max2),
    .data3 (max3),
    .max   (),
    .mid   (),
    .min   (min_of_max)
);

// mid of mid1 mid2 mid3
sort_3 inst_sort_3_22(
    .clk   (clk),
    .rst_n (rst_n),
    .data1 (mid1),
    .data2 (mid2),
    .data3 (mid3),
    .max   (),
    .mid   (mid_of_mid),
    .min   ()
);

// max of min1 min2 min3
sort_3 inst_sort_3_23(
    .clk   (clk),
    .rst_n (rst_n),
    .data1 (min1),
    .data2 (min2),
    .data3 (min3),
    .max   (max_of_min),
    .mid   (),
    .min   ()
);
//================= 第三级流水线  ====================================
wire [7:0] mid_of_nine;
sort_3 inst_sort_3_3(
    .clk   (clk),
    .rst_n (rst_n),
    .data1 (min_of_max),
    .data2 (mid_of_mid),
    .data3 (max_of_min),
    .max   (),
    .mid   (mid_of_nine),
    .min   ()
);


reg [7:0] median_value;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        median_value <= 0;
    end
    else begin
        median_value <= mid_of_nine;
    end
end

//reg define
reg     [ 1 : 0]    median_frame_vsync_r;
reg     [ 1 : 0]    median_frame_href_r;


//*****************************************************
//**                    main code
//*****************************************************

assign  pos_median_vsync    =   median_frame_vsync_r[1];
assign  pos_median_href     =   median_frame_href_r [1];
assign  target_data         =   median_value;

//延迟三个周期进行同步
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        median_frame_vsync_r <= 0;
        median_frame_href_r  <= 0;
    end
    else begin
        median_frame_vsync_r <= {median_frame_vsync_r[0],median_frame_vsync};
        median_frame_href_r  <= {median_frame_href_r [0], median_frame_href};
    end
end

endmodule 