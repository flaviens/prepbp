set signals [list \
    "top.clk_i" \
    "top.rst_ni" \
    "top.bp_tiny_soc.mem_req_instr" \
    "top.bp_tiny_soc.mem_addr_instr" \
    "top.bp_tiny_soc.mem_rdata_instr_o" \
    "top.bp_tiny_soc.mem_req_data" \
    "top.bp_tiny_soc.mem_addr_data" \
    "top.bp_tiny_soc.mem_rdata_data_o" \
]

gtkwave::addSignalsFromList $signals