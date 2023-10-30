module fulladder4(
    input logic [3:0] a_i,
    input logic [3:0] b_i,
    input logic carry_i,
    
    output logic [3:0] sum_o,
    output logic carry_o
);

    logic tmp0;
    logic tmp1;
    logic tmp2;
    
    fulladder fa0(
        .a_i(a_i[0]),
        .b_i(b_i[0]),
        .carry_i(carry_i),
        
        .sum_o(sum_o[0]),
        .carry_o(tmp0)
    );
    
    fulladder fa1(
        .a_i(a_i[1]),
        .b_i(b_i[1]),
        .carry_i(tmp0),
        
        .sum_o(sum_o[1]),
        .carry_o(tmp1)
    );
    
    fulladder fa2(
        .a_i(a_i[2]),
        .b_i(b_i[2]),
        .carry_i(tmp1),
        
        .sum_o(sum_o[2]),
        .carry_o(tmp2)
    );
    fulladder fa3(
        .a_i(a_i[3]),
        .b_i(b_i[3]),
        .carry_i(tmp2),
        
        .sum_o(sum_o[3]),
        .carry_o(carry_o)
    );


endmodule