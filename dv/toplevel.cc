// Copyright Flavien Solt, ETH Zurich.
// Licensed under the General Public License, Version 3.0, see LICENSE for details.
// SPDX-License-Identifier: GPL-3.0-only

#include "Vbp_tiny_soc__Syms.h"
#include "Vbp_tiny_soc___024root.h"

#include <chrono>

#include "testbench.h"

static int get_sim_length_cycles()
{
  const char* simlen_env = std::getenv("SIMLEN");
  if(simlen_env == NULL) { std::cerr << "SIMLEN environment variable not set." << std::endl; exit(1); }
  int simlen = atoi(simlen_env);
  assert(simlen > 0);
  std::cout << "SIMLEN set to " << simlen << " ticks." << std::endl;
  return simlen;
}

static const char *cl_get_tracefile(void)
{
#if VM_TRACE
  const char *trace_env = std::getenv("TRACEFILE"); // allow override for batch execution from python
  if(trace_env == NULL) { std::cerr << "TRACEFILE environment variable not set." << std::endl; exit(1); }
  return trace_env;
#else
  return "";
#endif
}

#define RUNMORETICKS_AFTER_STOP 50 // Run a bit longer in case something interesting still happens
static inline long tb_run_ticks_stoppable(Testbench *tb, int simlen, bool reset = false) {
  if (reset)
    tb->reset();

  bool got_stop_req = false;
  int remaining_before_stop = RUNMORETICKS_AFTER_STOP;

  auto start = std::chrono::steady_clock::now();
  for (size_t step_id = 0; step_id < simlen; step_id++) {
    tb->tick();

    // // Check the data memory requests.
    // if (tb->module_->rootp->vlSymsp->TOP.bp_tiny_soc->mem_req_data) {
    //   std::cout << "Requested data mem at address " << std::hex << tb->module_->rootp->vlSymsp->TOP.bp_tiny_soc->mem_addr_data << ", we: " << (tb->module_->rootp->vlSymsp->TOP.bp_tiny_soc->mem_we_data == 1) << ", wdata: " << (tb->module_->rootp->vlSymsp->TOP.bp_tiny_soc->mem_wdata_data == 1) << std::dec << std::endl;
    // }

    // Check whether stop has been requested.
    if (!got_stop_req &&
        tb->module_->rootp->vlSymsp->TOP.bp_tiny_soc->mem_req_data &&
        tb->module_->rootp->vlSymsp->TOP.bp_tiny_soc->mem_we_data  &&
        tb->module_->rootp->vlSymsp->TOP.bp_tiny_soc->mem_wdata_data == 0 &&
        tb->module_->rootp->vlSymsp->TOP.bp_tiny_soc->mem_addr_data == 0) {
      std::cout << "Found a stop request. Stopping the benchmark after " << RUNMORETICKS_AFTER_STOP << " more ticks." << std::endl;
      got_stop_req = true;
    }

    // Decrement the chrono and maybe stop if stop request has been detected.
    if (got_stop_req)
      if (remaining_before_stop-- == 0)
        break;

    // "Natural" stop since SIMLEN has been reached
    if (step_id == simlen-1)
      std::cout << "Reached SIMLEN (" << simlen << " cycles). Stopping." << std::endl;
  }
  auto stop = std::chrono::steady_clock::now();
  long ret = std::chrono::duration_cast<std::chrono::milliseconds>(stop - start).count();
  return ret;
}

/**
 * Runs the testbench.
 *
 * @param tb a pointer to a testbench instance
 * @param simlen the number of cycles to run
 */
static unsigned long run_test(Testbench *tb, int simlen, bool reset) {
    return tb_run_ticks_stoppable(tb, simlen, reset);
}

int main(int argc, char **argv, char **env) {

  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(VM_TRACE);

  ////////
  // Get the env vars early to avoid Verilator segfaults.
  ////////

  std::cout << "Starting getting env variables." << std::endl;

  int simlen = get_sim_length_cycles();

  ////////
  // Initialize testbench.
  ////////

  Testbench *tb = new Testbench(cl_get_tracefile());

  ////////
  // Run the testbench.
  ////////

  unsigned int duration = run_test(tb, simlen, true);

  ////////
  // Display the results.
  ////////
#if !VM_TRACE
  std::cout << "Testbench complete!" << std::endl;
  std::cout << "Elapsed time: " << std::dec << duration << "." << std::endl;
#else // VM_TRACE
  std::cout << "Testbench with traces complete!" << std::endl;
  std::cout << "Elapsed time (traces enabled): " << std::dec << duration << "." << std::endl;
#endif // VM_TRACE

  delete tb;
  exit(0);
}
