module fulladder32(
    input logic [31:0] a_i,
    input logic [31:0] b_i,
    input logic carry_i,
    
    output logic [31:0] sum_o,
    output logic carry_o
);

logic tmp[32:0];
assign tmp[0] = carry_i;
    
genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : newgen
        fulladder fa(
            .a_i(a_i[i]),
            .b_i(b_i[i]),
            .carry_i(tmp[i]),
            
            .sum_o(sum_o[i]),
            .carry_o(tmp[i + 1])
        );
        
    end
endgenerate

assign carry_o = tmp[32];

endmodule
