module riscv_unit(
  input logic clk_i,
  input logic rst_i
);

logic stall_i;

logic [31:0] im_read_data_o;

logic [31:0] core_instr_addr_o;
logic [31:0] core_mem_addr_o;
logic [2:0] core_mem_size_o;
logic core_mem_req_o;
logic core_mem_we_o;
logic [31:0] core_mem_wd_o;

logic [31:0] dm_read_data_o;


instr_mem im(
  .addr_i(core_instr_addr_o),
  .read_data_o(im_read_data_o)
);

riscv_core core(
  .clk_i(clk_i),
  .rst_i(rst_i),

  .stall_i(stall_i),
  .instr_i(im_read_data_o),
  .mem_rd_i(dm_read_data_o),

  .instr_addr_o(core_instr_addr_o),
  .mem_addr_o(core_mem_addr_o),
  .mem_size_o(core_mem_size_o), // 
  .mem_req_o(core_mem_req_o),
  .mem_we_o(core_mem_we_o),
  .mem_wd_o(core_mem_wd_o)
);

data_mem dm(
  .clk_i(clk_i),
  .mem_req_i(core_mem_req_o),
  .write_enable_i(core_mem_we_o),
  .addr_i(core_mem_addr_o),
  .write_data_i(core_mem_wd_o),

  .read_data_o(dm_read_data_o)
);

always_ff @(posedge clk_i) begin
  if(rst_i) begin
    stall_i <= 1d'0;
  end
  else begin
    stall_i <= (!stall_i && core_mem_req_o);
  end
end

endmodule
