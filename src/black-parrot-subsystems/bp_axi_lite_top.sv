
// This module wraps a minimal BP core with AXI interfaces. For an example usage
//   see https://github.com/black-parrot-hdk/zynq-parrot

`include "bp_common_defines.svh"
`include "bp_me_defines.svh"

module bp_axi_lite_top
 import bp_common_pkg::*;
 import bp_me_pkg::*;
 // Only default config is currently supported
 #(parameter bp_params_e bp_params_p = e_bp_default_cfg
   `declare_bp_proc_params(bp_params_p)

   , parameter boot_pc_p = 32'h0010000

   // AXI4-LITE PARAMS
   , parameter axil_addr_width_p   = 32
   , parameter axil_data_width_p   = 32
   , localparam axil_mask_width_lp = axil_data_width_p>>3

   `declare_bp_bedrock_mem_if_widths(paddr_width_p, did_width_p, lce_id_width_p, lce_assoc_p)
   )
  (input                                        clk_i
   , input                                      reset_i

   //======================== Outgoing I/O ========================
   , output logic [1:0][axil_addr_width_p-1:0]  m_axil_awaddr_o
   , output [1:0][2:0]                          m_axil_awprot_o
   , output logic [1:0]                         m_axil_awvalid_o
   , input [1:0]                                m_axil_awready_i

   , output logic [1:0][axil_data_width_p-1:0]  m_axil_wdata_o
   , output logic [1:0][axil_mask_width_lp-1:0] m_axil_wstrb_o
   , output logic [1:0]                         m_axil_wvalid_o
   , input [1:0]                                m_axil_wready_i

   , input [1:0][1:0]                           m_axil_bresp_i
   , input [1:0]                                m_axil_bvalid_i
   , output logic [1:0]                         m_axil_bready_o

   , output logic [1:0][axil_addr_width_p-1:0]  m_axil_araddr_o
   , output [1:0][2:0]                          m_axil_arprot_o
   , output logic [1:0]                         m_axil_arvalid_o
   , input [1:0]                                m_axil_arready_i

   , input [1:0][axil_data_width_p-1:0]         m_axil_rdata_i
   , input [1:0][1:0]                           m_axil_rresp_i
   , input [1:0]                                m_axil_rvalid_i
   , output logic [1:0]                         m_axil_rready_o

   , input                                      debug_irq_i
   , input                                      timer_irq_i
   , input                                      software_irq_i
   , input                                      m_external_irq_i
   , input                                      s_external_irq_i
   );

  `declare_bp_bedrock_mem_if(paddr_width_p, did_width_p, lce_id_width_p, lce_assoc_p);
  `declare_bp_cfg_bus_s(vaddr_width_p, hio_width_p, core_id_width_p, cce_id_width_p, lce_id_width_p);

  bp_bedrock_mem_header_s [1:0] proc_fwd_header_lo;
  logic [1:0][uce_fill_width_p-1:0] proc_fwd_data_lo;
  logic [1:0] proc_fwd_v_lo, proc_fwd_ready_and_li, proc_fwd_last_lo;
  bp_bedrock_mem_header_s [1:0] proc_rev_header_li;
  logic [1:0][uce_fill_width_p-1:0] proc_rev_data_li;
  logic [1:0] proc_rev_v_li, proc_rev_ready_and_lo, proc_rev_last_li;

  bp_cfg_bus_s cfg_bus_li;
  assign cfg_bus_li =
    '{freeze      : 1'b0
      ,npc        : boot_pc_p
      ,core_id    : '0
      ,icache_id  : '0
      ,icache_mode: e_lce_mode_normal
      ,dcache_id  : 1'b1
      ,dcache_mode: e_lce_mode_normal
      ,cce_id     : '0
      ,cce_mode   : e_cce_mode_uncached
      ,hio_mask   : '1
      };

  bp_unicore_lite
   #(.bp_params_p(bp_params_p))
   unicore_lite
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.cfg_bus_i(cfg_bus_li)

     ,.mem_cmd_header_o(proc_fwd_header_lo)
     ,.mem_cmd_data_o(proc_fwd_data_lo)
     ,.mem_cmd_v_o(proc_fwd_v_lo)
     ,.mem_cmd_ready_and_i(proc_fwd_ready_and_li)
     ,.mem_cmd_last_o(proc_fwd_last_lo)

     ,.mem_resp_header_i(proc_rev_header_li)
     ,.mem_resp_data_i(proc_rev_data_li)
     ,.mem_resp_v_i(proc_rev_v_li)
     ,.mem_resp_ready_and_o(proc_rev_ready_and_lo)
     ,.mem_resp_last_i(proc_rev_last_li)

     ,.debug_irq_i(debug_irq_i)
     ,.timer_irq_i(timer_irq_i)
     ,.software_irq_i(software_irq_i)
     ,.m_external_irq_i(m_external_irq_i)
     ,.s_external_irq_i(s_external_irq_i)
     );

  for (genvar i = 0; i < 2; i++)
    begin : rof1
      bp_me_axil_master
       #(.bp_params_p(bp_params_p)
         ,.axil_data_width_p(axil_data_width_p)
         ,.axil_addr_width_p(axil_addr_width_p)
         )
       cache2axil
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.io_cmd_header_i(proc_fwd_header_lo[i])
         ,.io_cmd_data_i(proc_fwd_data_lo[i])
         ,.io_cmd_v_i(proc_fwd_v_lo[i])
         ,.io_cmd_last_i(proc_fwd_last_lo[i])
         ,.io_cmd_ready_and_o(proc_fwd_ready_and_li[i])

         ,.io_resp_header_o(proc_rev_header_li[i])
         ,.io_resp_data_o(proc_rev_data_li[i])
         ,.io_resp_v_o(proc_rev_v_li[i])
         ,.io_resp_last_o(proc_rev_last_li[i])
         ,.io_resp_ready_and_i(proc_rev_ready_and_lo[i])

         ,.m_axil_awaddr_o(m_axil_awaddr_o[i])
         ,.m_axil_awprot_o(m_axil_awprot_o[i])
         ,.m_axil_awvalid_o(m_axil_awvalid_o[i])
         ,.m_axil_awready_i(m_axil_awready_i[i])

         ,.m_axil_wdata_o(m_axil_wdata_o[i])
         ,.m_axil_wstrb_o(m_axil_wstrb_o[i])
         ,.m_axil_wvalid_o(m_axil_wvalid_o[i])
         ,.m_axil_wready_i(m_axil_wready_i[i])

         ,.m_axil_bresp_i(m_axil_bresp_i[i])
         ,.m_axil_bvalid_i(m_axil_bvalid_i[i])
         ,.m_axil_bready_o(m_axil_bready_o[i])

         ,.m_axil_araddr_o(m_axil_araddr_o[i])
         ,.m_axil_arprot_o(m_axil_arprot_o[i])
         ,.m_axil_arvalid_o(m_axil_arvalid_o[i])
         ,.m_axil_arready_i(m_axil_arready_i[i])

         ,.m_axil_rdata_i(m_axil_rdata_i[i])
         ,.m_axil_rresp_i(m_axil_rresp_i[i])
         ,.m_axil_rvalid_i(m_axil_rvalid_i[i])
         ,.m_axil_rready_o(m_axil_rready_o[i])
         );
    end

  if (axil_data_width_p != uce_fill_width_p)
    $error("AXIL data width and UCE fill width must match (probably 64b)");

endmodule

