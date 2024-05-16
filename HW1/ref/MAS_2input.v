// 
// Designer: <N26112291> 
//


module MAS_2input(
  input signed [4:0] Din1,
  input signed [4:0] Din2,
  input [1:0] Sel,
  input signed[4:0] Q,
  output [1:0] Tcmp,
  output signed [4:0] TDout,
  output signed [3:0] Dout
);

  // Intermediate signed result before modulo reduction
  reg signed [4:0] temp1;
  // always @(posedge clk) or always @(negedge clk_n)  循序邏輯 賦值用"<="
  // always @(*) 組合邏輯 賦值用"="
  always @(Sel or Din1 or Din2)begin
   if (Sel == 2'b00)
     temp1 = Din1 + Din2;
   else if (Sel == 2'b11)
     temp1 = Din1 - Din2;
   else
     temp1 = Din1;
  end

  // Calculate positive modulo remainder
  //賦予wire訊號一個值
  // assign <wire> = #[延遲時間]<邏輯公式 or 常數>
  // 'assign' 不能用在 'always' 裡
  assign TDout = temp1;  


  reg [1:0] temp2;
  always @(TDout or Q)begin
    if (TDout[4] ==0)begin

      if (TDout >= Q)
        temp2 = 2'b11;
      else if (TDout < Q)
        temp2 = 2'b01;
    end

    else if (|TDout == 0)
      temp2 = 2'b01;
    
    else
      temp2 = 2'b00;
  end
    assign Tcmp = temp2; 



  reg signed [3:0] temp3;
  always @(Tcmp or Q or TDout)begin
  if (Tcmp == 2'b11)
    temp3 = TDout - Q;
  else if (Tcmp == 2'b01)
    temp3 = TDout;
  else
    temp3 = TDout + Q;
  end
  assign Dout = temp3; 


endmodule