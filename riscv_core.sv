module riscv_core (
  input logic clk_i,
  input logic rst_i,

  input logic stall_i,
  input logic [31:0] instr_i,
  input logic [31:0] mem_rd_i,

  output logic [31:0] instr_addr_o,
  output logic [31:0] mem_addr_o,
  output logic [2:0] mem_size_o,
  output logic mem_req_o,
  output logic mem_we_o,
  output logic [31:0] mem_wd_o
);

import riscv_pkg::*;

logic [1:0] dr_a_sel_o;
logic [2:0] dr_b_sel_o;
logic [4:0] dr_alu_op_o;
logic [2:0] dr_csr_op_o;
logic dr_csr_we_o;
logic dr_mem_req_o;
logic dr_mem_we_o;
logic [2:0] dr_mem_size_o;
logic dr_gpr_we_o;
logic [1:0] dr_wb_sel_o;
logic dr_illegal_instr_o;
logic dr_branch_o;
logic dr_jal_o;
logic dr_jalr_o;
logic dr_mret_o;

logic [31:0] RD1;
logic [31:0] RD2;

logic [31:0] wb_data;

logic [31:0] first_alu;
logic [31:0] second_alu;
logic [31:0] main_alu_result;

logic flag;

decoder_riscv dr(
    .fetched_instr_i(instr_i),

    .a_sel_o(dr_a_sel_o),
    .b_sel_o(dr_b_sel_o),
    .alu_op_o(dr_alu_op_o),
    .csr_op_o(dr_csr_op_o), //
    .csr_we_o(dr_csr_we_o), //
    .mem_req_o(dr_mem_req_o),
    .mem_we_o(dr_mem_we_o),
    .mem_size_o(dr_mem_size_o),
    .gpr_we_o(dr_gpr_we_o), 
    .wb_sel_o(dr_wb_sel_o), 
    .illegal_instr_o(dr_illegal_instr_o), //
    .branch_o(dr_branch_o), 
    .jal_o(dr_jal_o),
    .jalr_o(dr_jalr_o),
    .mret_o(dr_mret_o) //
);

rf_riscv rf(
 .clk_i(clk_i),
 .write_enable_i(dr_gpr_we && !stall_i),
 .write_addr_i(instr_i[11:7]),
 .read_addr1_i(instr_i[19:15]),
 .read_addr2_i(instr_i[24:20]), 
 .write_data_i(wb_data),
 
 .read_data1_o(RD1),
 .read_data2_o(RD2)
);

alu_riscv main_alu(
  .a_i(first_alu),
  .b_i(second_alu),
  .alu_op_i(dr_alu_op_o),
  .flag_o(flag),
  .result_o(main_alu_result)
);


logic [31:0] PC;
logic [31:0] PC_i;
logic [31:0] sum1;
logic [31:0] mul_B_J_o;
logic [31:0] sum2;
logic [31:0] mul_2_result;

logic [11:0] imm_i;
assign imm_i = instr_i[31:20];

logic [31:0] imm_i_32;
assign imm_i_32 = { {20{imm_i[11]}}, imm_i };

logic [11:0] imm_s;
assign imm_s[11:5] = instr_i[31:25];
assign imm_s[4:0] = instr_i[11:7];

logic [31:0] imm_s_32;
assign imm_s_32 = { {20{imm_s[11]}}, imm_s };

logic [11:0] imm_b;
assign imm_b[11] = instr_i[31];
assign imm_b[10] = instr_i[7];
assign imm_b[9:4] = instr_i[30:25];
assign imm_b[3:0] = instr_i[11:8];

logic [31:0] imm_b_32;
//assign imm_b_32 = { {19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0 };
assign imm_b_32 = { {19{imm_b[11]}}, imm_b, 1'b0 };

logic [19:0] imm_u;
assign imm_u = instr_i[31:12];

logic [31:0] imm_u_32;
assign imm_u_32 = { imm_u, {12'h000} };


logic [19:0] imm_j;
assign imm_j[19] = instr_i[31];
assign imm_j[9:0] = instr_i[30:21];
assign imm_j[10] = instr_i[20];
assign imm_j[18:11] = instr_i[19:12];

logic [31:0] imm_j_32;
assign imm_j_32 = { {11{imm_j[19]}}, imm_j, 1'b0 };

fulladder32 left_fa_32(.a_i(RD1), .b_i(imm_i_32), .carry_i(0), .sum_o(sum1));
fulladder32 right_fa_32(.a_i(PC), .b_i(mul_2_result), .carry_i(0), .sum_o(sum2));

always_ff @(posedge clk_i) begin
  if(!stall_i) begin
    if(rst_i) begin
        PC <= 32'd0;
    end
    else begin
        PC <= PC_i;
    end
  end
end

always_comb begin
    // multiplexors from left to right
    // 1 
    case(dr_jalr_o)
      1'b1: begin
        PC_i <= { {sum1[31:1]}, 1'b0 };
      end
      
      1'b0: begin 
        PC_i <= sum2;
      end
    endcase
    
    // 2
    case(dr_jal_o || (dr_branch_o && flag))
        1'd0: begin
            mul_2_result <= 32'd4;
        end
        
        1'd1: begin
            mul_2_result <= mul_B_J_o;
        end
    endcase
    
    // 3
    case(dr_branch_o)
        1'b0: begin
            mul_B_J_o <= imm_j_32;
        end
        
        1'b1: begin
            mul_B_J_o <= imm_b_32;
        end
    endcase
    
    // 4
    case(dr_a_sel_o)
        2'd0: begin
            first_alu <= RD1;
        end
        2'd1: begin
            first_alu <= PC;
        end
        2'd2: begin
            first_alu <= 32'd0;
        end
    endcase
    
    // 5
    case(dr_b_sel_o)
        3'd0: begin
            second_alu <= RD2;
        end
        3'd1: begin
            second_alu <= imm_i_32;
        end
        3'd2: begin
            second_alu <= imm_u_32;
        end
        3'd3: begin
            second_alu <= imm_s_32;
        end
        3'd4: begin
            second_alu <= 32'd4;
        end
    endcase
    
    // 6
    case(dr_wb_sel_o)
        2'd0: begin 
            wb_data <= main_alu_result;
        end
        
        2'd1: begin
            wb_data <= mem_rd_i;
        end
    endcase


    instr_addr_o <= PC;
    mem_size_o <= dr_mem_size_o;
    mem_req_o <= dr_mem_req_o;
    mem_we_o <= dr_mem_we_o;
    mem_wd_o <= RD2;
    mem_addr_o <= main_alu_result; 
end

// assign instr_addr_o = PC;
// assign mem_size_o = dr_mem_size_o;
// assign mem_req_o = dr_mem_req_o;
// assign mem_we_o = dr_mem_we_o;
// assign mem_wd_o = RD2;
// assign mem_addr_o = main_alu_result;

endmodule
