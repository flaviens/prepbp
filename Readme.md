# Simple BP SoC

This repo provides a BP that starts at 0x80 (*_low) and one that starts at 0x80000000 (*_high). The latter fetches a single instruction.

## Requirements

fusesoc (tested with 0.1), verilator (tested with Verilator 5.003 devel rev v4.228-192-g79682e607).

## How to use

Initialize the repo:

```
fusesoc library add simplebp .
```

Then run any of the targets (they can be run in parallel)

```
bash run_low.sh
bash run_high.sh
```

To observe the waveforms (this can be done while the programs are still running)

```
bash waves_low.sh
bash waves_high.sh
```
