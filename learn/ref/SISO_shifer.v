module SISO_SR(clk, clear, SI, SO);
input clk, clear, SI;
output SO;
reg [3:0]Reg4;

always @(posedge clk or posedge clear) begin
    if(clear)
        Reg4 = 4'b0;
    else 
        begin
            Reg4[3] = Reg4[2];
            Reg4[2] = Reg4[1];
            Reg4[1] = Reg4[0];
            Reg4[0] = SI;
        end
end


assign SO = Reg4[2];

endmodule
