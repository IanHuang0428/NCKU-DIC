module CIPU(
input       clk, 
input       rst,
input       [7:0]people_thing_in,
input       ready_fifo,
input       ready_lifo,
input       [7:0]thing_in,   
input       [3:0]thing_num,
output      valid_fifo,
output      valid_lifo,
output      valid_fifo2,
output      [7:0]people_thing_out,
output      [7:0]thing_out,
output      done_thing,
output      done_fifo,
output      done_lifo,
output      done_fifo2);

//LIFO
//---------------------------------------------------------------
reg [7:0] temp [15:0];
reg [7:0] left [29:0];
reg [29:0] left_count;
reg [7:0] lifo_data_out;
reg [3:0] count;
reg [3:0] num, left_num;
reg lifo_oe, done, temp_done, fifo2_oe, done2;
reg [3:0] currentstate, nextstate;
localparam [3:0] Init_State=4'b0000; 
localparam [3:0] Catch_Thing=4'b0001;
localparam [3:0] Send_get=4'b0010;
localparam [3:0] Save_left = 4'b0011;
localparam [3:0] Done = 4'b0100;
localparam [3:0] Delay = 4'b0101;
localparam [3:0] Send_left = 4'b0110;
localparam [3:0] Done2 = 4'b0111;
localparam [3:0] Finish= 4'b1000;

//Next State Logic
always@(*)
begin
    
    case(currentstate)
        Init_State:begin
            if(ready_lifo)
                nextstate = Catch_Thing;
            else
                nextstate = Init_State;
        end

        Catch_Thing:begin
            if (thing_in == 8'h3b)
                nextstate= Send_get;
            else
                nextstate = Catch_Thing;
        end


        Send_get:begin
            if (num == 0)
                nextstate = Save_left;
            else
                nextstate=Send_get;
        end

        Save_left: begin
            if(count < 1 )
                nextstate = Done;
            else
                nextstate = Save_left;
        end

        Done: begin
            nextstate = Delay; 
        end


        Delay:begin
            if (thing_in == 8'h24)
                nextstate = Send_left;
            else
                nextstate=Catch_Thing;
        end
        Send_left:begin
            if(left_num == left_count)
                nextstate = Done2;
            else
                nextstate = Send_left;
        end
        Done2: begin
            nextstate = Finish;
        end

        Finish:begin
        end

        default nextstate=Init_State;
    endcase
end

// state Register
always@(posedge clk)
begin
    if(rst)
        currentstate = Init_State;
    else
        currentstate = nextstate;
end

//Output Logic
always@(posedge clk)
begin
    case(currentstate)
        Init_State:begin
            count = -1;
            left_count = 0;
            lifo_oe = 0; 
            done = 0;   
        end

        Catch_Thing:begin
            lifo_oe = 0;
            left_num = 0;
            if (thing_num == 0 && thing_in == 8'h3b) begin
                num = 0;
                count = count + 1;    
            end

            else if(thing_in == 8'h3b)begin
                num = thing_num;
                count = count + 1;
            end

            else begin
                temp[count] = thing_in;
                num = thing_num;
                count = count + 1;
            end
        end


        Send_get:begin
            
            if(thing_num == 0)
                lifo_data_out = 8'h30;

            else begin
                count = count - 1;
                lifo_data_out = temp[count];
                temp[count] = 0;
                num = num - 1;
            end
            lifo_oe = 1;
               
        end
        Save_left: begin
            lifo_oe = 0;
            if(count == 0)
                count = count;
            else if(temp[left_num])begin
                left[left_count] = temp[left_num];
                temp[left_num] = 0;
                left_num = left_num + 1;
                left_count = left_count + 1;
                
            end
            count = count - 1;
        end
        Done:begin
            temp_done = 1;
            count = 0;
            num = 0;
            left_num = 0;
        end
        Delay:begin
            temp_done = 0;
        end
        Send_left:begin
            lifo_data_out = left[left_num];
            fifo2_oe = 1;
            left_num = left_num + 1;
        end
        Done2: begin
            fifo2_oe = 0;
            done2 = 1;
        end
        Finish:begin
            done2 = 0;
            done = 1;
            
        end
        default:begin

        end
    endcase
end


assign done_thing = temp_done;
assign valid_lifo = lifo_oe;
assign done_lifo = done;

assign thing_out = lifo_data_out;

assign valid_fifo2 = fifo2_oe;
assign done_fifo2 = done2;





//FIFO
//---------------------------------------------------------------
reg [7:0] people;
reg valid1;
reg done1;

always@(posedge clk)
begin
        if (people_thing_in == 16'h24)
            begin
                valid1 = 0;
                done1 = 1;
            end
        else if (people_thing_in < 16'h30 || people_thing_in > 16'h39) 
            begin
                valid1 = 1;
                people = people_thing_in;
            end 
        else 
            begin
                valid1 = 0;
            end 

end
assign done_fifo = done1;
assign people_thing_out = people;
assign valid_fifo = valid1;
//---------------------------------------------------------------
endmodule



















