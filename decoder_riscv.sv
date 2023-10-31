module decoder_riscv (
input logic [31:0] fetched_instr_i,

output logic [1:0] a_sel_o,
output logic [2:0] b_sel_o,
output logic [4:0] alu_op_o,
output logic [2:0] csr_op_o,
output logic csr_we_o,
output logic mem_req_o,
output logic mem_we_o,
output logic [2:0] mem_size_o,
output logic gpr_we_o,
output logic [1:0] wb_sel_o, // write back selector
output logic illegal_instr_o,
output logic branch_o,
output logic jal_o,
output logic jalr_o,
output logic mret_o
);

import riscv_pkg::*;

logic [1:0] opcode_end = fetched_instr_i[1:0];

logic [6:2] opcode = fetched_instr_i[6:2];
logic [2:0] funct3 = fetched_instr_i[14:12];
logic [6:0] funct7 = fetched_instr_i[31:25];
logic [4:0] rs2 = fetched_instr_i[24:20];
logic [4:0] rs1 = fetched_instr_i[19:15];
logic [4:0] rd = fetched_instr_i[11:7];

logic [11:0] i_type_imm = fetched_instr_i[31:20];

logic [11:0] s_type_imm;
assign s_type_imm[11:5] = fetched_instr_i[31:25];
assign s_type_imm[4:0] = fetched_instr_i[11:7];

logic [11:0] b_type_imm;
assign b_type_imm[11] = fetched_instr_i[31];
assign b_type_imm[10] = fetched_instr_i[7];
assign b_type_imm[9:4] = fetched_instr_i[30:25];
assign b_type_imm[3:0] = fetched_instr_i[11:8];

logic [19:0] u_type_imm = fetched_instr_i[31:12];

logic [19:0] j_type_imm;
assign j_type_imm[19] = fetched_instr_i[31];
assign j_type_imm[9:0] = fetched_instr_i[30:21];
assign j_type_imm[10] = fetched_instr_i[20];
assign j_type_imm[18:11] = fetched_instr_i[19:12];

always_comb begin
  a_sel_o <= 2'd0;
  b_sel_o <= 3'd0;
  alu_op_o <= 5'd0;
  csr_op_o <= 3'd0;
  csr_we_o <= 1'd0;
  mem_req_o <= 1'd0;
  mem_we_o <= 1'd0;
  mem_size_o <= 3'd0;
  gpr_we_o <= 1'd0;
  wb_sel_o <= 2'd0;
  branch_o <= 1'd0;
  jal_o <= 1'd0;
  jalr_o <= 1'd0;
  mret_o <= 1'd0;
  illegal_instr_o <= 0;

  case(opcode)
    LOAD_OPCODE: begin
    
    end
    MISC_MEM_OPCODE: begin
    
    end
    OP_IMM_OPCODE: begin
    
    end
    AUIPC_OPCODE: begin
    
    end
    STORE_OPCODE: begin
    
    end
    OP_OPCODE: begin
        
    end
    LUI_OPCODE: begin
    
    end
    BRANCH_OPCODE: begin
        branch_o <= 1'd1;
    end
    JALR_OPCODE: begin
        jalr_o <= 1'd1;
    end
    JAL_OPCODE: begin
        jal_o <= 1'd1;
    end
    SYSTEM_OPCODE: begin
    
    end
  endcase
  
end
  
endmodule
