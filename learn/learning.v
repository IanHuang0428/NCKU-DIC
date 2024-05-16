// 數位電路是一堆01兜出來的
// 裡面包含一堆MOS


//  連接線Net ( wire、wand、wor )
// 沒有記憶性
// 預設值為z
// 將兩個wire連在一起是不允許的
// 若是型態為wand/wor則例外
module learn_Net( a, b, c, d, e );

    input a, b;
    output c, d, e;

    wire c;
    wand d;
    wor e;

    // wire接一起 → 錯誤
    assign c = a;
    assign c = b;

    // wire-and → d = a&b
    assign d = a;
    assign d = b;

    // wire-or → e = a|b
    assign e = a;
    assign e = b;

endmodule


// 暫存器Register ( reg )
// 有記憶性
// 預設值為x ( 最好要初始化 )

module learn_reg( a, b, c );
    input a;
    output b, c;

    reg b, rTmp;

    // 範例1
    always @(*) begin
        b = a;
    end

    // 範例2
    assign c = rTmp;

endmodule

// 多進制表示
// <位元長度> ’ <進制表示> <數值資料>
// 位元長度：以十進制表示位元長度(二進制長度)
// 進制表示：二進制(b)、八進制(o)、十進制(d)、十六進制(h)，預設為十進制
// 數值資料：可用底線’_’來增加可讀性，數值內也可以混用X和Z

Num = 5'b01101              // 二進制
Num = 22;                   // 十進制
Num = 12'b0000_1111_0000;   // 增加可讀性
Num = 4'hf;                 // 十六進制(二進制的1111)
Num = 4'bxxx1;              // 前三位為未知，最後為1
Num = 4'bz01;               // 前兩位為z，後兩位為01