`timescale 1ns/10ps
module MM( in_data, col_end, row_end, is_legal, out_data, rst, clk , change_row, valid, busy);
input           clk;
input           rst;
input           col_end;
input           row_end;
input      [7:0]in_data;

output reg signed [19:0]out_data;
output is_legal;
output reg change_row, valid, busy;

localparam [2:0] s0=3'b000;
localparam [2:0] s1=3'b001; 
localparam [2:0] s2=3'b010; 
localparam [2:0] s3=3'b011; 
localparam [2:0] s4=3'b100; 
localparam [2:0] s5=3'b101; 
localparam [2:0] s6=3'b110; 
localparam [2:0] s7=3'b111; 

//temperory registers. 
reg [2:0] currentstate, nextstate;
reg signed [7:0] matA [4:0][4:0];
reg signed [7:0] matB [4:0][4:0];
reg signed [15:0] matC [4:0][4:0];
integer i_1, j_1, i_2, j_2;  //loop indices
integer i, k, j;  //loop indices
reg first_cycle;    //indicates its the first clock cycle after Enable went High.  
reg change_mat;
reg check;
reg end_of_mult;    //indicates multiplication has ended.
reg finish;
reg is_legal_temp;
reg signed [15:0] temp; //a temeporary register to hold the product of two elements.


//Next State Logic
always @ (*) 
begin
    case (currentstate)

        //default
        s0:begin
            if(busy)
                nextstate = s0;
            else
                nextstate = s1;
        end

        // mat1 get_data  
        s1: begin
            if(change_mat == 1)
                nextstate = s2;
            else
                nextstate = s1;
        end

        // mat2 get_data  
        s2: begin
            if(first_cycle == 0)
                nextstate = s3;
            else
                nextstate = s2;
        end

        // check   
        s3: begin
            if(check == 1)
                nextstate = s4;
            else
                nextstate = s0;
        end

        // initial mat_c   
        s4: begin
            nextstate = s5;
        end

        // multiplication   
        s5: begin
            if(end_of_mult)
                nextstate = s6;
            else
                nextstate = s5;
        end
        
        // output
        s6:begin
            if(finish == 1)
                nextstate = s0;
            else
                nextstate = s6;
        end 

        default:nextstate = s0;
    endcase
end


//Output Logic
always@(posedge clk)
begin

    if (rst)
            currentstate = s0;
    else
            currentstate = nextstate;


    case (currentstate)

        s0: begin                     //default
            busy = 0;

            //Initialize
            i_1 = 0;
            j_1 = 0;
            i_2 = 0;
            j_2 = 0;
            i = 0;
            j = 0;
            k = 0;
            temp = 0;
            
            //Initialize
            change_mat = 0;
            first_cycle = 1;  
            check = 0;
            end_of_mult = 0;
            finish = 0;

            //Initialize
            valid = 0;
            change_row = 0;
            is_legal_temp = 0;
        end

        s1: begin                     //mat1 get_data
            matA[i_1][j_1] = in_data;
            j_1 = j_1 + 1;

            if(col_end==1 && row_end!=1) begin
                i_1 = i_1 + 1;
                j_1 = 0;           
            end    

            if(col_end==1 && row_end==1) begin 
                change_mat = 1;
            end           

        end

        s2: begin                     //mat2 get_data
            matB[i_2][j_2] = in_data;
            j_2 = j_2+1;

            if(col_end==1 && row_end!=1) begin
                i_2 = i_2 + 1;
                j_2 = 0;           
            end    

            if(col_end==1 && row_end==1) begin 
                first_cycle = 0;
            end           

        end

        s3:begin   // check
            if ((j_1-1) != i_2)begin
                valid = 1;
                check = 0;
                is_legal_temp = 0;

            end else
                check = 1;
        end

        s4:begin   // initial mat_c
            matC[0][0] = 16'd0;
            matC[0][1] = 16'd0;
            matC[0][2] = 16'd0;
            matC[0][3] = 16'd0;
            matC[1][0] = 16'd0;
            matC[1][1] = 16'd0;
            matC[1][2] = 16'd0;
            matC[1][3] = 16'd0;
            matC[2][0] = 16'd0;
            matC[2][1] = 16'd0;
            matC[2][2] = 16'd0;
            matC[2][3] = 16'd0;
            matC[3][0] = 16'd0;
            matC[3][1] = 16'd0;
            matC[3][2] = 16'd0;
            matC[3][3] = 16'd0;
        end


        s5: begin                     // multiplication
            temp = matA[i][k] * matB[k][j];
            matC[i][j] = matC[i][j] + temp;

            if(k == i_2) begin
                k = 0;
                if(j == (j_2-1)) begin
                    j = 0;
                    if (i == i_1) begin
                        i = 0;
                        end_of_mult = 1;
                    end
                    else
                        i = i + 1;
                end
                else
                    j = j+1;    
            end
            else
                k = k+1;
        end


        s6: begin                       // output
            valid = 1;
            is_legal_temp = 1;
            change_row = 0;
            out_data = matC[i][j];

            if (i == i_1 && j == (j_2-1)) begin
                    finish = 1;
                    i_1 = 0;
                    j_1 = 0;
                    i_2 = 0;
                    j_2 = 0;
                    change_row = 1;
                end

            if (j == (j_2-1)) begin
                j = 0;
                change_row = 1;
                if (i == i_1) begin
                end

                else
                    i = i + 1;
            end
            else
                j = j+1; 
        end

        default:begin
            busy = 1;
        end

    endcase
end

assign is_legal = is_legal_temp;

endmodule












