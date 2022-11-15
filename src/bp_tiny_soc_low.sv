// Copyright Flavien Solt, ETH Zurich.
// Licensed under the General Public License, Version 3.0, see LICENSE for details.
// SPDX-License-Identifier: GPL-3.0-only

// Toplevel module without taints.

module bp_tiny_soc #(
    parameter int unsigned NumWords = 1 << 17,
    parameter int unsigned AddrWidth = 64,
    parameter int unsigned DataWidth = 64,

    parameter int unsigned StrbWidth = DataWidth >> 3,
    localparam type addr_t = logic [AddrWidth-1:0],
    localparam type data_t = logic [DataWidth-1:0],
    localparam type strb_t = logic [StrbWidth-1:0]
) (
  input logic clk_i,
  input logic rst_ni,

  // To prevent the whole internal logic from being optimized out.
  output data_t mem_rdata_instr_o,
  output data_t mem_rdata_data_o
);

  logic  mem_req_instr, mem_req_data     /* verilator public */;
  logic  mem_gnt_instr, mem_gnt_data     /* verilator public */;
  addr_t mem_addr_instr, mem_addr_data   /* verilator public */;
  data_t mem_wdata_instr, mem_wdata_data /* verilator public */;
  strb_t mem_strb_instr, mem_strb_data   /* verilator public */;
  logic  mem_we_instr, mem_we_data       /* verilator public */;
  // data_t mem_rdata;

  bp_mem_top #(
    .BootPC(32'h80),
  ) i_bp_mem_top (
    .clk_i,
    .rst_ni,
    .mem_instr_req_o   (mem_req_instr),
    .mem_instr_gnt_i   (mem_gnt_instr),
    .mem_instr_addr_o  (mem_addr_instr),
    .mem_instr_wdata_o (mem_wdata_instr),
    .mem_instr_strb_o  (mem_strb_instr),
    .mem_instr_we_o    (mem_we_instr),
    .mem_instr_rdata_i (mem_rdata_instr_o),

    .mem_data_req_o   (mem_req_data),
    .mem_data_gnt_i   (mem_gnt_data),
    .mem_data_addr_o  (mem_addr_data),
    .mem_data_wdata_o (mem_wdata_data),
    .mem_data_strb_o  (mem_strb_data),
    .mem_data_we_o    (mem_we_data),
    .mem_data_rdata_i (mem_rdata_data_o),

    .debug_irq_i      ('0),
    .timer_irq_i      ('0),
    .software_irq_i   ('0),
    .m_external_irq_i ('0),
    .s_external_irq_i ('0)
  );

  ///////////////////////////////
  // Instruction SRAM instance //
  ///////////////////////////////

  sram_mem #(
    .Width(DataWidth),
    .Depth(NumWords),
    .RelocateRequestUp(64'h00000000)
  ) i_instr_sram (
    .clk_i,
    .rst_ni,

    .req_i(mem_req_instr),
    .write_i(mem_we_instr),
    .addr_i(mem_addr_instr >> 3), // 64-bit words
    .wdata_i(mem_wdata_instr),
    .wmask_i({{8{mem_strb_instr[7]}}, {8{mem_strb_instr[6]}}, {8{mem_strb_instr[5]}}, {8{mem_strb_instr[4]}}, {8{mem_strb_instr[3]}}, {8{mem_strb_instr[2]}}, {8{mem_strb_instr[1]}}, {8{mem_strb_instr[0]}}}),
    .rdata_o(mem_rdata_instr_o)
  );

  ////////////////////////
  // Data SRAM instance //
  ////////////////////////

  sram_mem #(
    .Width(DataWidth),
    .Depth(NumWords),
    .RelocateRequestUp(64'h00000000)
  ) i_data_sram (
    .clk_i,
    .rst_ni,

    .req_i(mem_req_data),
    .write_i(mem_we_data),
    .addr_i(mem_addr_data >> 3), // 64-bit words
    .wdata_i(mem_wdata_data),
    .wmask_i({{8{mem_strb_data[7]}}, {8{mem_strb_data[6]}}, {8{mem_strb_data[5]}}, {8{mem_strb_data[4]}}, {8{mem_strb_data[3]}}, {8{mem_strb_data[2]}}, {8{mem_strb_data[1]}}, {8{mem_strb_data[0]}}}),
    .rdata_o(mem_rdata_data_o)
  );

  assign mem_gnt_instr = 1'b1;
  assign mem_gnt_data  = 1'b1;

endmodule;
