module sort_3(
    input clk,
    input rst_n,
    input [7:0] data1, data2, data3,
    output reg [7:0] max, mid, min
);
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            max <= 0;
            mid <= 0;
            min <= 0;
        end else begin
            // max
            if(data1 >= data2 && data1 >= data3)
                max <= data1;
            else if(data2 >= data1 && data2 >= data3)
                max <= data2;
            else
                max <= data3;

            // mid
            if((data1 >= data2 && data1 <= data3) || (data1 >= data3 && data1 <= data2))
                mid <= data1;
            else if((data2 >= data1 && data2 <= data3) || (data2 >= data3 && data2 <= data1))
                mid <= data2;
            else
                mid <= data3;

            // min
            if(data1 <= data2 && data1 <= data3)
                min <= data1;
            else if(data2 <= data1 && data2 <= data3)
                min <= data2;
            else
                min <= data3;
        end
    end
endmodule
