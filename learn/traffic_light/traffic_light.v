module traffic(Clock, Reset, Red, Green, Yellow);
input Clock, Reset;
output Red, Green, Yellow;
wire Recount_conter;
wire [3:0] Counter_Number;

Traffic_Control(.Clock(Clock), .Reset(Reset), .Recount_conter16(Recount_conter), .Red(Red), .Green(Green), .Yellow(Yellow));

Datapath(.Clock(Clock), .Reset(Reset), .RGY({Red,Green,Yellow}), .Recount(Recount_conter));

endmodule


module Datapath(Clock, Reset, RGY, Recount);
input Clock, Reset;
input [2:0] RGY;
output Recount;
wire [3:0] Counter_Number;

Counter16 A2 (.Clock(Clock), .Reset(Reset), .Recount_conter16(Recount), .Count_out(Counter_Number));

Compare A1 (.current_times(Counter_Number), .RGY(RGY), .Recount_conter16(Recount));

endmodule


module Compare(current_times, RGY, Recount_conter16);
input [3:0] RGY;
input [3:0] current_times;
output Recount_conter16;
reg Recount_conter16;
parameter R_times=4 ,G_times=2, Y_times=0;

@always(RGY)
begin
    case(RGY)
        3'b100:begin
            if(current_times == R_times)
                Recount_conter16=1;
            else
                Recount_conter16=0;
            end
        3'b001:begin
            if(current_times == Y_times)
                Recount_conter16=1;
            else
                Recount_conter16=0;
            end
        3'b010:begin
            if(current_times == G_times)
                Recount_conter16=1;
            else
                Recount_conter16=0;
            end       
        default:Recount_conter16=1;                                          
    endcase
end
endmodule


module Counter16(Clock, Reset, Recount_conter16, Count_out);
input Clock, Reset Recount_conter16;
output [3:0] Count_out;
reg [3:0] Count_out;

always@(posedge Clock)
begin
    if(Reset)
        Count_out = 0;
    else
        begin
            if(Recount_conter16)
                Count_out = 0;
            else
                Count_out = Count_out + 1;
        end
end
endmodule


module Traffic_Control(Clock, Reset, Recount_conter16, Red, Green, Yellow);
input Clock, Reset, Recount_conter16;
output Red, Green, Yellow;
reg Red, Green, Yellow;
reg [1:0] currentstate, nextstate;
parameter [1:0] Red_Light=0, Green_Light=1, Yellow_Light=2;

//Next State Logic
always@(currentstate)
begin
    case(currentstate)
        Red_Light:begin
            if(Recount_conter16)
                nextstate=Green_Light;
            else
                nextstate=Red_Light;
            end
        Green_Light:begin
            if(Recount_conter16)
                nextstate=Yellow_Light;
            else
                nextstate=Green_Light;
            end
        Yellow_Light:begin
            if(Recount_conter16)
                nextstate=Red_Light;
            else
                nextstate=Yellow_Light;
            end
        default nextstate=Red_Light;
    endcase
end

// state Register
always@(posedge Clock)
begin
    if(Reset)
        currentstate = Red_Light;
    else
        currentstate = nextstate;
end

//Output Logic
always@(currentstate)
begin
    case(currentstate)
        Red_Light:begin
            Red=1'b1;
            Green=1'b0;
            Yellow=1'b0;
            end
        Green_Light:begin
            Red=1'b0;
            Green=1'b1;
            Yellow=1'b0;
            end
        Yellow_Light:begin
            Red=1'b0;
            Green=1'b0;
            Yellow=1'b1;
            end
        default:begin
            Red=1'b0;
            Green=1'b0;
            Yellow=1'b0;
            end
    endcase

end


endmodule