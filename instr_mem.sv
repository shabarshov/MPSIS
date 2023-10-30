module instr_mem (
    input logic [31:0] addr_i,
    output logic [31:0] read_data_o
);

reg [31:0] memory [0:1023];

initial $readmemh("result.txt", memory);
    
always_comb begin
    if(addr_i > 4095)
        read_data_o <= 32'd0;
    else
        read_data_o <= memory[addr_i[31:2]];
end

endmodule
