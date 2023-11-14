module decoder_riscv (
    input logic [31:0] fetched_instr_i,
    
    output logic [1:0] a_sel_o, // Управляющий сигнал мультиплексора для выбора первого операнда АЛУ
    output logic [2:0] b_sel_o, // Управляющий сигнал мультиплексора для выбора второго операнда АЛУ
    output logic [4:0] alu_op_o, // Операция АЛУ // rd
    output logic [2:0] csr_op_o, // Операция модуля CSR
    output logic csr_we_o, // Разрешение на запись в CSR
    output logic mem_req_o, // Запрос на доступ к памяти (часть интерфейса памяти)
    output logic mem_we_o, // Сигнал разрешения записи в память, «write enable» (при равенстве нулю происходит чтение)
    output logic [2:0] mem_size_o, // Управляющий сигнал для выбора размера слова при чтении-записи в память (часть интерфейса памяти)
    output logic gpr_we_o, // Сигнал разрешения записи в регистровый файл
    output logic [1:0] wb_sel_o, // Управляющий сигнал мультиплексора для выбора данных, записываемых в регистровый файл
    output logic illegal_instr_o, // Сигнал о некорректной инструкции (на схеме не отмечен)
    output logic branch_o, // Сигнал об инструкции условного перехода
    output logic jal_o, // Сигнал об инструкции безусловного перехода jal
    output logic jalr_o, // Сигнал об инструкции безусловного перехода jalr
    output logic mret_o // Сигнал об инструкции возврата из прерывания/исключения mret
);

import riscv_pkg::*;

logic [1:0] opcode_end;
logic [4:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;

assign opcode_end = fetched_instr_i[1:0];
assign opcode = fetched_instr_i[6:2];
assign funct3 = fetched_instr_i[14:12];
assign funct7 = fetched_instr_i[31:25];

always_comb begin
  a_sel_o <= OP_A_RS1;
  b_sel_o <= OP_B_RS2;
  alu_op_o <= 5'b00000;
  csr_op_o <= 3'b000;
  csr_we_o <= 1'b0;
  mem_req_o <= 1'b0;
  mem_we_o <= 1'b0;
  mem_size_o <= 3'b000; // 000 
  gpr_we_o <= 1'b0;
  wb_sel_o <= WB_EX_RESULT;
  branch_o <= 1'b0;
  jal_o <= 1'b0;
  jalr_o <= 1'b0;
  mret_o <= 1'b0;
  illegal_instr_o <= 1'b0;
  
  
  if(opcode_end != 2'b11) illegal_instr_o <= 1'b1;
  
  else begin  
  
  case(opcode)
    LOAD_OPCODE: begin
        mem_req_o <= 1;
        mem_we_o <= 0;
        gpr_we_o <= 1;
        a_sel_o <= OP_A_RS1;
        b_sel_o <= OP_B_IMM_I;
        wb_sel_o <= WB_LSU_DATA;

      if(funct3 === 3'b000) begin
        mem_size_o <= LDST_B;
      end else if(funct3 === 3'b001) begin
        mem_size_o <= LDST_H;
      end else if(funct3 === 3'b010) begin
        mem_size_o <= LDST_W;
      end else if(funct3 === 3'b100) begin
        mem_size_o <= LDST_BU;
      end else if(funct3 === 3'b101) begin
        mem_size_o <= LDST_HU;
      end else begin
        mem_req_o <= 0;
        gpr_we_o <= 0;
        b_sel_o <= OP_B_RS2;
        wb_sel_o <= WB_EX_RESULT;

        illegal_instr_o <= 1'b1;
      end

    end
    MISC_MEM_OPCODE: begin
      if(funct3 === 3'b000) begin
        illegal_instr_o <= 1'b0;
      end else begin
        illegal_instr_o <= 1'b1;
      end
    end
    OP_IMM_OPCODE: begin
        gpr_we_o <= 1;
        b_sel_o <= OP_B_IMM_I;

        if(funct3 == 3'b000) begin
          alu_op_o <= ALU_ADD;
        end else if(funct3 == 3'b100) begin
          alu_op_o <= ALU_XOR;
        end else if(funct3 == 3'b110) begin
          alu_op_o <= ALU_OR;
        end else if(funct3 == 3'b111) begin
          alu_op_o <= ALU_AND;
        end else if(funct3 == 3'b001 && funct7 == 7'b0000000) begin
          alu_op_o <= ALU_SLL;
        end else if (funct3 == 3'b101 && funct7 == 7'b0000000) begin
          alu_op_o <= ALU_SRL;
        end else if (funct3 == 3'b101 && funct7 == 7'b0100000) begin
          alu_op_o <= ALU_SRA;
        end else if (funct3 == 3'b010) begin
          alu_op_o <= ALU_SLTS;
        end else if (funct3 == 3'b011) begin
          alu_op_o <= ALU_SLTU;
        end else begin
          gpr_we_o <= 0;
          b_sel_o <= OP_B_RS2;

          illegal_instr_o <= 1'b1;
        end
    end
    AUIPC_OPCODE: begin
      a_sel_o <= OP_A_CURR_PC;
      b_sel_o <= OP_B_IMM_U;
      gpr_we_o <= 1;
    end
    STORE_OPCODE: begin
      mem_req_o <= 1;
      mem_we_o <= 1;
      b_sel_o <= OP_B_IMM_S;

      if(funct3 == 3'b000) begin
        mem_size_o <= LDST_B;
      end else if(funct3 == 3'b001) begin
        mem_size_o <= LDST_H;
      end else if(funct3 == 3'b010) begin 
        mem_size_o <= LDST_W;
      end else begin
        mem_req_o <= 0;
        mem_we_o <= 0;
        b_sel_o <= OP_B_RS2;
        
        illegal_instr_o <= 1'b1;
      end
    end
    OP_OPCODE: begin
        gpr_we_o <= 1;

        if(funct3 == 3'b000 && funct7 == 7'b0000000) begin
          alu_op_o <= ALU_ADD;
        end else if(funct3 == 3'b000 && funct7 == 7'b0100000) begin
          alu_op_o <= ALU_SUB;
        end else if(funct3 == 3'b100 && funct7 == 7'b0000000) begin
          alu_op_o <= ALU_XOR;
        end else if(funct3 == 3'b110 && funct7 == 7'b0000000) begin
          alu_op_o <= ALU_OR;
        end else if(funct3 == 3'b111 && funct7 == 7'b0000000) begin
          alu_op_o <= ALU_AND;
        end else if(funct3 == 3'b001 && funct7 == 7'b0000000) begin
          alu_op_o <= ALU_SLL;
        end else if(funct3 == 3'b101 && funct7 == 7'b0000000) begin
          alu_op_o <= ALU_SRL;
        end else if(funct3 == 3'b101 && funct7 == 7'b0000000) begin
          alu_op_o <= ALU_SRL;
        end else if(funct3 == 3'b101 && funct7 == 7'b0100000) begin
          alu_op_o <= ALU_SRA;
        end else if(funct3 == 3'b010 && funct7 == 7'b0000000) begin
          alu_op_o <= ALU_SLTS;
        end else if(funct3 == 3'b011 && funct7 == 7'b0000000) begin
          alu_op_o <= ALU_SLTU;
        end else begin
          gpr_we_o <= 0;
          illegal_instr_o <= 1'b1;
        end
    end
    LUI_OPCODE: begin
      gpr_we_o <= 1;
      a_sel_o <= OP_A_ZERO;
      b_sel_o <= OP_B_IMM_U;
    end
    BRANCH_OPCODE: begin
      branch_o <= 1;

      if (funct3 === 3'b000) begin
        alu_op_o <= ALU_EQ;
      end else if (funct3 === 3'b001) begin
        alu_op_o <= ALU_NE;
      end else if (funct3 === 3'b100) begin
        alu_op_o <= ALU_LTS;
      end else if (funct3 === 3'b101) begin
        alu_op_o <= ALU_GES;
      end else if (funct3 === 3'b110) begin
        alu_op_o <= ALU_LTU;
      end else if (funct3 === 3'b111) begin
        alu_op_o <= ALU_GEU;
      end else begin
        branch_o <= 0;
        illegal_instr_o <= 1'b1;
      end
    end
    JALR_OPCODE: begin
      if(funct3 === 3'b000) begin
        a_sel_o <= OP_A_CURR_PC;
        b_sel_o <= OP_B_INCR;
        gpr_we_o <= 1;
        jalr_o <= 1;
      end else begin
        illegal_instr_o <= 1'b1;
      end
    end
    JAL_OPCODE: begin
      a_sel_o <= OP_A_CURR_PC;
      b_sel_o <= OP_B_INCR;
      gpr_we_o <= 1;
      jal_o <= 1;
    end
    SYSTEM_OPCODE: begin
      if(funct3 == 3'b000) begin
        if (funct7 == 7'b0011000) begin
          mret_o <= 1;
        end else begin
          illegal_instr_o <= 1'b1;
        end
      end else begin
        gpr_we_o <= 1;
        csr_we_o <= 1;
        wb_sel_o <= WB_CSR_DATA;

        if(funct3 == 3'b001) begin
          csr_op_o <= CSR_RW;
        end else if(funct3 == 3'b010) begin
          csr_op_o <= CSR_RS;
        end else if(funct3 == 3'b011) begin
          csr_op_o <= CSR_RC;
        end else if(funct3 == 3'b101) begin
          csr_op_o <= CSR_RWI;
        end else if(funct3 == 3'b110) begin
          csr_op_o <= CSR_RSI;
        end else if(funct3 == 3'b111) begin
          csr_op_o <= CSR_RCI;
        end else begin
          gpr_we_o <= 0;
          csr_we_o <=0;
          wb_sel_o <= WB_EX_RESULT;

          illegal_instr_o <= 1'b1;
        end
      end
    end
    default: illegal_instr_o <= 1'b1;
  endcase
  end
end

endmodule
