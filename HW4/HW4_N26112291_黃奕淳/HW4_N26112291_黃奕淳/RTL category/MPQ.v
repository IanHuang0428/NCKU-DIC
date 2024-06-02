module MPQ(clk,rst,data_valid,data,cmd_valid,cmd,index,value,busy,RAM_valid,RAM_A,RAM_D,done);

    input clk;
    input rst;
    input data_valid;
    input [7:0] data;
    input cmd_valid;
    input [2:0] cmd;
    input [7:0] index;
    input [7:0] value;

    output reg busy;
    output reg RAM_valid;
    output reg[7:0]RAM_A;
    output reg [7:0]RAM_D;
    output reg done;


    // State
    localparam [2:0] s0=3'b000;  //init
    localparam [2:0] s1=3'b001;  //get data
    localparam [2:0] s2=3'b010;  //read cmd
    localparam [2:0] s3=3'b011;  //Build_Queue
    localparam [2:0] s4=3'b100;  //Extract_Max
    localparam [2:0] s5=3'b101;  //Increase_Value
    localparam [2:0] s6=3'b110;  //Insert_Data
    localparam [2:0] s7=3'b111;  //Write

    //temperory registers
    reg [7:0] queue [12:0];
    reg [2:0] action;

    //Build registers
    reg max_heapify;
    reg [3:0] build_i, build_temp;
    reg [3:0] ind;
    reg [7:0] l, r;
    reg [3:0] largest; 

    //Extract registers
    reg [7:0] max;

    //Increase registers
    reg [7:0] index_temp;
    reg [7:0] increase_index;
    reg [7:0] increase_value;
    reg [7:0] increase_init;

    //Write registers
    reg [3:0] write_temp;

    //State registers
    reg [2:0] CurrentState, NextState;
    reg build_done, increase_done, write_done;
    reg exe_build, exe_extract, exe_increase, exe_insert, exe_write;


    // Next State
    always @(*) 
    begin
        case (CurrentState)
            s0: begin
                NextState = s2;
            end

            s1: begin
                if (data_valid)
                    NextState = s1;
                else
                    NextState = s0;
            end
        
            s2: begin
                if (exe_build == 2'b01) begin
                    NextState = s3; //Build_Queue
                end
            
                else if (exe_extract == 2'b01) begin
                    NextState = s4; //Extract_Max
                end
                else if (exe_increase == 2'b01) begin
                    NextState = s5; //Increase_Value
                end
                else if (exe_insert == 2'b01) begin
                    NextState = s6; //Insert_Data
                end
                else if (exe_write == 2'b01) begin
                    NextState = s7;  //Write
                end

                else begin
                    NextState = s2;
                end
            end

            //Build_Queue
            s3: begin
                if (build_done)
                    NextState = s0;
                else
                    NextState = s3;
            end

            //Extract_Max
            s4: begin
                NextState = s3;
            end

            //Increase_Value
            s5: begin
                if (increase_done)
                    NextState = s0;
                else
                    NextState = s5;
            end

            //Insert_Data
            s6: begin
                NextState = s5;
            end

            //Write
            s7: begin
                if (write_done)
                    NextState = s0;
                else
                    NextState = s7;
            end

            default:NextState = s1;
        
        endcase
    end


    // Output logic & Datapath
    always @(posedge clk or posedge rst) 

    begin

        if (rst)begin
            //Initialize params
            ind = 0;
            done = 0;
            busy = 1;
            max_heapify = 0;
            increase_init = 0;
            build_i = 0;
            write_temp = 0;

            exe_build = 0;
            exe_extract = 0;
            exe_increase = 0;
            exe_insert = 0;
            exe_write = 0;

            build_done = 0;
            increase_done = 0;
            write_done = 0;
            CurrentState <= s1;
        end

        else 
            CurrentState <= NextState;

        case (CurrentState)

                //init
                s0: begin   

                    //Initialize params
                    busy = 0;
                    max_heapify = 0;
                    increase_init = 0;
                    build_i = 0;
                    write_temp = 0;

                    exe_build = 0;
                    exe_extract = 0;
                    exe_increase = 0;
                    exe_insert = 0;
                    exe_write = 0;

                    build_done = 0;
                    increase_done = 0;
                    write_done = 0;
                end

                //get data
                s1: begin   
                    if (data_valid) begin
                        queue[ind] = data;
                        ind = ind + 1;
                    end
                end    

                //read cmd
                s2: begin    
                    if (cmd_valid) begin
                        case (cmd)  
                            3'b000: begin
                                exe_build <= 1;
                                build_i <= (ind >> 1);  //half of queue length
                                build_temp <= (ind >> 1);  //half of queue length
                            end

                            3'b001: begin
                                exe_extract <= 1;
                            end

                            3'b010: begin
                                exe_increase <= 1;
                                increase_index <= index;
                                increase_value <= value;
                                index_temp <= index;
                            end

                            3'b011: begin
                                exe_insert <= 1;
                                increase_index <= ind + 1;
                                increase_value <= value;
                                index_temp <= ind + 1;
                            end

                            3'b100: begin
                                exe_write <= 1;
                            end
                        endcase
                    busy <= 1;
                    end
                end

                //Build_Queue
                s3: begin  
                    if (max_heapify) begin

                        l = (build_i << 1);
                        r = (build_i << 1) + 1;
                        
                        if ((l <= ind) && (queue[l-1] > queue[build_i-1])) begin
                            largest = l;
                        end
                        else begin
                            largest = build_i;
                        end

                        if ((r <= ind) && (queue[r-1] > queue[largest-1])) begin
                            largest = r;
                        end
      

                        if (largest != build_i) begin
                            queue[largest-1] <= queue[build_i-1];
                            queue[build_i-1] <= queue[largest-1];
                            build_i <= largest;
                            max_heapify <= 1;
                        end
                        else begin
                            max_heapify <= 0;
                            build_temp <= build_temp - 1;
                        end
                    end
                    else begin
                        if (build_temp == 0) begin
                            build_done <= 1;
                        end

                        else begin
                            max_heapify <= 1;
                            build_i <= build_temp;
                        end
                    end
                end    

                //Extract_Max
                s4: begin
                    max = queue[0];
                    queue[0] = queue[ind-1];
                    ind = ind-1;
                    build_i = 1;
                    max_heapify = 1;
                end   

                //Increase_Value
                s5: begin      
                    if (increase_init) begin
                        if ((index_temp > 1) && (queue[(index_temp >> 1)-1] < queue[index_temp-1])) begin
                            queue[index_temp-1] <= queue[(index_temp >> 1)-1];
                            queue[(index_temp >> 1)-1] <= queue[index_temp-1];
                            index_temp = (index_temp >> 1);
                            increase_done = 0;
                        end
                        else begin
                            increase_done = 1;
                        end
                    end
                    else begin
                        queue[increase_index-1] = increase_value;
                        increase_init = 1;
                    end 
                end

                //Insert_Data
                s6: begin
                    ind = ind + 1;
                end

                //Write
                s7: begin   
                    if (write_temp < ind) begin
                        RAM_valid = 1;
                        RAM_A = write_temp;
                        RAM_D = queue[write_temp];
                        write_temp = write_temp + 1;
                    end
                    else begin
                        RAM_valid = 0;
                        write_done = 1;
                        done = 1;  
                    end
                end
        endcase
    end

endmodule






