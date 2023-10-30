module data_mem(
    input logic clk_i,
    input logic mem_req_i,
    input logic write_enable_i,
    input logic [31:0] addr_i,
    input logic [31:0] write_data_i,
    output logic [31:0] read_data_o
);

logic [31:0] memory [0:4095];

always_ff @(posedge clk_i) begin
        if(mem_req_i == 0 || write_enable_i == 1)
            read_data_o <= 32'hfa11_1eaf;
        else if(mem_req_i == 1 & addr_i < 4096*4)
            read_data_o <= memory[addr_i[31:2]];
        else if(mem_req_i == 1 & addr_i > 4096*4)
            read_data_o <= 32'hdead_beef;

end

always_ff @(posedge clk_i) begin
    if(mem_req_i == 1 & write_enable_i == 1)
        memory[addr_i[31:2]] <= write_data_i;
end

endmodule