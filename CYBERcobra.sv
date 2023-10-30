module CYBERcobra (
    input logic clk_i, // тактовый импульс
    input logic rst_i, // константа

    input logic [15:0] sw_i, // внешние данные

    output logic [31:0] out_o // то, что даем на выход
);

logic [31:0] PC; // адрес инструкции

logic [31:0] PC_i;
logic [31:0] instr; // полученная инструкция

logic [31:0] RD1;
logic [31:0] RD2;

logic [31:0] const_i;
logic [31:0] WD;

logic alu_flag_o;
logic [31:0] alu_result_o;
logic [31:0] fa32_b_i;

instr_mem im(.addr_i(PC), .read_data_o(instr));
fulladder32 fa32(.a_i(PC), .b_i(fa32_b_i), .carry_i(0), .sum_o(PC_i));

rf_riscv rr(
 .clk_i(clk_i),
 .write_enable_i(!(instr[30] | instr[31])),
 .write_addr_i(instr[4:0]),
 .read_addr1_i(instr[22:18]),
 .read_addr2_i(instr[17:13]), 
 .write_data_i(WD),
 .read_data1_o(RD1),
 .read_data2_o(RD2)
);

alu_riscv ar(
 .a_i(RD1),
 .b_i(RD2), 
 .alu_op_i(instr[27:23]), 
 .flag_o(alu_flag_o),
 .result_o(alu_result_o)
);

assign const_i = { {9{instr[27]}}, instr[27:5] };

always_ff @(posedge clk_i) begin // отрабатывает каждый такт
    if(rst_i) begin
        PC <= 32'd0;
    end
    else begin
        PC <= PC_i;
    end
end

always_comb begin
   case(instr[29:28])
    4'd0: begin
        WD <= const_i;
    end
    
    4'd1: begin
        WD <= alu_result_o;
    end

    4'd2: begin
        WD <= {{16{sw_i[15]}}, sw_i[15:0]};
    end

    4'd3: begin
        WD <= 32'd0;
    end
   endcase
   
   case((alu_flag_o & instr[30]) | instr[31])
     0: begin
       fa32_b_i <= 32'd4;
     end

     1: begin 
        fa32_b_i <= {{22{instr[12]}}, instr[12:5], 2'b0};
    end
   endcase
end

assign out_o = RD1;

endmodule
