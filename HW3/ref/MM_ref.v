`timescale 1ns/10ps
module MM( in_data, col_end, row_end, is_legal, out_data, rst, clk , change_row, valid, busy);
input           clk;
input           rst;
input           col_end;
input           row_end;
input      [7:0]     in_data;

output reg signed [19:0]   out_data;
output is_legal;
output reg change_row,valid,busy;
reg signed [7:0] mx1[15:0],mx2[15:0];
reg [3:0] mx1_row, mx2_row, mx1_col, mx2_col, cnt, mx1_col_cnt, mx1_row_cnt, mx2_col_cnt, mx2_row_cnt;
reg [2:0] cur,nxt;


assign is_legal = (mx1_col == mx2_row);
assign done = ((mx1_col_cnt == mx1_col - 1 && mx1_row_cnt == mx1_row - 1) &&(mx2_col_cnt == mx2_col - 1 && mx2_row_cnt == mx2_row - 1));
wire signed [15:0] temp_sum = mx1[mx1_row_cnt * mx1_col + mx1_col_cnt] * mx2[mx2_row_cnt * mx2_col + mx2_col_cnt];

parameter 
load_mx1 = 0,
load_mx2 = 1,
calculate = 2,
hold = 3,
not_legal = 4,
finish = 5;


// Next State
always @(*) begin
    case(cur)
        load_mx1:
            nxt = (row_end)?load_mx2:load_mx1;

        load_mx2:
            nxt = (row_end)? ((mx1_col == mx2_row + 1)?calculate:not_legal) : load_mx2;  //判斷mx1的行，有沒有等於mx2的列

        calculate:
            nxt = ((mx1_col_cnt == mx1_col-1 && mx1_row_cnt == mx1_row-1) && (mx2_col_cnt == mx2_col-1 && mx2_row_cnt == mx2_row-1))? finish : ((mx1_col_cnt == mx1_col - 1)?hold:calculate);
        
        hold:
            nxt = calculate;
        
        not_legal:
            nxt = finish;
        
        finish:
            nxt = load_mx1;
    endcase
end


// Output logic & Datapath
always @(posedge clk or posedge rst) begin

    if(rst)begin
        cur <= load_mx1;
        mx1_row <= 0;
        mx2_row <= 0;
        mx1_col <= 0;
        mx2_col <= 0;
        cnt <= 0;
        mx1_row_cnt <= 0;
        mx1_col_cnt <= 0;
        mx2_row_cnt <= 0;
        mx2_col_cnt <= 0;
        out_data <= 0;
        valid <= 0;
        busy <= 0;
    end

    else begin

        cur <= nxt;

        case (cur)

            load_mx1:begin
                cnt <= cnt + 1;
                mx1[cnt] <= in_data;
                if(col_end)begin
                    if(mx1_col == 0)
                        mx1_col <= cnt + 1;
                    mx1_row <= mx1_row + 1;
                end
                if(row_end)cnt <= 0;
            end

            load_mx2:begin
                cnt <= cnt + 1;
                mx2[cnt] <= in_data;
                if(col_end)begin
                    if(mx2_col == 0)
                        mx2_col <= cnt + 1;
                    mx2_row <= mx2_row + 1;
                end
                if(row_end)busy <= 1;
            end 

            // 2 * 2         2 * 3
            // | 00 01 |    | 00 01 02|
            // | 10 11 |    | 10 11 12|

            // temp_sum = mx1[mx1_row_cnt * mx1_col + mx1_col_cnt] * mx2[mx2_row_cnt * mx2_col + mx2_col_cnt];
            calculate:begin
                out_data <= out_data + temp_sum;

                //若 mx2_col_cnt 和 mx2_row_cnt 都到達了各自的最大值(矩陣的最右下角元素)，表示完成了一整行的計算
                if(mx2_col_cnt == mx2_col-1 && mx2_row_cnt == mx2_row-1)
                    change_row <= 1;
                else change_row <= 0;


                // 如果 mx2_row_cnt 和 mx2_col_cnt 都到達了各自的最大值，則重置 mx2_row_cnt 和 mx2_col_cnt 並增加 mx1_row_cnt，表示完成了一整行的計算並移動到下一行。
                // Ex: ([0]0*02 + [0]1*12) => ([1]0*00 + [1]1*10)
                if(mx2_col_cnt == mx2_col-1 && mx2_row_cnt == mx2_row-1)begin
                    mx2_row_cnt <= 0;
                    mx2_col_cnt <= 0;
                    mx1_row_cnt <= mx1_row_cnt + 1;  //往下移動
                    valid = 1; // 計算完輸出
                end
                
                // 如果 mx2_row_cnt 到達最大值但 mx2_col_cnt 沒有，則重置 mx2_row_cnt 並增加 mx2_col_cnt，表示完成了一列的計算並移動到下一列。
                // Ex: (00*0[0] + 01*1[0])=>00  、 (00*0[1] + 01*1[1])=>01 、 (00*0[2] + 01*1[2])=>02
                else if(mx2_row_cnt == mx2_row-1)begin  
                    mx2_row_cnt <= 0;
                    mx2_col_cnt <= mx2_col_cnt + 1; //往右移動
                    valid = 1;  // 計算完輸出
                end

                // 僅增加 mx2_row_cnt 以進行下一個元素的計算。
                // Ex: (00*[0]0 + 01*[1]0)=>00 
                else begin
                    mx2_row_cnt <= mx2_row_cnt + 1; 
                end

                // 如果 mx1_col_cnt 到達最大值，則重置為 0，否則增加 mx1_col_cnt。
                if(mx1_col_cnt == mx1_col -1)begin
                    mx1_col_cnt <= 0;
                end

                else mx1_col_cnt <= mx1_col_cnt + 1;
            end

            hold:begin
                out_data <= 0;
                valid <= 0;
            end

            not_legal:begin
                valid <= 1;
            end
            
            finish:begin
                valid <= 0;
                mx1_row <= 0;
                mx2_row <= 0;
                mx1_col <= 0;
                mx2_col <= 0;
                cnt <= 0;
                mx1_row_cnt <= 0;
                mx1_col_cnt <= 0;
                mx2_row_cnt <= 0;
                mx2_col_cnt <= 0;
                out_data <= 0;
                busy <= 0;
            end

        endcase
    end
end
endmodule
